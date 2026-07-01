import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/mospl_catalog.dart';
import '../models.dart';
import '../services/api_client.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        _allProducts = buildMosplProducts(),
        coupons = buildCoupons() {
    categories = buildCategories(_allProducts);
    _seedLocalData();
  }

  final ApiClient _apiClient;
  final List<Product> _allProducts;
  List<Coupon> coupons;
  Coupon? appliedCoupon;   // currently applied coupon (null = none)
  late List<ProductCategory> categories;
  final _uuid = const Uuid();

  AppUser? currentUser;
  bool authLoading = false;
  String? authError;
  bool rememberMe = true;
  bool hasOnboarded = false;
  bool darkMode = false;
  bool notificationsEnabled = true;
  bool catalogLoading = false;
  bool catalogLoadedFromBackend = false;
  String catalogSource = 'frontend-fallback';
  String? catalogError;
  String? backendToken;

  // ── Real-time Firestore stream subscriptions ────────────────────────────────
  StreamSubscription<firestore.DocumentSnapshot<Map<String, dynamic>>>? _cartStream;
  StreamSubscription<firestore.DocumentSnapshot<Map<String, dynamic>>>? _wishlistStream;
  StreamSubscription<firestore.QuerySnapshot<Map<String, dynamic>>>? _allReviewsStream;
  StreamSubscription<firestore.DocumentSnapshot<Map<String, dynamic>>>? _dailyOffersStream;
  StreamSubscription<firestore.QuerySnapshot<Map<String, dynamic>>>? _productsStream;
  StreamSubscription<firestore.QuerySnapshot<Map<String, dynamic>>>? _couponsStream;
  String? _realtimeSyncUid; // tracks which UID streams are active for

  String searchQuery = '';
  String sortOption = 'Recommended';
  String? selectedCategory;
  int? minPrice;
  int? maxPrice;

  final List<CartLine> cart = [];
  final Set<String> wishlist = {};
  final List<Product> recentlyViewed = [];
  final List<AppOrder> orders = [];
  final List<ShippingAddress> addresses = [];
  final List<AppNotification> notifications = [];
  final List<ChatMessage> chatMessages = [];
  final List<Review> reviews = [];
  final List<PaymentRecord> payments = [];
  final List<BannerItem> banners = [];
  final List<InventoryItem> inventory = [];
  final List<ReturnRequest> returnRequests = [];
  final List<SupportTicket> supportTickets = [];
  final List<AppUser> adminUsers = [];
  final List<Product> adminProductPerformance = [];
  final List<int> revenueByDay = [];
  final List<Map<String, dynamic>> salesByCategory = [];
  AdminMetrics? adminMetrics;

  List<Product>? _cachedProcessedProducts;
  List<Product>? _cachedFeaturedProducts;
  List<Product>? _cachedTrendingProducts;
  List<Product>? _cachedBestSellers;
  List<Product>? _cachedWishlistProducts;
  List<Product>? _cachedRecommendations;
  List<Product>? _cachedVisibleProducts;

  void _invalidateProductsCache() {
    _cachedProcessedProducts = null;
    _cachedFeaturedProducts = null;
    _cachedTrendingProducts = null;
    _cachedBestSellers = null;
    _cachedWishlistProducts = null;
    _cachedRecommendations = null;
    _cachedVisibleProducts = null;
  }

  void _invalidateWishlistCache() {
    _cachedWishlistProducts = null;
  }

  void _invalidateVisibleProductsCache() {
    _cachedVisibleProducts = null;
  }

  Map<String, int> dailyOffers = {
    'monday': 10,
    'tuesday': 15,
    'wednesday': 20,
    'thursday': 25,
    'friday': 30,
    'saturday': 35,
    'sunday': 40,
  };

  Product applyDynamicPriceToProduct(Product product) {
    final customDiscount = product.customDiscount;
    int discountPercentage = 0;
    if (customDiscount > 0) {
      discountPercentage = customDiscount;
    } else {
      final days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      final weekday = DateTime.now().weekday; // 1 = Monday, ..., 7 = Sunday
      final dayName = days[weekday % 7];
      discountPercentage = dailyOffers[dayName] ?? 0;
    }
    final oldPrice = product.oldPrice > 0 ? product.oldPrice : product.price;
    final price = oldPrice - (oldPrice * discountPercentage / 100).round();
    return product.copyWith(
      discountPercentage: discountPercentage,
      price: price,
    );
  }

  List<Product> get allProducts {
    if (_cachedProcessedProducts == null) {
      _cachedProcessedProducts = List.unmodifiable(_allProducts.map(applyDynamicPriceToProduct).toList());
    }
    return _cachedProcessedProducts!;
  }

  /// Returns all reviews for a given [productId], newest first.
  List<Review> reviewsForProduct(String productId) =>
      reviews.where((r) => r.productId == productId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Product> get visibleProducts {
    if (_cachedVisibleProducts == null) {
      Iterable<Product> result = allProducts;
      final query = searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        result = result.where((product) {
          final text =
              '${product.name} ${product.category} ${product.subcategory} ${product.color} ${product.material}'
                  .toLowerCase();
          return text.contains(query);
        });
      }
      if (selectedCategory != null && selectedCategory!.isNotEmpty) {
        result = result.where((product) => product.category == selectedCategory);
      }
      if (minPrice != null) result = result.where((product) => product.price >= minPrice!);
      if (maxPrice != null) result = result.where((product) => product.price <= maxPrice!);

      final list = result.toList();
      switch (sortOption) {
        case 'Price: Low to High':
          list.sort((a, b) => a.price.compareTo(b.price));
        case 'Price: High to Low':
          list.sort((a, b) => b.price.compareTo(a.price));
        case 'Top Rated':
          list.sort((a, b) => getProductLiveRating(b.productId).compareTo(getProductLiveRating(a.productId)));
        case 'Newest':
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        default:
          list.sort((a, b) {
            final aScore = (a.isBestSeller ? 2 : 0) + (a.isTrending ? 1 : 0);
            final bScore = (b.isBestSeller ? 2 : 0) + (b.isTrending ? 1 : 0);
            return bScore.compareTo(aScore);
          });
      }
      _cachedVisibleProducts = List.unmodifiable(list);
    }
    return _cachedVisibleProducts!;
  }

  List<Product> get featuredProducts {
    if (_cachedFeaturedProducts == null) {
      final flagged = allProducts.where((p) => p.isFeatured).take(16).toList();
      _cachedFeaturedProducts = List.unmodifiable(flagged.isEmpty ? allProducts.take(16).toList() : flagged);
    }
    return _cachedFeaturedProducts!;
  }

  List<Product> get trendingProducts {
    if (_cachedTrendingProducts == null) {
      final flagged = allProducts.where((p) => p.isTrending).take(24).toList();
      _cachedTrendingProducts = List.unmodifiable(flagged.isEmpty ? allProducts.take(24).toList() : flagged);
    }
    return _cachedTrendingProducts!;
  }

  List<Product> get bestSellers {
    if (_cachedBestSellers == null) {
      final flagged = allProducts.where((p) => p.isBestSeller).take(16).toList();
      _cachedBestSellers = List.unmodifiable(flagged.isEmpty ? allProducts.take(16).toList() : flagged);
    }
    return _cachedBestSellers!;
  }

  List<Product> get wishlistProducts {
    if (_cachedWishlistProducts == null) {
      _cachedWishlistProducts = List.unmodifiable(allProducts.where((p) => wishlist.contains(p.productId)).toList());
    }
    return _cachedWishlistProducts!;
  }

  List<Product> get recommendations {
    if (_cachedRecommendations == null) {
      final seen = recentlyViewed.map((p) => p.category).toSet();
      final pool = seen.isEmpty ? trendingProducts : allProducts.where((p) => seen.contains(p.category)).toList();
      _cachedRecommendations = List.unmodifiable(pool.take(24).toList());
    }
    return _cachedRecommendations!;
  }

  int get cartCount => cart.fold(0, (total, line) => total + line.quantity);
  int get cartSubtotal => cart.fold(0, (total, line) => total + line.subtotal);
  int get deliveryFee => cartSubtotal >= 595 || cart.isEmpty ? 0 : 49;
  int get cartDiscount {
    if (appliedCoupon == null) return 0;
    if (cartSubtotal < appliedCoupon!.minimumAmount) return 0;
    return min(300, (cartSubtotal * appliedCoupon!.discountPercent / 100).round());
  }
  int get cartTotal => max(0, cartSubtotal + deliveryFee - cartDiscount);

  /// Apply a coupon by code. Returns an error message, or null on success.
  String? applyCoupon(String code) {
    final trimmed = code.trim().toUpperCase();
    final coupon = coupons.cast<Coupon?>().firstWhere(
      (c) => c!.code.toUpperCase() == trimmed,
      orElse: () => null,
    );
    if (coupon == null) return 'Invalid coupon code';
    if (cartSubtotal < coupon.minimumAmount) {
      return 'Minimum order of ₹${coupon.minimumAmount} required for this coupon';
    }
    appliedCoupon = coupon;
    notifyListeners();
    return null; // success
  }

  void removeCoupon() {
    appliedCoupon = null;
    notifyListeners();
  }
  int get unreadNotifications => notifications.where((item) => !item.read).length;
  int get totalRevenue => adminMetrics?.revenue ?? orders.fold(0, (total, order) => total + order.total);
  int get lowStockCount =>
      adminMetrics?.lowStock ?? (inventory.isEmpty ? _allProducts.where((product) => product.stock <= 5).length : inventory.where((item) => item.isLowStock).length);

  Future<void> loadCatalogFromBackend() async {
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiClient.fetchProducts(),
        _apiClient.fetchCategories(),
        _apiClient.fetchCoupons(),
        _apiClient.fetchBanners(),
        _apiClient.fetchDailyOffers().catchError((_) => <String, int>{}),
      ]);
      final products = results[0] as List<Product>;
      final backendCategories = results[1] as List<ProductCategory>;
      final backendCoupons = results[2] as List<Coupon>;
      final backendBanners = results[3] as List<BannerItem>;
      final backendDailyOffers = results[4] as Map<String, int>;

      _allProducts
        ..clear()
        ..addAll(products);
      if (backendDailyOffers.isNotEmpty) {
        dailyOffers = backendDailyOffers;
      }
      categories = backendCategories.isEmpty ? buildCategories(_allProducts) : backendCategories;
      coupons = backendCoupons.isEmpty ? buildCoupons() : backendCoupons;
      banners
        ..clear()
        ..addAll(backendBanners);
      catalogLoadedFromBackend = true;
      catalogSource = _apiClient.baseUrl;
      if (backendToken != null) await loadAuthenticatedData(notify: false);
    } catch (error) {
      catalogLoadedFromBackend = false;
      catalogSource = 'frontend-fallback';
      catalogError = error.toString();
      if (_allProducts.isEmpty) {
        _allProducts.addAll(buildMosplProducts());
        categories = buildCategories(_allProducts);
        coupons = buildCoupons();
      }
    } finally {
      // Merge any admin-saved Firestore products on top of the catalog
      await _mergeFirestoreProducts();
      catalogLoading = false;
      _invalidateProductsCache();
      notifyListeners();
    }
  }

  /// Loads products saved by admin from Firestore `products` collection
  /// and merges them into the local catalog. Firestore products override
  /// the local fallback entry for the same productId (stock updates etc.),
  /// and newly admin-added products that don't exist locally are appended.
  Future<void> _mergeFirestoreProducts() async {
    if (!_firebaseReady) return;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('products')
          .get();
      for (final doc in snapshot.docs) {
        try {
          final docData = doc.data();
          final index = _allProducts.indexWhere((p) => p.productId == doc.id);
          if (index >= 0) {
            // Merge Firestore values into the existing local copy
            final existing = _allProducts[index];
            _allProducts[index] = Product(
              productId: existing.productId,
              name: docData['name']?.toString() ?? existing.name,
              category: docData['category']?.toString() ?? existing.category,
              subcategory: (docData['subcategory'] ?? docData['category'])?.toString() ?? existing.subcategory,
              price: docData['price'] != null ? _int(docData['price']) : existing.price,
              oldPrice: docData['oldPrice'] != null ? _int(docData['oldPrice']) : existing.oldPrice,
              customDiscount: docData['customDiscount'] != null ? _int(docData['customDiscount']) : existing.customDiscount,
              discountPercentage: docData['discountPercentage'] != null ? _int(docData['discountPercentage']) : existing.discountPercentage,
              rating: docData['rating'] != null ? _double(docData['rating']) : existing.rating,
              reviewCount: docData['reviewCount'] != null ? _int(docData['reviewCount']) : existing.reviewCount,
              stock: docData['stock'] != null ? _int(docData['stock']) : existing.stock,
              sku: docData['sku']?.toString() ?? existing.sku,
              shortDescription: (docData['shortDescription'] ?? docData['description'])?.toString() ?? existing.shortDescription,
              description: docData['description']?.toString() ?? existing.description,
              specifications: docData['specifications'] != null ? _stringMap(docData['specifications']) : existing.specifications,
              material: docData['material']?.toString() ?? existing.material,
              size: docData['size']?.toString() ?? existing.size,
              color: docData['color']?.toString() ?? existing.color,
              deliveryInfo: docData['deliveryInfo']?.toString() ?? existing.deliveryInfo,
              returnPolicy: docData['returnPolicy']?.toString() ?? existing.returnPolicy,
              warranty: docData['warranty']?.toString() ?? existing.warranty,
              sourceUrl: docData['sourceUrl']?.toString() ?? existing.sourceUrl,
              thumbnail: docData['thumbnail']?.toString() ?? existing.thumbnail,
              galleryImages: docData['galleryImages'] != null ? _strings(docData['galleryImages']) : existing.galleryImages,
              isFeatured: docData['isFeatured'] != null ? docData['isFeatured'] == true : existing.isFeatured,
              isTrending: docData['isTrending'] != null ? docData['isTrending'] == true : existing.isTrending,
              isBestSeller: docData['isBestSeller'] != null ? docData['isBestSeller'] == true : existing.isBestSeller,
              createdAt: docData['createdAt'] != null ? _date(docData['createdAt']) : existing.createdAt,
              updatedAt: _date(docData['updatedAt'] ?? existing.updatedAt),
            );
          } else {
            // New product added by admin – deserialize completely
            final product = Product.fromMap({...docData, 'productId': doc.id});
            _allProducts.insert(0, product);
          }
        } catch (_) {}
      }
      if (snapshot.docs.isNotEmpty) {
        categories = buildCategories(_allProducts);
      }
    } catch (_) {}
    _invalidateProductsCache();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
    darkMode = prefs.getBool('darkMode') ?? false;
    rememberMe = prefs.getBool('rememberMe') ?? true;
    backendToken = prefs.getString('backendToken');
    final firebaseUser = _firebaseReady ? firebase_auth.FirebaseAuth.instance.currentUser : null;
    final email = firebaseUser?.email ?? prefs.getString('userEmail');
    final name = firebaseUser?.displayName ?? prefs.getString('userName');
    // Prefer persisted role, but re-fetch from Firestore for firebase users to pick up role changes
    String role = prefs.getString('userRole') ?? 'customer';
    if (firebaseUser != null && _firebaseReady) {
      final freshRole = await _fetchFirestoreRole(firebaseUser.uid);
      if (freshRole != 'customer' || role == 'customer') role = freshRole;
    }
    if (email != null && name != null && rememberMe) {
      currentUser = AppUser(
        uid: firebaseUser?.uid ?? prefs.getString('uid') ?? 'local-user',
        email: email,
        name: name,
        role: role,
      );
      _syncBackendFirebaseSession().ignore();
      await loadAuthenticatedData(notify: false);
      _startRealtimeSync(firebaseUser?.uid);
    } else {
      await _loadGuestChatHistory();
    }
    subscribeAllReviews();
    subscribeDailyOffers();
    subscribeCoupons();
    subscribeProducts();
    notifyListeners();
  }

  /// Fetches the user's role from the Firestore `users` collection.
  /// Returns 'admin' if the document has role=='admin', otherwise 'customer'.
  Future<String> _fetchFirestoreRole(String uid) async {
    if (!_firebaseReady) return 'customer';
    try {
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final r = data?['role']?.toString() ?? 'customer';
        return r;
      }
    } catch (_) {}
    return 'customer';
  }

  /// Saves (or upserts) a user document in Firestore `users` collection.
  /// If [isNew] is true (sign-up), writes all fields including role.
  /// If [isNew] is false (sign-in), only updates name/email/lastSeen
  /// so we never accidentally overwrite an existing admin role.
  Future<void> _saveUserToFirestore(AppUser user, {required bool isNew}) async {
    if (!_firebaseReady) return;
    try {
      final now = DateTime.now().toIso8601String();
      final ref = firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      if (isNew) {
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.name,
          'role': user.role,
          'createdAt': now,
          'updatedAt': now,
          'lastSeen': now,
        }, firestore.SetOptions(merge: true));
      } else {
        // Only update mutable fields, preserve role set by admin
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.name,
          'updatedAt': now,
          'lastSeen': now,
        }, firestore.SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> completeOnboarding() async {
    hasOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOnboarded', true);
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool remember,
  }) async {
    authError = _validateEmailPassword(email, password, isSignup: false);
    if (authError != null) {
      notifyListeners();
      return false;
    }
    authLoading = true;
    notifyListeners();
    try {
      if (_firebaseReady) {
        final credential = await firebase_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email.trim(), password: password);
        final user = credential.user;
        final uid = user?.uid ?? 'firebase-user';
        final firestoreRole = await _fetchFirestoreRole(uid);
        currentUser = AppUser(
          uid: uid,
          email: email.trim(),
          name: user?.displayName ?? email.split('@').first,
          role: firestoreRole,
        );
        // Upsert user doc so admin sees all users who have signed in
        _saveUserToFirestore(currentUser!, isNew: false).ignore();
      } else {
        currentUser = AppUser(
          uid: 'local-${email.hashCode.abs()}',
          email: email.trim(),
          name: email.split('@').first,
          role: 'customer',
        );
      }
      _syncBackendLogin(email: email, password: password).ignore();
      rememberMe = remember;
      _startRealtimeSync(_firebaseUid);
      await loadAuthenticatedData(notify: false);
      authLoading = false;
      await _persistUser();
      _pushNotification('Welcome back', 'You are signed in to MOSPL with email/password.');
      notifyListeners();
    } catch (error) {
      authError = _authFailureMessage(error);
      authLoading = false;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool remember,
  }) async {
    authError = _validateEmailPassword(email, password, isSignup: true);
    if (confirmPassword != password) authError = 'Passwords do not match.';
    if (name.trim().length < 2) authError = 'Enter your full name.';
    if (authError != null) {
      notifyListeners();
      return false;
    }
    authLoading = true;
    notifyListeners();
    try {
      if (_firebaseReady) {
        final credential = await firebase_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email.trim(), password: password);
        await credential.user?.updateDisplayName(name.trim());
        final uid = credential.user?.uid ?? 'firebase-user';
        currentUser = AppUser(
          uid: uid,
          email: email.trim(),
          name: name.trim(),
          role: 'customer',
        );
        // Save new user profile to Firestore so admin can see them
        _saveUserToFirestore(currentUser!, isNew: true).ignore();
      } else {
        currentUser = AppUser(
          uid: 'local-${email.hashCode.abs()}',
          email: email.trim(),
          name: name.trim(),
          role: 'customer',
        );
      }
      _syncBackendRegister(name: name, email: email, password: password).ignore();
      rememberMe = remember;
      _startRealtimeSync(_firebaseUid);
      await loadAuthenticatedData(notify: false);
      authLoading = false;
      await _persistUser();
      _pushNotification('Account created', 'Your MOSPL shopping account is ready.');
      notifyListeners();
    } catch (error) {
      authError = _authFailureMessage(error);
      authLoading = false;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<String> sendPasswordReset(String email) async {
    final validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
    if (!validEmail) return 'Enter a valid email address.';
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
    return 'Password reset link sent to ${email.trim()} if the account exists.';
  }

  Future<bool> changePassword(String newPassword) async {
    if (newPassword.length < 6) {
      authError = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    try {
      if (_firebaseReady) {
        await firebase_auth.FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
      }
    } catch (error) {
      authError = error is firebase_auth.FirebaseAuthException && error.code == 'requires-recent-login'
          ? 'Please sign in again before changing your password.'
          : _authFailureMessage(error);
      notifyListeners();
      return false;
    }
    authError = null;
    _pushNotification('Password updated', 'Your account password was changed.');
    notifyListeners();
    return true;
  }

  Future<void> updateProfile({required String name, required String email}) async {
    if (currentUser == null) return;
    final updated = AppUser(
      uid: currentUser!.uid,
      email: email.trim(),
      name: name.trim().isEmpty ? currentUser!.name : name.trim(),
      role: currentUser!.role,
    );
    currentUser = updated;
    if (backendToken != null) {
      try {
        currentUser = await _apiClient.updateProfile(
          name: updated.name,
          email: updated.email,
          token: backendToken!,
        );
      } catch (error) {
        catalogError = error.toString();
      }
    }
    await _persistUser();
    _pushNotification('Profile updated', 'Your MOSPL profile changes are saved.');
    notifyListeners();
  }

  Future<void> logout() async {
    _stopRealtimeSync();
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}
    currentUser = null;
    backendToken = null;
    addresses.clear();
    orders.clear();
    payments.clear();
    cart.clear();
    wishlist.clear();
    returnRequests.clear();
    supportTickets.clear();
    adminUsers.clear();
    inventory.clear();
    adminProductPerformance.clear();
    revenueByDay.clear();
    salesByCategory.clear();
    adminMetrics = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('userRole');
    await prefs.remove('backendToken');
    _invalidateProductsCache();
    await _loadGuestChatHistory();
  }

  // ── Real-time Firestore streams ─────────────────────────────────────────────
  // These listeners fire within ~100-500 ms whenever mobile (or any client)
  // writes to carts/{uid} or wishlists/{uid} in Firestore.

  void _startRealtimeSync(String? uid) {
    if (uid == null || uid == _realtimeSyncUid) return; // already listening
    if (!_firebaseReady) return;
    _stopRealtimeSync(); // cancel any previous streams
    _realtimeSyncUid = uid;

    // Also subscribe to reviews
    subscribeAllReviews();

    final db = firestore.FirebaseFirestore.instance;

    // ── Cart stream ──────────────────────────────────────────────────────────
    _cartStream = db
        .collection('carts')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      final rawItems = (data['items'] as List? ?? const []).whereType<Map>();
      final newCart = rawItems
          .map((item) => _cartLineFromBackend(item.cast<String, dynamic>()))
          .toList();
      cart
        ..clear()
        ..addAll(newCart);
      notifyListeners();
    }, onError: (_) {/* silently ignore stream errors */});

    // ── Wishlist stream ──────────────────────────────────────────────────────
    _wishlistStream = db
        .collection('wishlists')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      final ids = (data['productIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toSet();
      wishlist
        ..clear()
        ..addAll(ids);
      _invalidateWishlistCache();
      notifyListeners();
    }, onError: (_) {/* silently ignore stream errors */});
  }

  void _stopRealtimeSync() {
    _cartStream?.cancel();
    _wishlistStream?.cancel();
    _cartStream = null;
    _wishlistStream = null;
    _realtimeSyncUid = null;
  }

  Future<void> _updateFirestoreCart() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final itemsList = cart.map((line) => {
        'productId': line.product.productId,
        'quantity': line.quantity,
        'price': line.product.price,
        'product': line.product.toMap(),
      }).toList();

      await firestore.FirebaseFirestore.instance
          .collection('carts')
          .doc(uid)
          .set({
            'userId': uid,
            'items': itemsList,
            'updatedAt': now,
          }, firestore.SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _updateFirestoreWishlist() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      await firestore.FirebaseFirestore.instance
          .collection('wishlists')
          .doc(uid)
          .set({
            'userId': uid,
            'productIds': wishlist.toList(),
            'updatedAt': now,
          }, firestore.SetOptions(merge: true));
    } catch (_) {}
  }

  void updateSearch(String value) {
    searchQuery = value;
    _invalidateVisibleProductsCache();
    notifyListeners();
  }

  void setCategory(String? value) {
    selectedCategory = value;
    _invalidateVisibleProductsCache();
    notifyListeners();
  }

  void setSort(String value) {
    sortOption = value;
    _invalidateVisibleProductsCache();
    notifyListeners();
  }

  void setPriceFilter(int? min, int? max) {
    minPrice = min;
    maxPrice = max;
    _invalidateVisibleProductsCache();
    notifyListeners();
  }

  void clearFilters() {
    selectedCategory = null;
    minPrice = null;
    maxPrice = null;
    sortOption = 'Recommended';
    _invalidateVisibleProductsCache();
    notifyListeners();
  }

  Product productById(String id) {
    final raw = _allProducts.firstWhere((product) => product.productId == id, orElse: () => _allProducts.first);
    return applyDynamicPriceToProduct(raw);
  }

  void viewProduct(Product product) {
    recentlyViewed.removeWhere((item) => item.productId == product.productId);
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 20) recentlyViewed.removeLast();
    // FIX: Removed notifyListeners() — this was firing a global rebuild on every
    // product card tap, causing ALL sibling cards to blink before navigation.
    // recentlyViewed is a background update; consumers (recommendations section)
    // use context.select and will pick up the change when they next become active.
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final index = cart.indexWhere((line) => line.product.productId == product.productId);
    final currentQty = index >= 0 ? cart[index].quantity : 0;
    if (currentQty + quantity > product.stock) {
      _pushNotification('Out of Stock', 'Cannot add more items. Only ${product.stock} available.');
      notifyListeners();
      return;
    }
    if (index >= 0) {
      cart[index] = cart[index].copyWith(quantity: cart[index].quantity + quantity);
    } else {
      cart.add(CartLine(product: product, quantity: quantity));
    }
    // FIX: Removed _pushNotification('Added to cart', ...) — adding to the
    // persistent notifications list incremented unreadNotifications, which
    // triggered HomeScreen to rebuild, cascading into every ProductCard blinking.
    notifyListeners(); // single notification — cart badge updates immediately

    if (_firebaseUid != null) {
      // Firebase path: _cartStream listener will fire its own notifyListeners()
      // after Firestore confirms the write. No second call needed here.
      await _updateFirestoreCart();
    } else {
      if (backendToken == null) await _syncBackendFirebaseSession();
      if (backendToken == null) return;
      try {
        final saved = await _apiClient.addCartItem(
          productId: product.productId,
          quantity: quantity,
          token: backendToken!,
        );
        cart
          ..clear()
          ..addAll(saved);
        notifyListeners(); // only needed for non-Firebase backend sync
      } catch (error) {
        catalogError = error.toString();
      }
    }
  }

  Future<void> setCartQuantity(String productId, int quantity) async {
    final index = cart.indexWhere((line) => line.product.productId == productId);
    if (index < 0) return;
    final product = cart[index].product;
    if (quantity > product.stock) {
      // FIX: Removed _pushNotification here — mutating notifications list
      // changed unreadNotifications count and caused HomeScreen to rebuild.
      notifyListeners();
      return;
    }
    if (quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(quantity: quantity);
    }
    notifyListeners();

    if (_firebaseUid != null) {
      await _updateFirestoreCart();
    } else {
      if (backendToken == null) return;
      try {
        final saved = quantity <= 0
            ? await _apiClient.removeCartItem(productId, backendToken!)
            : await _apiClient.updateCartItem(productId: productId, quantity: quantity, token: backendToken!);
        cart
          ..clear()
          ..addAll(saved);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    // FIX: Removed trailing notifyListeners() — for the Firebase path the
    // _cartStream listener fires its own notify after Firestore confirms.
    // For the backend path, the cart is already up-to-date in memory after the
    // await above, so the single notify at line 861 is sufficient.
  }

  Future<void> removeFromCart(String productId) async {
    cart.removeWhere((line) => line.product.productId == productId);
    notifyListeners();

    if (_firebaseUid != null) {
      await _updateFirestoreCart();
    } else {
      if (backendToken == null) return;
      try {
        final saved = await _apiClient.removeCartItem(productId, backendToken!);
        cart
          ..clear()
          ..addAll(saved);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    // FIX: Removed trailing notifyListeners() — same reason as setCartQuantity().
    // The Firebase stream fires its own notify; backend path already updated in memory.
  }

  Future<void> toggleWishlist(Product product) async {
    final shouldAdd = !wishlist.contains(product.productId);
    if (!wishlist.add(product.productId)) {
      wishlist.remove(product.productId);
    }
    // FIX: Removed _pushNotification('Wishlist updated', ...) — adding to the
    // persistent notifications list incremented unreadNotifications, which
    // triggered HomeScreen to rebuild, cascading into every ProductCard blinking.
    _invalidateWishlistCache();
    notifyListeners(); // single notification — only the _WishlistButton for this product rebuilds

    if (_firebaseUid != null) {
      // Firebase path: _wishlistStream listener will fire its own notifyListeners()
      // after Firestore confirms the write. No second call needed here.
      await _updateFirestoreWishlist();
    } else {
      if (backendToken == null) await _syncBackendFirebaseSession();
      if (backendToken == null) return;
      try {
        final saved = shouldAdd
            ? await _apiClient.addWishlistProduct(product.productId, backendToken!)
            : await _apiClient.removeWishlistProduct(product.productId, backendToken!);
        wishlist
          ..clear()
          ..addAll(saved);
        notifyListeners(); // only needed for non-Firebase backend sync
      } catch (error) {
        catalogError = error.toString();
      }
    }
  }

  bool isWishlisted(String productId) => wishlist.contains(productId);

  Future<void> loadAuthenticatedData({bool notify = true}) async {
    if (backendToken == null) {
      _syncBackendFirebaseSession().ignore();
    }
    await _loadLocalAddresses();
    if (backendToken == null) {
      await loadAddresses(notify: false);
      await loadOrders(notify: false);
      await loadSupportTickets(notify: false);
      if (notify) notifyListeners();
      return;
    }
    await Future.wait([
      loadCart(notify: false),
      loadWishlist(notify: false),
      loadAddresses(notify: false),
      loadOrders(notify: false),
      loadNotifications(notify: false),
      loadReviews(notify: false),
      loadChatHistory(notify: false),
      loadPaymentHistory(notify: false),
      loadReturns(notify: false),
      loadSupportTickets(notify: false),
      if (currentUser?.isAdmin == true) loadAdminData(notify: false),
    ]);
    if (notify) notifyListeners();
  }

  Future<void> loadCart({bool notify = true}) async {
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.fetchCart(backendToken!);
      cart
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadWishlist({bool notify = true}) async {
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.fetchWishlist(backendToken!);
      wishlist
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadAddresses({bool notify = true}) async {
    await _loadLocalAddresses();
    if (backendToken == null) {
      _syncBackendFirebaseSession().ignore();
    }
    if (backendToken == null) {
      await _loadFirestoreAddresses();
      if (notify) notifyListeners();
      return;
    }
    try {
      final saved = await _apiClient.fetchAddresses(backendToken!);
      addresses
        ..clear()
        ..addAll(saved);
      await _saveLocalAddresses();
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> addAddress(ShippingAddress address) async {
    if (_firebaseUid != null) {
      final addressToStore = await _saveFirestoreAddress(address);
      _upsertLocalAddress(addressToStore);
      await _saveLocalAddresses();
      notifyListeners();
      if (backendToken != null) {
        _apiClient.createAddress(address, backendToken!).ignore();
      }
      return;
    }
    if (backendToken == null) {
      _syncBackendFirebaseSession().ignore();
    }
    if (backendToken == null) {
      final addressToStore = await _saveFirestoreAddress(address);
      _upsertLocalAddress(addressToStore);
      await _saveLocalAddresses();
      notifyListeners();
      return;
    }
    late final ShippingAddress addressToStore;
    try {
      addressToStore = await _apiClient.createAddress(address, backendToken!);
    } catch (error) {
      catalogError = error.toString();
      notifyListeners();
      throw StateError('Address was not saved to Firebase. $catalogError');
    }
    _upsertLocalAddress(addressToStore);
    await _saveLocalAddresses();
    notifyListeners();
  }

  Future<void> deleteAddress(String addressId) async {
    addresses.removeWhere((item) => item.id == addressId);
    await _saveLocalAddresses();
    notifyListeners();
    if (backendToken == null) {
      await _deleteFirestoreAddress(addressId);
      return;
    }
    try {
      final saved = await _apiClient.deleteAddress(addressId, backendToken!);
      addresses
        ..clear()
        ..addAll(saved);
      await _saveLocalAddresses();
    } catch (error) {
      catalogError = error.toString();
    }
    notifyListeners();
  }

  void _upsertLocalAddress(ShippingAddress address) {
    if (address.isDefault) {
      final existing = List<ShippingAddress>.from(addresses);
      addresses
        ..clear()
        ..addAll(existing.map((item) => ShippingAddress(
              id: item.id,
              name: item.name,
              phone: item.phone,
              line1: item.line1,
              line2: item.line2,
              city: item.city,
              state: item.state,
              pincode: item.pincode,
            )));
    }
    addresses.removeWhere((item) => item.id == address.id);
    addresses.add(address);
  }

  Future<void> _loadFirestoreAddresses() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: uid)
          .get();
      final saved = snapshot.docs
          .map((doc) => ShippingAddress.fromMap({...doc.data(), 'id': doc.id, 'addressId': doc.id}))
          .toList()
        ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
      addresses
        ..clear()
        ..addAll(saved);
      await _saveLocalAddresses();
      catalogError = null;
    } catch (error) {
      catalogError = 'Address sync failed. Check Firestore rules for addresses. $error';
    }
  }

  Future<ShippingAddress> _saveFirestoreAddress(ShippingAddress address) async {
    final uid = _firebaseUid;
    if (uid == null) {
      throw StateError('Please sign in again. Address was not saved.');
    }
    try {
      if (address.isDefault) await _clearFirestoreDefaultAddresses(uid);
      final docId = address.id.isEmpty ? _uuid.v4() : address.id;
      final now = DateTime.now().toIso8601String();
      final addressToStore = ShippingAddress(
        id: docId,
        name: address.name,
        phone: address.phone,
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        isDefault: address.isDefault,
      );
      await firestore.FirebaseFirestore.instance.collection('addresses').doc(docId).set({
        ...addressToStore.toMap(),
        'id': docId,
        'addressId': docId,
        'userId': uid,
        'userEmail': currentUser?.email ?? firebase_auth.FirebaseAuth.instance.currentUser?.email,
        'createdAt': now,
        'updatedAt': now,
      }, firestore.SetOptions(merge: true));
      catalogError = null;
      return addressToStore;
    } catch (error) {
      catalogError = 'Address was not saved to Firestore. Check Firebase rules. $error';
      throw StateError(catalogError!);
    }
  }

  Future<void> _deleteFirestoreAddress(String addressId) async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final ref = firestore.FirebaseFirestore.instance.collection('addresses').doc(addressId);
      final doc = await ref.get();
      if (doc.exists && doc.data()?['userId'] == uid) await ref.delete();
      catalogError = null;
    } catch (error) {
      catalogError = 'Address delete failed. Check Firestore rules. $error';
    }
  }

  Future<void> _clearFirestoreDefaultAddresses(String uid) async {
    final snapshot = await firestore.FirebaseFirestore.instance
        .collection('addresses')
        .where('userId', isEqualTo: uid)
        .get();
    final batch = firestore.FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'isDefault': false,
        'updatedAt': DateTime.now().toIso8601String(),
      }, firestore.SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> loadOrders({bool notify = true}) async {
    if (backendToken == null) {
      await _loadFirestoreOrders();
      if (notify) notifyListeners();
      return;
    }
    try {
      final saved = await _apiClient.fetchOrders(backendToken!);
      orders
        ..clear()
        ..addAll(saved.map(_orderFromBackend));
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadPaymentHistory({bool notify = true}) async {
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.fetchPaymentHistory(backendToken!);
      payments
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadNotifications({bool notify = true}) async {
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.fetchNotifications(backendToken!);
      notifications
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadReviews({bool notify = true, String? productId}) async {
    if (_firebaseReady) return;
    try {
      final saved = await _apiClient.fetchReviews(productId: productId);
      if (productId == null) {
        reviews
          ..clear()
          ..addAll(saved);
      } else {
        reviews.removeWhere((review) => review.productId == productId);
        reviews.addAll(saved);
      }
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadChatHistory({bool notify = true}) async {
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.fetchChatHistory(backendToken!);
      if (saved.isNotEmpty) {
        chatMessages
          ..clear()
          ..addAll(saved);
      }
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> _loadGuestChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('guest_chat_history');
      if (raw != null) {
        final List decoded = json.decode(raw);
        final messages = decoded.map((item) => ChatMessage.fromMap(Map<String, dynamic>.from(item))).toList();
        chatMessages
          ..clear()
          ..addAll(messages);
      } else {
        chatMessages.clear();
      }
    } catch (_) {
      chatMessages.clear();
    }
    notifyListeners();
  }

  Future<void> _saveGuestChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = chatMessages.map((msg) => msg.toMap()).toList();
      await prefs.setString('guest_chat_history', json.encode(list));
    } catch (_) {}
  }

  Future<void> loadReturns({bool notify = true}) async {
    if (backendToken == null) {
      await _loadFirestoreReturnRequests();
      if (notify) notifyListeners();
      return;
    }
    try {
      final saved = await _apiClient.fetchReturns(backendToken!);
      returnRequests
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadSupportTickets({bool notify = true}) async {
    if (backendToken == null) {
      await _loadFirestoreSupportTickets();
      if (notify) notifyListeners();
      return;
    }
    try {
      final saved = await _apiClient.fetchSupportTickets(backendToken!);
      supportTickets
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<void> loadAdminData({bool notify = true}) async {
    if (currentUser?.isAdmin != true) return;

    if (_firebaseReady) {
      try {
        final db = firestore.FirebaseFirestore.instance;

        // 1. Fetch products
        final productsSnapshot = await db.collection('products').get();
        final dbProducts = productsSnapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList();

        // 2. Fetch orders
        final ordersSnapshot = await db.collection('orders').get();
        final dbOrders = ordersSnapshot.docs
            .map((doc) => _orderFromBackend({...doc.data(), 'orderId': doc.id}))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 3. Fetch users
        final usersSnapshot = await db.collection('users').get();
        final dbUsers = usersSnapshot.docs
            .map((doc) => AppUser.fromMap(doc.data()))
            .toList();

        // 4. Fetch inventory
        final inventorySnapshot = await db.collection('inventory').get();
        final dbInventory = inventorySnapshot.docs
            .map((doc) => InventoryItem.fromMap(doc.data()))
            .toList();

        // 5. Fetch payments
        final paymentsSnapshot = await db.collection('payments').get();
        final dbPayments = paymentsSnapshot.docs
            .map((doc) => PaymentRecord.fromMap(doc.data()))
            .toList();

        // 6. Fetch return requests
        final returnsSnapshot = await db.collection('returns').get();
        final dbReturns = returnsSnapshot.docs
            .map((doc) => ReturnRequest.fromMap({
                  ...doc.data(),
                  'returnId': doc.id,
                }))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Compute metrics
        final revenue = dbOrders.fold<int>(0, (sum, order) => sum + order.total);
        final lowStock = dbInventory
            .where((item) => item.stock <= item.lowStockThreshold)
            .length;

        adminMetrics = AdminMetrics(
          revenue: revenue,
          products: dbProducts.length,
          orders: dbOrders.length,
          users: dbUsers.length,
          lowStock: lowStock,
          payments: dbPayments.length,
        );

        orders
          ..clear()
          ..addAll(dbOrders);

        inventory
          ..clear()
          ..addAll(dbInventory);

        adminUsers
          ..clear()
          ..addAll(dbUsers);

        payments
          ..clear()
          ..addAll(dbPayments);

        returnRequests
          ..clear()
          ..addAll(dbReturns);

        adminProductPerformance
          ..clear()
          ..addAll(dbProducts.where((p) => p.isBestSeller).take(10));

        // Weekly sales trend (last 7 days)
        revenueByDay.clear();
        for (int i = 6; i >= 0; i--) {
          final date = DateTime.now().subtract(Duration(days: i));
          final key = DateTime(date.year, date.month, date.day);
          final dailyRevenue = dbOrders
              .where((o) {
                final oc = o.createdAt;
                return oc.year == key.year && oc.month == key.month && oc.day == key.day;
              })
              .fold<int>(0, (sum, o) => sum + o.total);
          revenueByDay.add(dailyRevenue);
        }

        // Sales by category
        salesByCategory.clear();
        final categoriesSet = dbProducts.map((p) => p.category).toSet();
        for (final cat in categoriesSet) {
          final catProducts = dbProducts.where((p) => p.category == cat).length;
          salesByCategory.add({
            'category': cat,
            'sales': catProducts,
          });
        }

        if (notify) notifyListeners();
        return; // Success, bypass backend dashboard fetch
      } catch (error) {
        catalogError = 'Direct Firestore fetch failed, falling back to backend: $error';
      }
    }

    if (backendToken == null) return;
    try {
      final dashboard = await _apiClient.fetchAdminDashboard(backendToken!);
      final analytics = await _apiClient.fetchAdminAnalytics(backendToken!);
      final users = await _apiClient.fetchAdminUsers(backendToken!);
      final stock = await _apiClient.fetchInventory(backendToken!);
      adminMetrics = AdminMetrics.fromMap((dashboard['metrics'] as Map? ?? const {}).cast<String, dynamic>());
      final recentOrders = (dashboard['recentOrders'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _orderFromBackend(item.cast<String, dynamic>()))
          .toList();
      orders
        ..clear()
        ..addAll(recentOrders);
      adminProductPerformance
        ..clear()
        ..addAll(
          (dashboard['productPerformance'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => Product.fromMap(item.cast<String, dynamic>())),
        );
      revenueByDay
        ..clear()
        ..addAll((analytics['revenueByDay'] as List? ?? const []).map(_intDynamic));
      salesByCategory
        ..clear()
        ..addAll(
          (analytics['salesByCategory'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>()),
        );
      inventory
        ..clear()
        ..addAll(stock);
      adminUsers
        ..clear()
        ..addAll(users);
    } catch (error) {
      catalogError = error.toString();
    }
    if (notify) notifyListeners();
  }

  Future<AppOrder> placeOrder({required ShippingAddress address, required String paymentMethod}) async {
    var order = AppOrder(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: List<CartLine>.from(cart),
      address: address,
      status: 'Confirmed',
      paymentStatus: (paymentMethod == 'Razorpay' || paymentMethod == 'COD') ? 'Pending' : 'Paid',
      paymentMethod: paymentMethod,
      total: cartTotal,
      createdAt: DateTime.now(),
      razorpayOrderId: paymentMethod == 'Razorpay' ? 'order_test_${_uuid.v4().substring(0, 8)}' : null,
    );
    if (backendToken == null) {
      order = await _saveFirestoreOrder(order);
    } else {
      try {
        final saved = await _apiClient.createOrder(_orderPayload(order), backendToken!);
        order = _orderFromBackend(saved, fallback: order);
      } catch (error) {
        catalogError = error.toString();
        notifyListeners();
        throw StateError('Order was not saved to Firebase. $catalogError');
      }
    }
    orders.removeWhere((item) => item.orderId == order.orderId);
    orders.insert(0, order);
    payments.insert(
      0,
      PaymentRecord(
        paymentId: 'PAY-${_uuid.v4().substring(0, 8)}',
        orderId: order.orderId,
        amount: order.total,
        status: order.paymentStatus,
        method: paymentMethod,
        createdAt: DateTime.now(),
      ),
    );
    // ── Decrement stock for each ordered item ────────────────────────────────
    _decrementStockForOrder(order);
    cart.clear();
    _pushNotification('Order placed', '${order.orderId} is confirmed.');
    notifyListeners();
    return order;
  }

  /// Reduces stock locally and in Firestore for every product in the order.
  void _decrementStockForOrder(AppOrder order) {
    // If firebase is ready, we always update the 'products' collection in Firestore so the stock count decrements permanently.
    // This acts as a robust override since the backend might run in in-memory fallback mode or lose the product state on restarts.
    final db = _firebaseReady ? firestore.FirebaseFirestore.instance : null;
    final isUserAdmin = currentUser?.isAdmin == true;

    for (final line in order.items) {
      final productId = line.product.productId;
      final qty = line.quantity;
      // Update local in-memory list
      final index = _allProducts.indexWhere((p) => p.productId == productId);
      if (index >= 0) {
        final newStock = (_allProducts[index].stock - qty).clamp(0, 99999);
        _allProducts[index] = _allProducts[index].copyWith(stock: newStock, updatedAt: DateTime.now());
        // Persist updated stock to Firestore
        if (db != null) {
          db.collection('products').doc(productId).set(
            {'stock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
            firestore.SetOptions(merge: true),
          ).ignore();

          // Only write to 'inventory' if the user is an admin (customers get permission error)
          // or in local/fallback mode (backendToken == null).
          if (isUserAdmin || backendToken == null) {
            db.collection('inventory').doc(productId).set(
              {'stock': newStock, 'lastRestockedAt': DateTime.now().toIso8601String()},
              firestore.SetOptions(merge: true),
            ).ignore();
          }
        }
      }
    }
    _invalidateProductsCache();
  }

  Future<Map<String, dynamic>> createRazorpayOrder(AppOrder order) async {
    if (backendToken == null) {
      await _syncBackendFirebaseSession();
    }
    if (backendToken == null) {
      return {
        'razorpayOrder': {
          'id': order.razorpayOrderId ?? 'order_test_local',
          'amount': order.total * 100,
          'currency': 'INR',
        },
        'keyId': 'rzp_test_1234567890abcdef',
      };
    }
    return _apiClient.createPaymentOrder(
      amount: order.total,
      receipt: order.orderId,
      token: backendToken!,
    );
  }

  Future<void> verifyRazorpayPayment({
    required String orderId,
    required int amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    // --- Optimistic update: mark as Paid immediately so the UI responds instantly ---
    _replaceOrder(
      orderId,
      (order) => order.copyWith(
        paymentStatus: 'Paid',
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
      ),
    );
    notifyListeners();

    // --- Persist to Firestore directly (fastest path) ---
    if (_firebaseReady) {
      try {
        await firestore.FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .set({
          'paymentStatus': 'Paid',
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'paidAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, firestore.SetOptions(merge: true));
      } catch (_) {}
    }

    // --- Also persist to backend if token available ---
    _pushPaymentToBackend(
      orderId: orderId,
      amount: amount,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    ).ignore();
  }

  Future<void> _pushPaymentToBackend({
    required String orderId,
    required int amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken != null) {
      try {
        final payment = await _apiClient.verifyPayment(
          orderId: orderId,
          amount: amount,
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: razorpayPaymentId,
          razorpaySignature: razorpaySignature,
          token: backendToken!,
        );
        payments.removeWhere((item) => item.paymentId == payment.paymentId);
        payments.insert(0, payment);
        notifyListeners();
      } catch (error) {
        catalogError = error.toString();
      }
    }
  }

  void markPaymentFailed(String orderId) {
    _replaceOrder(
      orderId,
      (order) => order.copyWith(paymentStatus: 'Failed'),
    );
    notifyListeners();
    // Persist Failed status to Firestore
    if (_firebaseReady) {
      firestore.FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set({'paymentStatus': 'Failed', 'updatedAt': DateTime.now().toIso8601String()},
              firestore.SetOptions(merge: true))
          .ignore();
    }
  }

  Future<Map<String, dynamic>> retryRazorpayPayment(String orderId) async {
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) return {'razorpayOrder': {'id': 'order_test_local'}};
    return _apiClient.retryPayment(orderId, backendToken!);
  }

  Future<void> submitReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final userName = currentUser?.name ?? 'MOSPL Customer';
    final docId = _uuid.v4();
    final now = DateTime.now();

    // ── 1. Write directly to Firestore ──────────────────────────────────────
    if (!_firebaseReady) {
      throw StateError('Firebase is not initialized. Please restart the app and try again.');
    }

    await firestore.FirebaseFirestore.instance
        .collection('reviews')
        .doc(productId)
        .collection('items')
        .doc(docId)
        .set({
      'id': docId,
      'productId': productId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': firestore.Timestamp.fromDate(now),
    });

    // ── 2. Calculate new average rating and review count from Firestore ─────
    try {
      final reviewsSnap = await firestore.FirebaseFirestore.instance
          .collection('reviews')
          .doc(productId)
          .collection('items')
          .get();

      final docs = reviewsSnap.docs;
      final count = docs.length;
      double avgRating = 0.0;
      if (count > 0) {
        final total = docs.fold<double>(0, (sum, doc) {
          final r = doc.data()['rating'];
          return sum + (r is num ? r.toDouble() : 0.0);
        });
        avgRating = total / count;
      }

      // Update the product document in Firestore
      await firestore.FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'rating': avgRating,
        'reviewCount': count,
      });

      // Update local product copy
      final prodIndex = _allProducts.indexWhere((p) => p.productId == productId);
      if (prodIndex >= 0) {
        final p = _allProducts[prodIndex];
        _allProducts[prodIndex] = p.copyWith(
          rating: avgRating,
          reviewCount: count,
        );
        _invalidateProductsCache();
      }
    } catch (e) {
      debugPrint('Failed to update product rating/reviewCount in Firestore: $e');
    }

    // ── 3. Optimistically add to local list (real-time stream will update) ──
    final localReview = Review(
      id: docId,
      productId: productId,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: now,
    );
    reviews.removeWhere((item) => item.id == docId);
    reviews.insert(0, localReview);
    notifyListeners();
  }

  void subscribeAllReviews() {
    if (!_firebaseReady) return;
    _allReviewsStream?.cancel();
    _allReviewsStream = firestore.FirebaseFirestore.instance
        .collectionGroup('items')
        .snapshots()
        .listen((snapshot) {
      reviews
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Review.fromMap(doc.data())));
      notifyListeners();
    }, onError: (error) {
      debugPrint('Firestore reviews collectionGroup stream error: $error');
    });
  }

  void subscribeDailyOffers() {
    if (!_firebaseReady) return;
    _dailyOffersStream?.cancel();
    _dailyOffersStream = firestore.FirebaseFirestore.instance
        .collection('settings')
        .doc('daily_offers')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        firestore.FirebaseFirestore.instance
            .collection('settings')
            .doc('daily_offers')
            .set({
          'monday': 10,
          'tuesday': 15,
          'wednesday': 20,
          'thursday': 25,
          'friday': 30,
          'saturday': 35,
          'sunday': 40,
        });
        return;
      }
      final data = snapshot.data();
      if (data == null) return;
      
      final Map<String, int> newOffers = {};
      data.forEach((key, value) {
        newOffers[key.toLowerCase()] = _int(value);
      });
      if (newOffers.isNotEmpty) {
        dailyOffers = newOffers;
        _invalidateProductsCache();
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('Firestore daily_offers document stream error: $error');
    });
  }

  void subscribeCoupons() {
    if (!_firebaseReady) return;
    _couponsStream?.cancel();
    _couponsStream = firestore.FirebaseFirestore.instance
        .collection('coupons')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        final batch = firestore.FirebaseFirestore.instance.batch();
        for (final coupon in buildCoupons()) {
          final docRef = firestore.FirebaseFirestore.instance.collection('coupons').doc(coupon.code);
          batch.set(docRef, {
            'code': coupon.code,
            'description': coupon.description,
            'discountPercent': coupon.discountPercent,
            'minimumAmount': coupon.minimumAmount,
          });
        }
        await batch.commit();
        return;
      }
      final loaded = snapshot.docs.map((doc) => Coupon.fromMap(doc.data())).toList();
      coupons = loaded;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Firestore coupons collection stream error: $error');
    });
  }

  void subscribeProducts() {
    if (!_firebaseReady) return;
    _productsStream?.cancel();
    _productsStream = firestore.FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      bool changed = false;
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final docData = doc.data();
        if (docData == null) continue;
        final index = _allProducts.indexWhere((p) => p.productId == doc.id);
        if (change.type == firestore.DocumentChangeType.removed) {
          if (index >= 0) {
            _allProducts.removeAt(index);
            changed = true;
          }
        } else {
          // Added or Modified
          if (index >= 0) {
            final existing = _allProducts[index];
            _allProducts[index] = Product(
              productId: existing.productId,
              name: docData['name']?.toString() ?? existing.name,
              category: docData['category']?.toString() ?? existing.category,
              subcategory: (docData['subcategory'] ?? docData['category'])?.toString() ?? existing.subcategory,
              price: docData['price'] != null ? _int(docData['price']) : existing.price,
              oldPrice: docData['oldPrice'] != null ? _int(docData['oldPrice']) : existing.oldPrice,
              customDiscount: docData['customDiscount'] != null ? _int(docData['customDiscount']) : existing.customDiscount,
              discountPercentage: docData['discountPercentage'] != null ? _int(docData['discountPercentage']) : existing.discountPercentage,
              rating: docData['rating'] != null ? _double(docData['rating']) : existing.rating,
              reviewCount: docData['reviewCount'] != null ? _int(docData['reviewCount']) : existing.reviewCount,
              stock: docData['stock'] != null ? _int(docData['stock']) : existing.stock,
              sku: docData['sku']?.toString() ?? existing.sku,
              shortDescription: (docData['shortDescription'] ?? docData['description'])?.toString() ?? existing.shortDescription,
              description: docData['description']?.toString() ?? existing.description,
              specifications: docData['specifications'] != null ? _stringMap(docData['specifications']) : existing.specifications,
              material: docData['material']?.toString() ?? existing.material,
              size: docData['size']?.toString() ?? existing.size,
              color: docData['color']?.toString() ?? existing.color,
              deliveryInfo: docData['deliveryInfo']?.toString() ?? existing.deliveryInfo,
              returnPolicy: docData['returnPolicy']?.toString() ?? existing.returnPolicy,
              warranty: docData['warranty']?.toString() ?? existing.warranty,
              sourceUrl: docData['sourceUrl']?.toString() ?? existing.sourceUrl,
              thumbnail: docData['thumbnail']?.toString() ?? existing.thumbnail,
              galleryImages: docData['galleryImages'] != null ? _strings(docData['galleryImages']) : existing.galleryImages,
              isFeatured: docData['isFeatured'] != null ? docData['isFeatured'] == true : existing.isFeatured,
              isTrending: docData['isTrending'] != null ? docData['isTrending'] == true : existing.isTrending,
              isBestSeller: docData['isBestSeller'] != null ? docData['isBestSeller'] == true : existing.isBestSeller,
              createdAt: docData['createdAt'] != null ? _date(docData['createdAt']) : existing.createdAt,
              updatedAt: _date(docData['updatedAt'] ?? existing.updatedAt),
            );
            changed = true;
          } else {
            final product = Product.fromMap({...docData, 'productId': doc.id});
            _allProducts.insert(0, product);
            changed = true;
          }
        }
      }
      if (changed) {
        categories = buildCategories(_allProducts);
        _invalidateProductsCache();
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('Firestore products stream error: $error');
    });
  }

  double getProductLiveRating(String productId) {
    final prodReviews = reviews.where((r) => r.productId == productId).toList();
    if (prodReviews.isEmpty) return 0;
    final totalRating = prodReviews.fold<double>(0, (sum, r) => sum + r.rating);
    return totalRating / prodReviews.length;
  }

  int getProductLiveReviewCount(String productId) {
    return reviews.where((r) => r.productId == productId).length;
  }

  /// Start listening to real-time Firestore updates for a product's reviews.
  void subscribeProductReviews(String productId) {
    // No-op: handled globally by subscribeAllReviews
  }

  /// Stop listening to the current product's reviews stream.
  void unsubscribeProductReviews() {
    // No-op: handled globally by subscribeAllReviews
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index >= 0) notifications[index] = notifications[index].copyWith(read: true);
    notifyListeners();
    if (backendToken == null) return;
    try {
      await _apiClient.markNotificationRead(notificationId, backendToken!);
    } catch (error) {
      catalogError = error.toString();
    }
  }

  Future<void> createSupportTicket({required String subject, required String message}) async {
    if (_firebaseUid != null) {
      final uid = _firebaseUid!;
      final docId = _uuid.v4();
      final now = DateTime.now();
      final ticket = SupportTicket(
        ticketId: docId,
        subject: subject,
        message: message,
        status: 'open',
        createdAt: now,
      );

      try {
        await firestore.FirebaseFirestore.instance
            .collection('support_tickets')
            .doc(docId)
            .set({
              'ticketId': docId,
              'userId': uid,
              'subject': subject,
              'message': message,
              'status': 'open',
              'createdAt': now.toIso8601String(),
              'userEmail': currentUser?.email ?? firebase_auth.FirebaseAuth.instance.currentUser?.email,
              'userName': currentUser?.name ?? firebase_auth.FirebaseAuth.instance.currentUser?.displayName,
            });
        
        supportTickets.insert(0, ticket);
        notifyListeners();

        // Sync with backend API in the background if token is available
        if (backendToken != null) {
          _apiClient.createSupportTicket(
            subject: subject,
            message: message,
            token: backendToken!,
          ).ignore();
        }
        return;
      } catch (error) {
        catalogError = error.toString();
        rethrow;
      }
    }

    if (backendToken == null) {
      _syncBackendFirebaseSession().ignore();
    }
    if (backendToken == null) {
      throw StateError('Please sign in again before creating a support ticket.');
    }
    try {
      final ticket = await _apiClient.createSupportTicket(
        subject: subject,
        message: message,
        token: backendToken!,
      );
      supportTickets.insert(0, ticket);
      notifyListeners();
    } catch (error) {
      catalogError = error.toString();
      rethrow;
    }
  }

  Future<void> createReturnRequest({required String orderId, required String reason}) async {
    if (_firebaseUid != null) {
      final uid = _firebaseUid!;
      final docId = _uuid.v4();
      final now = DateTime.now();
      final request = ReturnRequest(
        returnId: docId,
        orderId: orderId,
        reason: reason,
        status: 'Requested',
        createdAt: now,
      );

      try {
        await firestore.FirebaseFirestore.instance
            .collection('returns')
            .doc(docId)
            .set({
          'returnId': docId,
          'orderId': orderId,
          'userId': uid,
          'reason': reason,
          'status': 'Requested',
          'createdAt': now.toIso8601String(),
        });
        
        returnRequests.insert(0, request);
        notifyListeners();

        // Sync with backend API in the background if token is available
        if (backendToken != null) {
          _apiClient.createReturnRequest(
            orderId: orderId,
            reason: reason,
            token: backendToken!,
          ).ignore();
        }
        return;
      } catch (error) {
        catalogError = error.toString();
        rethrow;
      }
    }

    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) {
      throw StateError('Please sign in again before creating a return request.');
    }
    try {
      final request = await _apiClient.createReturnRequest(
        orderId: orderId,
        reason: reason,
        token: backendToken!,
      );
      returnRequests.insert(0, request);
      notifyListeners();
    } catch (error) {
      catalogError = error.toString();
      rethrow;
    }
  }

  Future<void> updateInventoryStock({
    required String productId,
    required int stock,
    int lowStockThreshold = 5,
  }) async {
    final clampedStock = stock.clamp(0, 30);
    final timestamp = DateTime.now().toIso8601String();

    // 1. Update local state immediately
    final index = _allProducts.indexWhere((product) => product.productId == productId);
    if (index >= 0) {
      _allProducts[index] = _allProducts[index].copyWith(stock: clampedStock, updatedAt: DateTime.now());
    }

    final updatedItem = InventoryItem(
      productId: productId,
      stock: clampedStock,
      lowStockThreshold: lowStockThreshold,
      lastRestockedAt: DateTime.parse(timestamp),
    );
    inventory.removeWhere((entry) => entry.productId == productId);
    inventory.add(updatedItem);
    _invalidateProductsCache();
    notifyListeners();

    // 2. Persist to Firebase directly (Firebase is the primary stock db)
    if (_firebaseReady) {
      try {
        await firestore.FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .set({
              'stock': clampedStock,
              'updatedAt': timestamp,
            }, firestore.SetOptions(merge: true));
        await firestore.FirebaseFirestore.instance
            .collection('inventory')
            .doc(productId)
            .set({
              'productId': productId,
              'stock': clampedStock,
              'lowStockThreshold': lowStockThreshold,
              'lastRestockedAt': timestamp,
            }, firestore.SetOptions(merge: true));
      } catch (error) {
        catalogError = 'Firestore write failed: $error';
      }
    }

    // 3. Fire-and-forget sync to Render backend to keep in-memory sync'd
    Future<void> syncStock() async {
      if (_firebaseReady && backendToken == null) {
        await _syncBackendFirebaseSession();
      }
      if (backendToken != null && currentUser?.isAdmin == true) {
        try {
          final item = await _apiClient.updateInventory(
            productId: productId,
            stock: clampedStock,
            lowStockThreshold: lowStockThreshold,
            token: backendToken!,
          );
          inventory.removeWhere((entry) => entry.productId == productId);
          inventory.add(item);
          if (hasListeners) notifyListeners();
        } catch (_) {
          // Silently ignore Render backend failures; Firebase is our source of truth
        }
      }
    }
    syncStock().ignore();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentStatus,
  }) async {
    if (currentUser?.isAdmin != true) return;
    // Update Firestore directly (works without backend token)
    if (_firebaseReady) {
      try {
        final Map<String, dynamic> data = {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        if (paymentStatus != null) {
          data['paymentStatus'] = paymentStatus;
        }
        await firestore.FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .set(data, firestore.SetOptions(merge: true));
        _replaceOrder(
          orderId,
          (order) => order.copyWith(
            status: status,
            paymentStatus: paymentStatus ?? order.paymentStatus,
          ),
        );
        notifyListeners();
        return;
      } catch (error) {
        catalogError = 'Order update failed: $error';
        notifyListeners();
      }
    }
    // Fallback: backend API
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.updateOrderStatus(
        orderId: orderId,
        status: status,
        paymentStatus: paymentStatus,
        token: backendToken!,
      );
      final order = _orderFromBackend(saved);
      orders.removeWhere((item) => item.orderId == order.orderId);
      orders.insert(0, order);
    } catch (error) {
      catalogError = error.toString();
    }
    notifyListeners();
  }

  void _replaceOrder(String orderId, AppOrder Function(AppOrder order) updater) {
    final index = orders.indexWhere((order) => order.orderId == orderId);
    if (index >= 0) orders[index] = updater(orders[index]);
  }

  Future<void> _loadFirestoreOrders() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();
      final saved = snapshot.docs
          .map((doc) => _orderFromBackend({...doc.data(), 'orderId': doc.id}))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      orders
        ..clear()
        ..addAll(saved);
      catalogError = null;
    } catch (error) {
      catalogError = 'Order sync failed. Check Firestore rules for orders. $error';
    }
  }

  Future<void> _loadFirestoreSupportTickets() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('support_tickets')
          .where('userId', isEqualTo: uid)
          .get();
      final saved = snapshot.docs
          .map((doc) => SupportTicket.fromMap({
                ...doc.data(),
                'ticketId': doc.id,
              }))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      supportTickets
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = 'Support ticket sync failed. $error';
    }
  }

  Future<void> _loadFirestoreReturnRequests() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('returns')
          .where('userId', isEqualTo: uid)
          .get();
      final saved = snapshot.docs
          .map((doc) => ReturnRequest.fromMap({
                ...doc.data(),
                'returnId': doc.id,
              }))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      returnRequests
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = 'Return request sync failed. $error';
    }
  }

  Future<AppOrder> _saveFirestoreOrder(AppOrder order) async {
    final uid = _firebaseUid;
    if (uid == null) {
      throw StateError('Please sign in again. Order was not saved.');
    }
    try {
      final payload = {
        ..._orderPayload(order),
        'userId': uid,
        'customerEmail': currentUser?.email ?? firebase_auth.FirebaseAuth.instance.currentUser?.email,
        'addressId': order.address.id,
        'createdAt': order.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final db = firestore.FirebaseFirestore.instance;
      final batch = db.batch();
      batch.set(db.collection('orders').doc(order.orderId), payload, firestore.SetOptions(merge: true));
      for (var index = 0; index < order.items.length; index += 1) {
        final line = order.items[index];
        final product = line.product;
        final orderItemId = '${order.orderId}-${index + 1}';
        batch.set(db.collection('order_items').doc(orderItemId), {
          'orderItemId': orderItemId,
          'orderId': order.orderId,
          'userId': uid,
          'productId': product.productId,
          'name': product.name,
          'sku': product.sku,
          'thumbnail': product.thumbnail,
          'color': product.color,
          'size': product.size,
          'quantity': line.quantity,
          'price': product.price,
          'subtotal': line.subtotal,
          'createdAt': order.createdAt.toIso8601String(),
        }, firestore.SetOptions(merge: true));
      }
      await batch.commit();
      catalogError = null;
      return order;
    } catch (error) {
      catalogError = 'Order was not saved to Firestore. Check Firebase rules. $error';
      throw StateError(catalogError!);
    }
  }

  Map<String, dynamic> _orderPayload(AppOrder order) {
    return {
      'orderId': order.orderId,
      'items': order.items.map((line) {
        final product = line.product;
        return {
          'productId': product.productId,
          'name': product.name,
          'sku': product.sku,
          'price': product.price,
          'quantity': line.quantity,
          'thumbnail': product.thumbnail,
          'color': product.color,
          'size': product.size,
        };
      }).toList(),
      'address': order.address.toMap(),
      'status': order.status,
      'paymentStatus': order.paymentStatus,
      'paymentMethod': order.paymentMethod,
      'subtotal': cartSubtotal,
      'deliveryFee': deliveryFee,
      'discount': cartDiscount,
      'total': order.total,
      'razorpayOrderId': order.razorpayOrderId,
      'razorpayPaymentId': order.razorpayPaymentId,
    };
  }

  AppOrder _orderFromBackend(Map<String, dynamic> map, {AppOrder? fallback}) {
    final rawItems = (map['items'] as List? ?? const []).whereType<Map>();
    final items = rawItems.map((item) => _cartLineFromBackend(item.cast<String, dynamic>(), isHistory: true)).toList();
    final rawAddress = map['address'];
    final address = rawAddress is Map
        ? ShippingAddress.fromMap(rawAddress.cast<String, dynamic>())
        : fallback?.address ?? _placeholderOrderAddress;
    return AppOrder(
      orderId: (map['orderId'] ?? fallback?.orderId ?? '').toString(),
      items: items.isEmpty ? fallback?.items ?? [CartLine(product: _allProducts.first, quantity: 1)] : items,
      address: address,
      status: (map['status'] ?? fallback?.status ?? 'Confirmed').toString(),
      paymentStatus: (map['paymentStatus'] ?? fallback?.paymentStatus ?? 'Pending').toString(),
      paymentMethod: (map['paymentMethod'] ?? fallback?.paymentMethod ?? 'Razorpay').toString(),
      total: _intValue(map['total'], fallback?.total ?? 0),
      createdAt: _dateValue(map['createdAt'], fallback?.createdAt ?? DateTime.now()),
      razorpayOrderId: (map['razorpayOrderId'] ?? fallback?.razorpayOrderId)?.toString(),
      razorpayPaymentId: (map['razorpayPaymentId'] ?? fallback?.razorpayPaymentId)?.toString(),
    );
  }

  CartLine _cartLineFromBackend(Map<String, dynamic> map, {bool isHistory = false}) {
    final productId = (map['productId'] ?? '').toString();
    final index = _allProducts.indexWhere((product) => product.productId == productId);
    var source = index >= 0 ? _allProducts[index] : _allProducts.first;
    if (!isHistory) {
      source = applyDynamicPriceToProduct(source);
    }
    final name = (map['name'] ?? '').toString();
    final thumbnail = (map['thumbnail'] ?? '').toString();
    final product = source.copyWith(
      productId: productId.isEmpty ? source.productId : productId,
      name: name.isEmpty ? source.name : name,
      price: isHistory ? _intValue(map['price'], source.price) : source.price,
      discountPercentage: isHistory
          ? _intValue(map['discountPercentage'] ?? map['discount'] ?? source.discountPercentage, source.discountPercentage)
          : source.discountPercentage,
      thumbnail: thumbnail.isEmpty ? source.thumbnail : thumbnail,
      color: (map['color'] ?? source.color).toString(),
      size: (map['size'] ?? source.size).toString(),
    );
    return CartLine(product: product, quantity: _intValue(map['quantity'], 1));
  }

  int _intValue(dynamic value, int fallback) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _intDynamic(dynamic value) => _intValue(value, 0);

  DateTime _dateValue(dynamic value, DateTime fallback) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? fallback;
  }

  ShippingAddress get _placeholderOrderAddress => const ShippingAddress(
        id: 'not-specified',
        name: 'Not Specified',
        phone: 'Not Specified',
        line1: 'Not Specified',
        line2: '',
        city: 'Not Specified',
        state: 'Not Specified',
        pincode: 'Not Specified',
      );

  Future<void> upsertProduct(Product product) async {
    final clampedProduct = product.copyWith(stock: product.stock.clamp(0, 30));
    final index = _allProducts.indexWhere((item) => item.productId == clampedProduct.productId);
    var productToStore = clampedProduct;
    if (_firebaseReady && backendToken == null) {
      await _syncBackendFirebaseSession();
    }
    // Try backend API first
    if (currentUser?.isAdmin == true && backendToken != null) {
      try {
        productToStore = index >= 0
            ? await _apiClient.updateProduct(clampedProduct, backendToken!)
            : await _apiClient.createProduct(clampedProduct, backendToken!);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    // Always persist to Firestore so the product survives page reload
    if (_firebaseReady) {
      try {
        final payload = productToStore.toMap()
          ..['updatedAt'] = DateTime.now().toIso8601String();
        await firestore.FirebaseFirestore.instance
            .collection('products')
            .doc(productToStore.productId)
            .set(payload, firestore.SetOptions(merge: true));
        await firestore.FirebaseFirestore.instance
            .collection('inventory')
            .doc(productToStore.productId)
            .set({
              'productId': productToStore.productId,
              'stock': productToStore.stock,
              'lowStockThreshold': 5,
              'lastRestockedAt': payload['updatedAt'],
            }, firestore.SetOptions(merge: true));
      } catch (error) {
        catalogError = 'Product saved locally but Firestore write failed: $error';
      }
    }
    final productToStoreClamped = productToStore.copyWith(stock: productToStore.stock.clamp(0, 30));
    final doubleCheckIndex = _allProducts.indexWhere((item) => item.productId == productToStoreClamped.productId);
    if (doubleCheckIndex >= 0) {
      _allProducts[doubleCheckIndex] = productToStoreClamped.copyWith(updatedAt: DateTime.now());
    } else {
      _allProducts.insert(0, productToStoreClamped);
    }
    categories = buildCategories(_allProducts);
    _invalidateProductsCache();
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    if (_firebaseReady && backendToken == null) {
      await _syncBackendFirebaseSession();
    }
    if (currentUser?.isAdmin == true && backendToken != null) {
      try {
        await _apiClient.deleteProduct(productId, backendToken!);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    // Also remove from Firestore so it doesn't reappear on next load
    if (_firebaseReady) {
      firestore.FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete()
          .ignore();
    }
    _allProducts.removeWhere((product) => product.productId == productId);
    categories = buildCategories(_allProducts);
    _invalidateProductsCache();
    notifyListeners();
  }

  void toggleDarkMode() async {
    darkMode = !darkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> sendChat(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    chatMessages.add(
      ChatMessage(id: _uuid.v4(), text: clean, isUser: true, createdAt: DateTime.now()),
    );
    notifyListeners();
    if (backendToken == null) {
      await _saveGuestChatHistory();
      await _syncBackendFirebaseSession();
    }
    if (backendToken != null) {
      try {
        final reply = await _apiClient.sendChatMessage(clean, backendToken!);
        chatMessages.add(reply);
        notifyListeners();
        return;
      } catch (error) {
        catalogError = error.toString();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final lower = clean.toLowerCase();
    
    // Determine category constraint if possible
    String? targetCategory;
    if (lower.contains('women wallet') || 
        lower.contains("women's wallet") || 
        lower.contains('women wallets') || 
        lower.contains("women's wallets") ||
        (lower.contains('women') && (lower.contains('wallet') || lower.contains('wallets'))) ||
        (lower.contains('woman') && (lower.contains('wallet') || lower.contains('wallets'))) ||
        (lower.contains('lady') && (lower.contains('wallet') || lower.contains('wallets'))) ||
        (lower.contains('ladies') && (lower.contains('wallet') || lower.contains('wallets')))) {
      targetCategory = 'Women Wallets';
    } else if (lower.contains('men wallet') || 
        lower.contains("men's wallet") || 
        lower.contains('men wallets') || 
        lower.contains("men's wallets") ||
        (lower.contains('men') && (lower.contains('wallet') || lower.contains('wallets'))) ||
        (lower.contains('man') && (lower.contains('wallet') || lower.contains('wallets'))) ||
        lower.contains('coat wallet') ||
        lower.contains('coat wallets')) {
      targetCategory = 'Men Wallets';
    } else if (lower.contains('passport') || lower.contains('passports') || lower.contains('travel')) {
      targetCategory = 'Passport Holders';
    } else if (lower.contains('belt') || lower.contains('belts')) {
      targetCategory = 'Men Belts';
    }

    // Extract query words, excluding stop words
    final stopWords = {
      'show', 'search', 'find', 'me', 'under', 'below', 'above', 'price', 
      'pricing', 'cost', 'how much', 'is', 'are', 'there', 'any', 'available', 
      'availability', 'stock', 'in stock', 'inr', 'rs', 'wallet', 'wallets', 
      'belt', 'belts', 'passport', 'passports', 'cover', 'covers', 'holder', 
      'holders', 'women', "women's", 'woman', "woman's", 'lady', 'ladies', 
      'men', "men's", 'man', "man's", 'gent', 'gents', 'gentlemen', 'travel'
    };
    final words = lower.split(RegExp(r'\s+')).where((w) {
      return !stopWords.contains(w) && w.length > 2 && int.tryParse(w) == null;
    }).toList();

    final recommended = _allProducts.where((product) {
      final category = product.category;
      
      // 1. Category filter
      if (targetCategory != null) {
        if (category != targetCategory) return false;
      } else {
        // Generic fallback check if no specific target category is found
        bool typeMatch = false;
        if ((lower.contains('wallet') || lower.contains('wallets')) && category.contains('Wallet')) typeMatch = true;
        if ((lower.contains('belt') || lower.contains('belts')) && category.contains('Belts')) typeMatch = true;
        if ((lower.contains('passport') || lower.contains('passports')) && category.contains('Passport')) typeMatch = true;
        
        // If query has generic keywords but product doesn't match, filter out
        if ((lower.contains('wallet') || lower.contains('wallets') || 
             lower.contains('belt') || lower.contains('belts') || 
             lower.contains('passport') || lower.contains('passports')) && !typeMatch) {
          return false;
        }
      }
      
      // 2. Keyword filter (if any specific search words exist)
      if (words.isNotEmpty) {
        final haystack = '${product.name} ${product.category} ${product.subcategory} ${product.color}'.toLowerCase();
        return words.any((word) => haystack.contains(word));
      }
      
      return true;
    }).take(4).map((product) => product.productId).toList();
    final reply = _dummyReply(clean, lower, recommended);
    chatMessages.add(
      ChatMessage(
        id: _uuid.v4(),
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
        recommendedProductIds: recommended.isEmpty
            ? trendingProducts.take(4).map((product) => product.productId).toList()
            : recommended,
      ),
    );
    notifyListeners();
    await _saveGuestChatHistory();
  }

  String _dummyReply(String original, String lower, List<String> recommended) {
    if (lower.contains('order') || lower.contains('track')) {
      return 'I can help with order status. Open My Orders to view confirmation, payment state, and delivery tracking.';
    }
    if (lower.contains('return')) {
      return 'MOSPL products include a 7 day return or replacement policy for unused items with tags.';
    }
    if (lower.contains('gift')) {
      return 'For gifting, I recommend MOSPL wallets, passport holders, hand woven belts, and women wallets from the current catalog. I have added a few options below.';
    }
    if (recommended.isNotEmpty) {
      return 'Here are MOSPL leather products that match your request. Most carry 30% off, free shipping, and 5 day delivery.';
    }
    return 'I cannot help with "$original". I am the MOSPL AI Assistant and can only help with leather products, orders, returns, or support. Tell me what you are shopping for: men wallet, coat wallet, hand woven belt, passport holder, or women wallet.';
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    if (currentUser == null || !rememberMe) return;
    await prefs.setString('uid', currentUser!.uid);
    await prefs.setString('userEmail', currentUser!.email);
    await prefs.setString('userName', currentUser!.name);
    await prefs.setString('userRole', currentUser!.role);
    if (backendToken != null) await prefs.setString('backendToken', backendToken!);
  }

  Future<void> _syncBackendLogin({
    required String email,
    required String password,
  }) async {
    try {
      _applyAuthSession(await _apiClient.loginSession(email: email.trim(), password: password));
    } catch (_) {
      // First attempt failed (e.g. Render cold start). Wait and retry once.
      await Future<void>.delayed(const Duration(seconds: 10));
      try {
        _applyAuthSession(await _apiClient.loginSession(email: email.trim(), password: password));
      } catch (_) {
        await _syncBackendFirebaseSession();
      }
    }
  }

  Future<void> _syncBackendRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _applyAuthSession(await _apiClient.registerSession(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ));
      if (backendToken == null) {
        _applyAuthSession(await _apiClient.loginSession(email: email.trim(), password: password));
      }
    } catch (_) {
      try {
        _applyAuthSession(await _apiClient.loginSession(email: email.trim(), password: password));
      } catch (_) {
        await _syncBackendFirebaseSession();
      }
    }
  }

  Future<void> _syncBackendFirebaseSession() async {
    if (!_firebaseReady) return;
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final idToken = await user.getIdToken(attempt > 0); // force refresh on retry
        if (idToken == null || idToken.isEmpty) return;
        _applyAuthSession(await _apiClient.firebaseAuthSession(idToken));
        if (backendToken != null) await _persistUser();
        subscribeDailyOffers();
        subscribeCoupons();
        subscribeProducts();
        return; // success
      } catch (_) {
        if (attempt < 2) {
          // Short back-off: 2 s then 4 s (was 8 s / 16 s) so Render cold-starts
          // don't block the UI for more than ~6 seconds total.
          await Future<void>.delayed(Duration(seconds: (attempt + 1) * 2));
        } else {
          backendToken = null;
        }
      }
    }
  }

  void _applyAuthSession(AuthSession session) {
    final hadToken = backendToken != null;
    backendToken = session.token;
    if (session.user != null) currentUser = session.user;
    // Start real-time Firestore streams as soon as we have a Firebase UID.
    // This covers the case where restoreSession() wasn't able to start them
    // (e.g. Render cold-start forced a retry).
    final uid = _firebaseUid;
    if (uid != null) _startRealtimeSync(uid);
    // Also do a one-shot reload if we just obtained a token for the first time
    // to immediately populate all authenticated details (cart, wishlist, and admin data if applicable).
    if (!hadToken && backendToken != null) {
      loadAuthenticatedData(notify: true).ignore();
    }
  }

  Future<void> _loadLocalAddresses() async {
    final key = _addressStorageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      addresses
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((item) => ShippingAddress.fromMap(item.cast<String, dynamic>())),
        );
    } catch (_) {}
  }

  Future<void> _saveLocalAddresses() async {
    final key = _addressStorageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(addresses.map((address) => address.toMap()).toList()),
    );
  }

  String? get _addressStorageKey {
    final email = currentUser?.email.trim().toLowerCase();
    if (email == null || email.isEmpty) return null;
    return 'addresses:$email';
  }

  String? _validateEmailPassword(String email, String password, {required bool isSignup}) {
    final clean = email.trim();
    final validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(clean);
    if (!validEmail) return 'Enter a valid email address.';
    if (isSignup) {
      final parts = clean.split('@');
      if (parts.length == 2) {
        final domain = parts[1].toLowerCase();
        if (domain != 'email.com' && domain != 'gmail.com') {
          return 'You entered invalid email or gmail';
        }
      }
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (isSignup && !RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Password should include letters and numbers.';
    }
    return null;
  }

  bool get _firebaseReady => firebase_core.Firebase.apps.isNotEmpty;

  String? get _firebaseUid {
    if (!_firebaseReady) return null;
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  String _authFailureMessage(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Invalid email or password.';
        case 'weak-password':
          return 'Use a stronger password.';
        case 'network-request-failed':
          return 'Check your internet connection and try again.';
      }
    }
    return 'Authentication failed. Please try again.';
  }

  void _pushNotification(String title, String body) {
    if (!notificationsEnabled) return;
    notifications.insert(
      0,
      AppNotification(id: _uuid.v4(), title: title, body: body, createdAt: DateTime.now()),
    );
  }

  void _seedLocalData() {
    notifications.addAll([
      AppNotification(
        id: _uuid.v4(),
        title: '30% OFF MOSPL leather goods',
        body: 'Wallets, belts, and passport holders now start at ₹595.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: _uuid.v4(),
        title: 'Free shipping',
        body: 'All MOSPL products include 5 day delivery and free shipping.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);
    chatMessages.add(
      ChatMessage(
        id: _uuid.v4(),
        text: 'Hi, I am your MOSPL shopping assistant. Ask me for wallet, belt, passport holder, gift, order, or return help.',
        isUser: false,
        createdAt: DateTime.now(),
        recommendedProductIds: trendingProducts.take(3).map((product) => product.productId).toList(),
      ),
    );
    reviews.addAll([
      Review(
        id: _uuid.v4(),
        productId: _allProducts.first.productId,
        userName: 'Anbazhagan',
        rating: 5,
        comment: 'Very good product. Nice to use.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Review(
        id: _uuid.v4(),
        productId: _allProducts[12].productId,
        userName: 'Priya S',
        rating: 4.5,
        comment: 'Good storage and clean finishing for the price.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  Future<void> updateDailyOffers(Map<String, int> schedule) async {
    if (_firebaseReady && backendToken == null) {
      await _syncBackendFirebaseSession();
    }
    if (_firebaseReady) {
      try {
        await firestore.FirebaseFirestore.instance
            .collection('settings')
            .doc('daily_offers')
            .set(schedule);
      } catch (error) {
        debugPrint('Firestore updateDailyOffers error: $error');
      }
    }
    if (backendToken != null && currentUser?.isAdmin == true) {
      try {
        final updated = await _apiClient.updateDailyOffers(schedule, backendToken!);
        dailyOffers = updated;
        _invalidateProductsCache();
        notifyListeners();
      } catch (error) {
        catalogError = error.toString();
        rethrow;
      }
    } else {
      dailyOffers = schedule;
      _invalidateProductsCache();
      notifyListeners();
    }
  }
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

List<String> _strings(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item.toString()));
  }
  return const {};
}

