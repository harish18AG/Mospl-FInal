import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String inr(num value) => _currency.format(value);

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
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

class Product {
  const Product({
    required this.productId,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.oldPrice,
    required this.customDiscount,
    required this.discountPercentage,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.sku,
    required this.shortDescription,
    required this.description,
    required this.specifications,
    required this.material,
    required this.size,
    required this.color,
    required this.deliveryInfo,
    required this.returnPolicy,
    required this.warranty,
    required this.sourceUrl,
    required this.thumbnail,
    required this.galleryImages,
    required this.isFeatured,
    required this.isTrending,
    required this.isBestSeller,
    required this.createdAt,
    required this.updatedAt,
  });

  final String productId;
  final String name;
  final String category;
  final String subcategory;
  final int price;
  final int oldPrice;
  final int customDiscount;
  final int discountPercentage;
  final double rating;
  final int reviewCount;
  final int stock;
  final String sku;
  final String shortDescription;
  final String description;
  final Map<String, String> specifications;
  final String material;
  final String size;
  final String color;
  final String deliveryInfo;
  final String returnPolicy;
  final String warranty;
  final String sourceUrl;
  final String thumbnail;
  final List<String> galleryImages;
  final bool isFeatured;
  final bool isTrending;
  final bool isBestSeller;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get inStock => stock > 0;
  String get priceLabel => inr(price);
  String get oldPriceLabel => inr(oldPrice);
  String get discountLabel => '$discountPercentage% OFF';

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Not Specified',
      category: map['category']?.toString() ?? 'Not Specified',
      subcategory: (map['subcategory'] ?? map['category'])?.toString() ?? 'Not Specified',
      price: map['price'] != null ? _int(map['price']) : 0,
      oldPrice: map['oldPrice'] != null ? _int(map['oldPrice']) : (map['price'] != null ? _int(map['price']) : 0),
      customDiscount: map['customDiscount'] != null ? _int(map['customDiscount']) : 0,
      discountPercentage: map['discountPercentage'] != null ? _int(map['discountPercentage']) : 0,
      rating: map['rating'] != null ? _double(map['rating']) : 0.0,
      reviewCount: map['reviewCount'] != null ? _int(map['reviewCount']) : 0,
      stock: map['stock'] != null ? _int(map['stock']) : 0,
      sku: map['sku']?.toString() ?? 'Not Specified',
      shortDescription: (map['shortDescription'] ?? map['description'] ?? 'Not Specified').toString(),
      description: (map['description'] ?? map['shortDescription'] ?? 'Not Specified').toString(),
      specifications: _stringMap(map['specifications']),
      material: map['material']?.toString() ?? 'Not Specified',
      size: map['size']?.toString() ?? 'Not Specified',
      color: map['color']?.toString() ?? 'Not Specified',
      deliveryInfo: map['deliveryInfo']?.toString() ?? 'Not Specified',
      returnPolicy: map['returnPolicy']?.toString() ?? 'Not Specified',
      warranty: map['warranty']?.toString() ?? 'Not Specified',
      sourceUrl: (map['sourceUrl'] ?? _stringMap(map['specifications'])['Source URL'] ?? 'Not Specified').toString(),
      thumbnail: map['thumbnail']?.toString() ?? '',
      galleryImages: _strings(map['galleryImages']),
      isFeatured: map['isFeatured'] == true,
      isTrending: map['isTrending'] == true,
      isBestSeller: map['isBestSeller'] == true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'oldPrice': oldPrice,
        'customDiscount': customDiscount,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'reviewCount': reviewCount,
        'stock': stock,
        'sku': sku,
        'shortDescription': shortDescription,
        'description': description,
        'specifications': specifications,
        'material': material,
        'size': size,
        'color': color,
        'deliveryInfo': deliveryInfo,
        'returnPolicy': returnPolicy,
        'warranty': warranty,
        'sourceUrl': sourceUrl,
        'thumbnail': thumbnail,
        'galleryImages': galleryImages,
        'isFeatured': isFeatured,
        'isTrending': isTrending,
        'isBestSeller': isBestSeller,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Product copyWith({
    String? productId,
    String? name,
    String? category,
    String? subcategory,
    int? price,
    int? oldPrice,
    int? customDiscount,
    int? discountPercentage,
    double? rating,
    int? reviewCount,
    int? stock,
    String? sku,
    String? shortDescription,
    String? description,
    Map<String, String>? specifications,
    String? material,
    String? size,
    String? color,
    String? deliveryInfo,
    String? returnPolicy,
    String? warranty,
    String? sourceUrl,
    String? thumbnail,
    List<String>? galleryImages,
    bool? isFeatured,
    bool? isTrending,
    bool? isBestSeller,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      customDiscount: customDiscount ?? this.customDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      material: material ?? this.material,
      size: size ?? this.size,
      color: color ?? this.color,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      warranty: warranty ?? this.warranty,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      galleryImages: galleryImages ?? this.galleryImages,
      isFeatured: isFeatured ?? this.isFeatured,
      isTrending: isTrending ?? this.isTrending,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Product) return false;

    if (galleryImages.length != other.galleryImages.length) return false;
    for (int i = 0; i < galleryImages.length; i++) {
      if (galleryImages[i] != other.galleryImages[i]) return false;
    }

    return productId == other.productId &&
        name == other.name &&
        category == other.category &&
        subcategory == other.subcategory &&
        price == other.price &&
        oldPrice == other.oldPrice &&
        customDiscount == other.customDiscount &&
        discountPercentage == other.discountPercentage &&
        rating == other.rating &&
        reviewCount == other.reviewCount &&
        stock == other.stock &&
        sku == other.sku &&
        shortDescription == other.shortDescription &&
        description == other.description &&
        material == other.material &&
        size == other.size &&
        color == other.color &&
        deliveryInfo == other.deliveryInfo &&
        returnPolicy == other.returnPolicy &&
        warranty == other.warranty &&
        sourceUrl == other.sourceUrl &&
        thumbnail == other.thumbnail &&
        isFeatured == other.isFeatured &&
        isTrending == other.isTrending &&
        isBestSeller == other.isBestSeller;
  }

