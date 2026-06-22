import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl);

  final http.Client _client;
  final String baseUrl;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'MOSPL_API_BASE_URL',
    defaultValue: '',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return 'https://mospl-final-1.onrender.com';
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<List<Product>> fetchProducts() async {
    final json = await _getJson('/api/products');
    final products = (json['products'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _withAbsoluteImages(item.cast<String, dynamic>()))
        .map(Product.fromMap)
        .toList();
    if (products.isEmpty) {
      throw const FormatException('Backend returned no products.');
    }
    return products;
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final json = await _getJson('/api/categories');
    return (json['categories'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _withAbsoluteImageUrl(item.cast<String, dynamic>()))
        .map(ProductCategory.fromMap)
        .toList();
  }

  Future<List<Coupon>> fetchCoupons() async {
    final json = await _getJson('/api/coupons');
    return (json['coupons'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Coupon.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<List<BannerItem>> fetchBanners() async {
    final json = await _getJson('/api/banners');
    return (json['banners'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _withAbsoluteImageUrl(item.cast<String, dynamic>()))
        .map(BannerItem.fromMap)
        .toList();
  }

  Future<AuthSession> loginSession({required String email, required String password}) async {
    final json = await _postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<String?> login({required String email, required String password}) async {
    return (await loginSession(email: email, password: password)).token;
  }

  Future<AuthSession> registerSession({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _postJson('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return (await registerSession(name: name, email: email, password: password)).token;
  }

  Future<AuthSession> firebaseAuthSession(String idToken) async {
    final json = await _postJson('/api/auth/firebase-session', {
      'idToken': idToken,
    });
    return AuthSession.fromJson(json);
  }

  Future<String?> firebaseSession(String idToken) async {
    return (await firebaseAuthSession(idToken)).token;
  }

  Future<AppUser> updateProfile({
    required String name,
    required String email,
    required String token,
  }) async {
    final json = await _patchJson('/api/auth/profile', {
      'name': name,
      'email': email,
    }, token: token);
    return AppUser.fromMap((json['user'] as Map).cast<String, dynamic>());
  }

  Future<Product> createProduct(Product product, String token) async {
    final json = await _postJson('/api/products', product.toMap(), token: token);
    return Product.fromMap(_withAbsoluteImages((json['product'] as Map).cast<String, dynamic>()));
  }

  Future<Product> updateProduct(Product product, String token) async {
    final json = await _putJson('/api/products/${product.productId}', product.toMap(), token: token);
    return Product.fromMap(_withAbsoluteImages((json['product'] as Map).cast<String, dynamic>()));
  }

  Future<void> deleteProduct(String productId, String token) async {
    await _delete('/api/products/$productId', token: token);
  }

  Future<List<CartLine>> fetchCart(String token) async {
    final json = await _getJson('/api/cart', token: token);
    return _cartLines(json['items']);
  }

  Future<List<CartLine>> addCartItem({
    required String productId,
    required int quantity,
    required String token,
  }) async {
    final json = await _postJson('/api/cart/items', {
      'productId': productId,
      'quantity': quantity,
    }, token: token);
    return _cartLines(json['items']);
  }

  Future<List<CartLine>> updateCartItem({
    required String productId,
    required int quantity,
    required String token,
  }) async {
    final json = await _patchJson('/api/cart/items/$productId', {
      'quantity': quantity,
    }, token: token);
    return _cartLines(json['items']);
  }

  Future<List<CartLine>> removeCartItem(String productId, String token) async {
    final json = await _deleteJson('/api/cart/items/$productId', token: token);
    return _cartLines(json['items']);
  }

  Future<void> clearCart(String token) async {
    await _delete('/api/cart', token: token);
  }

  Future<Set<String>> fetchWishlist(String token) async {
    final json = await _getJson('/api/wishlist', token: token);
    return (json['productIds'] as List? ?? const []).map((item) => item.toString()).toSet();
  }

  Future<Set<String>> addWishlistProduct(String productId, String token) async {
    final json = await _postJson('/api/wishlist/$productId', {}, token: token);
    return (json['productIds'] as List? ?? const []).map((item) => item.toString()).toSet();
  }

  Future<Set<String>> removeWishlistProduct(String productId, String token) async {
    final json = await _deleteJson('/api/wishlist/$productId', token: token);
    return (json['productIds'] as List? ?? const []).map((item) => item.toString()).toSet();
  }

  Future<List<ShippingAddress>> fetchAddresses(String token) async {
    final json = await _getJson('/api/addresses', token: token);
    return (json['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ShippingAddress.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ShippingAddress> createAddress(ShippingAddress address, String token) async {
    final json = await _postJson('/api/addresses', address.toMap(), token: token);
    return ShippingAddress.fromMap((json['address'] as Map).cast<String, dynamic>());
  }

  Future<ShippingAddress> updateAddress(ShippingAddress address, String token) async {
    final json = await _patchJson('/api/addresses/${address.id}', address.toMap(), token: token);
    return ShippingAddress.fromMap((json['address'] as Map).cast<String, dynamic>());
  }

  Future<List<ShippingAddress>> deleteAddress(String addressId, String token) async {
    final json = await _deleteJson('/api/addresses/$addressId', token: token);
    return (json['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ShippingAddress.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String token) async {
    final json = await _getJson('/api/orders', token: token);
    return (json['orders'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order, String token) async {
    final json = await _postJson('/api/orders', order, token: token);
    return (json['order'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchOrder(String orderId, String token) async {
    final json = await _getJson('/api/orders/$orderId', token: token);
    return (json['order'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String paymentStatus,
    required String token,
  }) async {
    final json = await _patchJson('/api/orders/$orderId/status', {
      'status': status,
      'paymentStatus': paymentStatus,
    }, token: token);
    return (json['order'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createPaymentOrder({
    required int amount,
    required String receipt,
    required String token,
  }) async {
    return _postJson('/api/payments/create-order', {
      'amount': amount,
      'receipt': receipt,
    }, token: token);
  }

  Future<PaymentRecord> verifyPayment({
    required String orderId,
    required int amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String token,
  }) async {
    final json = await _postJson('/api/payments/verify', {
      'orderId': orderId,
      'amount': amount,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    }, token: token);
    return PaymentRecord.fromMap((json['payment'] as Map).cast<String, dynamic>());
  }

  Future<List<PaymentRecord>> fetchPaymentHistory(String token) async {
    final json = await _getJson('/api/payments/history', token: token);
    return (json['payments'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => PaymentRecord.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> retryPayment(String orderId, String token) async {
    return _postJson('/api/payments/$orderId/retry', {}, token: token);
  }

  Future<List<Review>> fetchReviews({String? productId}) async {
    final path = productId == null ? '/api/reviews' : '/api/reviews/product/$productId';
    final json = await _getJson(path);
    return (json['reviews'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Review.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Review> createReview({
    required String productId,
    required double rating,
    required String comment,
    required String token,
  }) async {
    final json = await _postJson('/api/reviews', {
      'productId': productId,
      'rating': rating,
      'comment': comment,
    }, token: token);
    return Review.fromMap((json['review'] as Map).cast<String, dynamic>());
  }

  Future<List<AppNotification>> fetchNotifications(String token) async {
    final json = await _getJson('/api/notifications', token: token);
    return (json['notifications'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AppNotification.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<AppNotification> createNotification({
    required String title,
    required String body,
    String? userId,
    required String token,
  }) async {
    final payload = {
      'title': title,
      'body': body,
    };
    if (userId != null) payload['userId'] = userId;
    final json = await _postJson('/api/notifications', payload, token: token);
    return AppNotification.fromMap((json['notification'] as Map).cast<String, dynamic>());
  }

  Future<void> markNotificationRead(String notificationId, String token) async {
    await _patchJson('/api/notifications/$notificationId/read', {}, token: token);
  }

  Future<ChatMessage> sendChatMessage(String text, String token) async {
    final json = await _postJson('/api/chatbot/message', {'text': text}, token: token);
    return ChatMessage.fromMap((json['message'] as Map).cast<String, dynamic>());
  }

  Future<List<ChatMessage>> fetchChatHistory(String token) async {
    final json = await _getJson('/api/chatbot/history', token: token);
    return (json['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ChatMessage.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<List<InventoryItem>> fetchInventory(String token, {bool lowStock = false}) async {
    final json = await _getJson('/api/inventory${lowStock ? '?lowStock=true' : ''}', token: token);
    return (json['inventory'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => InventoryItem.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<InventoryItem> updateInventory({
    required String productId,
    required int stock,
    required int lowStockThreshold,
    required String token,
  }) async {
    final json = await _patchJson('/api/inventory/$productId', {
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
    }, token: token);
    return InventoryItem.fromMap((json['inventory'] as Map).cast<String, dynamic>());
  }

  Future<List<ReturnRequest>> fetchReturns(String token) async {
    final json = await _getJson('/api/returns', token: token);
    return (json['returns'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ReturnRequest.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ReturnRequest> createReturnRequest({
    required String orderId,
    required String reason,
    required String token,
  }) async {
    final json = await _postJson('/api/returns', {
      'orderId': orderId,
      'reason': reason,
    }, token: token);
    return ReturnRequest.fromMap((json['returnRequest'] as Map).cast<String, dynamic>());
  }

  Future<List<SupportTicket>> fetchSupportTickets(String token) async {
    final json = await _getJson('/api/support-tickets', token: token);
    return (json['tickets'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => SupportTicket.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
    required String token,
  }) async {
    final json = await _postJson('/api/support-tickets', {
      'subject': subject,
      'message': message,
    }, token: token);
    return SupportTicket.fromMap((json['ticket'] as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> fetchAdminDashboard(String token) async {
    return _getJson('/api/admin/dashboard', token: token);
  }

  Future<List<AppUser>> fetchAdminUsers(String token) async {
    final json = await _getJson('/api/admin/users', token: token);
    return (json['users'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AppUser.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> fetchAdminAnalytics(String token) async {
    return _getJson('/api/admin/analytics', token: token);
  }

  Future<Map<String, dynamic>> _getJson(String path, {String? token}) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$path'), headers: _headers(token: token))
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Future<void> _delete(String path, {String? token}) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl$path'), headers: _headers(token: token))
        .timeout(const Duration(seconds: 30));
    _decode(response);
  }

  Future<Map<String, dynamic>> _deleteJson(String path, {String? token}) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl$path'), headers: _headers(token: token))
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response body is not a JSON object.');
      }
      json = decoded;
    } catch (_) {
      throw ApiException(
        response.statusCode,
        response.body.trim().isEmpty ? 'Backend returned an empty response.' : 'Backend returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || json['ok'] == false) {
      throw ApiException(response.statusCode, json['message']?.toString() ?? 'Backend request failed.');
    }
    return json;
  }

  Map<String, dynamic> _withAbsoluteImages(Map<String, dynamic> product) {
    return {
      ...product,
      'thumbnail': _absoluteMediaUrl(product['thumbnail']?.toString() ?? ''),
      'galleryImages': (product['galleryImages'] as List? ?? const [])
          .map((item) => _absoluteMediaUrl(item.toString()))
          .toList(),
    };
  }

  Map<String, dynamic> _withAbsoluteImageUrl(Map<String, dynamic> category) {
    return {
      ...category,
      'imageUrl': _absoluteMediaUrl(category['imageUrl']?.toString() ?? ''),
    };
  }

  List<CartLine> _cartLines(dynamic value) {
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .where((item) => item['product'] is Map)
        .map((item) {
          final product = Product.fromMap(_withAbsoluteImages((item['product'] as Map).cast<String, dynamic>()));
          final quantity = (item['quantity'] as num?)?.round() ?? 1;
          return CartLine(product: product, quantity: quantity);
        })
        .toList();
  }

  String _absoluteMediaUrl(String value) {
    if (value.isEmpty || value.startsWith('http://') || value.startsWith('https://') || value.startsWith('assets/')) {
      return value;
    }
    if (!value.startsWith('/')) return '$baseUrl/$value';
    return '$baseUrl$value';
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String? token;
  final AppUser? user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthSession(
      token: json['token']?.toString(),
      user: rawUser is Map ? AppUser.fromMap(rawUser.cast<String, dynamic>()) : null,
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
