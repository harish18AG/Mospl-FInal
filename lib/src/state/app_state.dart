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

  List<Product> get allProducts => List.unmodifiable(_allProducts);

  List<Product> get visibleProducts {
    Iterable<Product> result = _allProducts;
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
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case 'Newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        list.sort((a, b) {
          final aScore = (a.isBestSeller ? 2 : 0) + (a.isTrending ? 1 : 0);
          final bScore = (b.isBestSeller ? 2 : 0) + (b.isTrending ? 1 : 0);
          return bScore.compareTo(aScore);
        });
    }
    return list;
  }

  List<Product> get featuredProducts {
    final flagged = _allProducts.where((p) => p.isFeatured).take(16).toList();
    return flagged.isEmpty ? _allProducts.take(16).toList() : flagged;
  }

  List<Product> get trendingProducts {
    final flagged = _allProducts.where((p) => p.isTrending).take(24).toList();
    return flagged.isEmpty ? _allProducts.take(24).toList() : flagged;
  }

  List<Product> get bestSellers {
    final flagged = _allProducts.where((p) => p.isBestSeller).take(16).toList();
    return flagged.isEmpty ? _allProducts.take(16).toList() : flagged;
  }
  List<Product> get wishlistProducts => _allProducts.where((p) => wishlist.contains(p.productId)).toList();
  List<Product> get recommendations {
    final seen = recentlyViewed.map((p) => p.category).toSet();
    final pool = seen.isEmpty ? trendingProducts : _allProducts.where((p) => seen.contains(p.category)).toList();
    return pool.take(24).toList();
  }

  int get cartCount => cart.fold(0, (total, line) => total + line.quantity);
  int get cartSubtotal => cart.fold(0, (total, line) => total + line.subtotal);
  int get deliveryFee => cartSubtotal >= 595 || cart.isEmpty ? 0 : 49;
  int get cartDiscount => min(300, (cartSubtotal * 0.08).round());
  int get cartTotal => max(0, cartSubtotal + deliveryFee - cartDiscount);
  int get unreadNotifications => notifications.where((item) => !item.read).length;
  int get totalRevenue => adminMetrics?.revenue ?? orders.fold(0, (total, order) => total + order.total);
  int get lowStockCount =>
      adminMetrics?.lowStock ?? (inventory.isEmpty ? _allProducts.where((product) => product.stock < 15).length : inventory.where((item) => item.isLowStock).length);

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
      ]);
      final products = results[0] as List<Product>;
      final backendCategories = results[1] as List<ProductCategory>;
      final backendCoupons = results[2] as List<Coupon>;
      final backendBanners = results[3] as List<BannerItem>;

      _allProducts
        ..clear()
        ..addAll(products);
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
      catalogLoading = false;
      notifyListeners();
    }
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
    final role = prefs.getString('userRole') ?? 'customer';
    if (email != null && name != null && rememberMe) {
      currentUser = AppUser(
        uid: firebaseUser?.uid ?? prefs.getString('uid') ?? 'local-user',
        email: email,
        name: name,
        role: role,
      );
      await _syncBackendFirebaseSession();
      await loadAuthenticatedData(notify: false);
    }
    notifyListeners();
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
        currentUser = AppUser(
          uid: user?.uid ?? 'firebase-user',
          email: email.trim(),
          name: user?.displayName ?? email.split('@').first,
          role: 'customer',
        );
      } else {
        currentUser = AppUser(
          uid: 'local-${email.hashCode.abs()}',
          email: email.trim(),
          name: email.split('@').first,
          role: 'customer',
        );
      }
      await _syncBackendLogin(email: email, password: password);
      rememberMe = remember;
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
        currentUser = AppUser(
          uid: credential.user?.uid ?? 'firebase-user',
          email: email.trim(),
          name: name.trim(),
          role: 'customer',
        );
      } else {
        currentUser = AppUser(
          uid: 'local-${email.hashCode.abs()}',
          email: email.trim(),
          name: name.trim(),
          role: 'customer',
        );
      }
      await _syncBackendRegister(name: name, email: email, password: password);
      rememberMe = remember;
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
    notifyListeners();
  }

  void updateSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setSort(String value) {
    sortOption = value;
    notifyListeners();
  }

  void setPriceFilter(int? min, int? max) {
    minPrice = min;
    maxPrice = max;
    notifyListeners();
  }

  void clearFilters() {
    selectedCategory = null;
    minPrice = null;
    maxPrice = null;
    sortOption = 'Recommended';
    notifyListeners();
  }

  Product productById(String id) {
    return _allProducts.firstWhere((product) => product.productId == id, orElse: () => _allProducts.first);
  }

  void viewProduct(Product product) {
    recentlyViewed.removeWhere((item) => item.productId == product.productId);
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 20) recentlyViewed.removeLast();
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final index = cart.indexWhere((line) => line.product.productId == product.productId);
    if (index >= 0) {
      cart[index] = cart[index].copyWith(quantity: cart[index].quantity + quantity);
    } else {
      cart.add(CartLine(product: product, quantity: quantity));
    }
    _pushNotification('Added to cart', product.name);
    notifyListeners();
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
    } catch (error) {
      catalogError = error.toString();
    }
    notifyListeners();
  }

  Future<void> setCartQuantity(String productId, int quantity) async {
    final index = cart.indexWhere((line) => line.product.productId == productId);
    if (index < 0) return;
    if (quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(quantity: quantity);
    }
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    cart.removeWhere((line) => line.product.productId == productId);
    notifyListeners();
    if (backendToken == null) return;
    try {
      final saved = await _apiClient.removeCartItem(productId, backendToken!);
      cart
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    notifyListeners();
  }

  Future<void> toggleWishlist(Product product) async {
    final shouldAdd = !wishlist.contains(product.productId);
    if (!wishlist.add(product.productId)) {
      wishlist.remove(product.productId);
    } else {
      _pushNotification('Wishlist updated', '${product.name} saved for later.');
    }
    notifyListeners();
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) return;
    try {
      final saved = shouldAdd
          ? await _apiClient.addWishlistProduct(product.productId, backendToken!)
          : await _apiClient.removeWishlistProduct(product.productId, backendToken!);
      wishlist
        ..clear()
        ..addAll(saved);
    } catch (error) {
      catalogError = error.toString();
    }
    notifyListeners();
  }

  bool isWishlisted(String productId) => wishlist.contains(productId);

  Future<void> loadAuthenticatedData({bool notify = true}) async {
    if (backendToken == null) {
      await _syncBackendFirebaseSession();
    }
    await _loadLocalAddresses();
    if (backendToken == null) {
      await loadAddresses(notify: false);
      await loadOrders(notify: false);
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
      await _syncBackendFirebaseSession();
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
    if (backendToken == null) {
      await _syncBackendFirebaseSession();
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

  Future<void> loadReturns({bool notify = true}) async {
    if (backendToken == null) return;
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
    if (backendToken == null) return;
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
    if (backendToken == null || currentUser?.isAdmin != true) return;
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
      if (orders.isEmpty) {
        orders
          ..clear()
          ..addAll(recentOrders);
      }
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
      paymentStatus: paymentMethod == 'Razorpay' ? 'Pending' : 'Paid',
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
    cart.clear();
    _pushNotification('Order placed', '${order.orderId} is confirmed.');
    notifyListeners();
    return order;
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
      } catch (error) {
        catalogError = error.toString();
      }
    }
    _replaceOrder(
      orderId,
      (order) => order.copyWith(
        paymentStatus: 'Paid',
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
      ),
    );
    notifyListeners();
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
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) throw StateError('Please sign in again before adding a review.');
    final review = await _apiClient.createReview(
      productId: productId,
      rating: rating,
      comment: comment,
      token: backendToken!,
    );
    reviews.removeWhere((item) => item.id == review.id);
    reviews.insert(0, review);
    notifyListeners();
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
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) throw StateError('Please sign in again before creating a support ticket.');
    final ticket = await _apiClient.createSupportTicket(
      subject: subject,
      message: message,
      token: backendToken!,
    );
    supportTickets.insert(0, ticket);
    notifyListeners();
  }

  Future<void> createReturnRequest({required String orderId, required String reason}) async {
    if (backendToken == null) await _syncBackendFirebaseSession();
    if (backendToken == null) throw StateError('Please sign in again before creating a return request.');
    final request = await _apiClient.createReturnRequest(
      orderId: orderId,
      reason: reason,
      token: backendToken!,
    );
    returnRequests.insert(0, request);
    notifyListeners();
  }

  Future<void> updateInventoryStock({
    required String productId,
    required int stock,
    int lowStockThreshold = 15,
  }) async {
    if (backendToken == null || currentUser?.isAdmin != true) return;
    final item = await _apiClient.updateInventory(
      productId: productId,
      stock: stock,
      lowStockThreshold: lowStockThreshold,
      token: backendToken!,
    );
    inventory.removeWhere((entry) => entry.productId == productId);
    inventory.add(item);
    final index = _allProducts.indexWhere((product) => product.productId == productId);
    if (index >= 0) _allProducts[index] = _allProducts[index].copyWith(stock: stock, updatedAt: DateTime.now());
    notifyListeners();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String paymentStatus,
  }) async {
    if (backendToken == null || currentUser?.isAdmin != true) return;
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
    final items = rawItems.map((item) => _cartLineFromBackend(item.cast<String, dynamic>())).toList();
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

  CartLine _cartLineFromBackend(Map<String, dynamic> map) {
    final productId = (map['productId'] ?? '').toString();
    final index = _allProducts.indexWhere((product) => product.productId == productId);
    final source = index >= 0 ? _allProducts[index] : _allProducts.first;
    final name = (map['name'] ?? '').toString();
    final thumbnail = (map['thumbnail'] ?? '').toString();
    final product = source.copyWith(
      productId: productId.isEmpty ? source.productId : productId,
      name: name.isEmpty ? source.name : name,
      price: _intValue(map['price'], source.price),
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
    final index = _allProducts.indexWhere((item) => item.productId == product.productId);
    var productToStore = product;
    if (currentUser?.isAdmin == true && backendToken != null) {
      try {
        productToStore = index >= 0
            ? await _apiClient.updateProduct(product, backendToken!)
            : await _apiClient.createProduct(product, backendToken!);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    if (index >= 0) {
      _allProducts[index] = productToStore.copyWith(updatedAt: DateTime.now());
    } else {
      _allProducts.insert(0, productToStore);
    }
    categories = buildCategories(_allProducts);
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    if (currentUser?.isAdmin == true && backendToken != null) {
      try {
        await _apiClient.deleteProduct(productId, backendToken!);
      } catch (error) {
        catalogError = error.toString();
      }
    }
    _allProducts.removeWhere((product) => product.productId == productId);
    categories = buildCategories(_allProducts);
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
    if (backendToken == null) await _syncBackendFirebaseSession();
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
    final recommended = _allProducts.where((product) {
      final haystack = '${product.name} ${product.category} ${product.subcategory}'.toLowerCase();
      return lower.split(' ').any((word) => word.length > 3 && haystack.contains(word)) ||
          (lower.contains('wallet') && product.category.contains('Wallet')) ||
          (lower.contains('belt') && product.category.contains('Belts')) ||
          (lower.contains('travel') && product.category.contains('Passport'));
    }).take(4).map((product) => product.productId).toList();
    final reply = _dummyReply(lower, recommended);
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
  }

  String _dummyReply(String lower, List<String> recommended) {
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
    return 'Tell me what you are shopping for: men wallet, coat wallet, hand woven belt, passport holder, or women wallet.';
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
      await _syncBackendFirebaseSession();
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
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      _applyAuthSession(await _apiClient.firebaseAuthSession(idToken));
      if (backendToken != null) await _persistUser();
    } catch (_) {
      backendToken = null;
    }
  }

  void _applyAuthSession(AuthSession session) {
    backendToken = session.token;
    if (session.user != null) currentUser = session.user;
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
}