  @override
  int get hashCode => productId.hashCode;
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.productCount,
  });

  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final int productCount;

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: (map['id'] ?? map['categoryId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      productCount: (map['productCount'] as num?)?.round() ?? 0,
    );
  }
}

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  int get subtotal => product.price * quantity;

  CartLine copyWith({Product? product, int? quantity}) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  String get shortLabel => '$line1, $city - $pincode';

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: (map['id'] ?? map['addressId']).toString(),
      name: map['name'].toString(),
      phone: map['phone'].toString(),
      line1: map['line1'].toString(),
      line2: (map['line2'] ?? '').toString(),
      city: map['city'].toString(),
      state: map['state'].toString(),
      pincode: map['pincode'].toString(),
      isDefault: map['isDefault'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'addressId': id,
        'name': name,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
      };
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  final String uid;
  final String email;
  final String name;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      name: (map['name'] ?? map['email'] ?? 'MOSPL User').toString(),
      role: (map['role'] ?? 'customer').toString(),
    );
  }
}

class AppOrder {
  const AppOrder({
    required this.orderId,
    required this.items,
    required this.address,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
    this.razorpayOrderId,
    this.razorpayPaymentId,
  });

  final String orderId;
  final List<CartLine> items;
  final ShippingAddress address;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final int total;
  final DateTime createdAt;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;

  String get totalLabel => inr(total);

  AppOrder copyWith({
    String? status,
    String? paymentStatus,
    String? razorpayOrderId,
    String? razorpayPaymentId,
  }) {
    return AppOrder(
      orderId: orderId,
      items: items,
      address: address,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod,
      total: total,
      createdAt: createdAt,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
  });

  final String paymentId;
  final String orderId;
  final int amount;
  final String status;
  final String method;
  final DateTime createdAt;

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      paymentId: (map['paymentId'] ?? map['razorpayPaymentId'] ?? '').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      amount: _int(map['amount']),
      status: (map['status'] ?? 'Pending').toString(),
      method: (map['method'] ?? map['currency'] ?? 'Razorpay').toString(),
      createdAt: _date(map['createdAt']),
    );
  }
}

class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: (map['id'] ?? map['reviewId'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      userName: (map['userName'] ?? map['customerName'] ?? 'MOSPL Customer').toString(),
      rating: _double(map['rating'], 0),
      comment: (map['comment'] ?? '').toString(),
      createdAt: _date(map['createdAt']),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: (map['id'] ?? map['notificationId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      createdAt: _date(map['createdAt']),
      read: map['read'] == true,
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.recommendedProductIds = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<String> recommendedProductIds;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] ?? map['messageId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      isUser: map['isUser'] == true,
      createdAt: _date(map['createdAt']),
      recommendedProductIds: _strings(map['recommendedProductIds']),
    );
  }
}

class Coupon {
  const Coupon({
    required this.code,
    required this.description,
    required this.discountPercent,
    required this.minimumAmount,
  });

  final String code;
  final String description;
  final int discountPercent;
  final int minimumAmount;

  factory Coupon.fromMap(Map<String, dynamic> map) {
    return Coupon(
      code: (map['code'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      discountPercent: (map['discountPercent'] as num?)?.round() ?? 0,
      minimumAmount: (map['minimumAmount'] as num?)?.round() ?? 0,
    );
  }
}

class BannerItem {
  const BannerItem({
    required this.bannerId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.isActive = true,
  });

  final String bannerId;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isActive;

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      bannerId: (map['bannerId'] ?? map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      isActive: map['isActive'] != false,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.productId,
    required this.stock,
    required this.lowStockThreshold,
    required this.lastRestockedAt,
  });

  final String productId;
  final int stock;
  final int lowStockThreshold;
  final DateTime lastRestockedAt;

  bool get isLowStock => stock <= lowStockThreshold;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      productId: (map['productId'] ?? '').toString(),
      stock: _int(map['stock']),
      lowStockThreshold: _int(map['lowStockThreshold'], 5),
      lastRestockedAt: _date(map['lastRestockedAt'] ?? map['updatedAt']),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.ticketId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.reply,
  });

  final String ticketId;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? reply;

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      ticketId: (map['ticketId'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      status: (map['status'] ?? 'open').toString(),
      createdAt: _date(map['createdAt']),
      reply: map['reply']?.toString(),
    );
  }
}

class ReturnRequest {
  const ReturnRequest({
    required this.returnId,
    required this.orderId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String returnId;
  final String orderId;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory ReturnRequest.fromMap(Map<String, dynamic> map) {
    return ReturnRequest(
      returnId: (map['returnId'] ?? '').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      status: (map['status'] ?? 'Requested').toString(),
      createdAt: _date(map['createdAt']),
    );
  }
}

class AdminMetrics {
  const AdminMetrics({
    required this.revenue,
    required this.products,
    required this.orders,
    required this.users,
    required this.lowStock,
    required this.payments,
  });

  final int revenue;
  final int products;
  final int orders;
  final int users;
  final int lowStock;
  final int payments;

  factory AdminMetrics.fromMap(Map<String, dynamic> map) {
    return AdminMetrics(
      revenue: _int(map['revenue']),
      products: _int(map['products']),
      orders: _int(map['orders']),
      users: _int(map['users']),
      lowStock: _int(map['lowStock']),
      payments: _int(map['payments']),
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.metrics,
    required this.recentOrders,
    required this.productPerformance,
  });

  final AdminMetrics metrics;
  final List<AppOrder> recentOrders;
  final List<Product> productPerformance;
}

class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.revenueByDay,
    required this.salesByCategory,
    required this.inventoryAlerts,
  });

  final List<int> revenueByDay;
  final List<Map<String, dynamic>> salesByCategory;
  final List<InventoryItem> inventoryAlerts;
}
