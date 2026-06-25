import '../models.dart';

const _notSpecified = 'Not Specified';
final _snapshotAt = DateTime.utc(2026, 6, 10);

String _image(int productId, String file) {
  final normalizedFile = file.toLowerCase().replaceAll('.jpeg', '.jpg');
  return 'assets/products/p${productId}_$normalizedFile';
}

List<String> _gallery(int productId, List<String> files) {
  return files.map((file) => _image(productId, file)).toList();
}

class _WebsiteProduct {
  const _WebsiteProduct({
    required this.sourceProductId,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.oldPrice,
    required this.color,
    required this.reviewCount,
    required this.galleryImages,
    required this.specifications,
  }) : returnPolicy = '7-Day Easy Return | No Questions Asked',
       warranty = '6-Month Brand Warranty';

  final int sourceProductId;
  final String name;
  final String category;
  final String subcategory;
  final int price;
  final int oldPrice;
  final String color;
  final int reviewCount;
  final List<String> galleryImages;
  final Map<String, String> specifications;
  final String returnPolicy;
  final String warranty;
}

final List<_WebsiteProduct> _websiteProducts = [
  // ── Men Wallets (p1–p5, p12, p13) ──────────────────────────────────────────
  _WebsiteProduct(
    sourceProductId: 1,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(1, ['2186188.JPG', '4475235.JPG', '1381835.JPG', '9756552.JPG', '8885992.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '7',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),
  _WebsiteProduct(
    sourceProductId: 2,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(2, ['215679.JPG', '9528665.JPG', '6118426.JPG', '5442007.JPG', '4114825.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),
  _WebsiteProduct(
    sourceProductId: 3,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(3, ['4841724.JPG', '9719345.JPG', '3675476.JPG', '2839403.JPG', '3130607.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),
  _WebsiteProduct(
    sourceProductId: 4,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(4, ['4924639.JPG', '4674009.JPG', '8795280.JPG', '556440.JPG', '2082995.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),
  _WebsiteProduct(
    sourceProductId: 5,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(5, ['7392122.JPG', '5773488.JPG', '8596671.JPG', '3186778.JPG', '3493921.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '7',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),

  // ── Passport Holders (p6, p7) ───────────────────────────────────────────────
  // From image analysis: p6 is a slim upright passport holder with zipper top.
  // p7 interior shows: passport slot, 4 card slots, 2 currency pockets, ID window.
  _WebsiteProduct(
    sourceProductId: 6,
    name: 'MOSPL Genuine Leather Passport Holder (Black)',
    category: 'Passport Holders',
    subcategory: 'Passport Holder',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(6, ['1140001.JPG', '9990583.JPG', '7696777.JPG', '3321365.JPG', '3680334.JPG']),
    specifications: const {
      'Height': '145 mm',
      'Width': '105 mm',
      'Card Slots': '4',
      'No. of Pocket': '3',
      'Pattern': 'Plain',
      'No. of Compartments': '3',
      'Closure Type': 'Zipper',
      'Passport Slots': '1',
    },
  ),
  // p7 interior: MOSPL logo embossed, 6 card slots, currency pocket, ID window, passport slot.
  _WebsiteProduct(
    sourceProductId: 7,
    name: 'MOSPL Genuine Leather Passport Holder (Black)',
    category: 'Passport Holders',
    subcategory: 'Passport Holder',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(7, ['3345797.JPG', '7005130.JPG', '621840.JPG', '3975609.JPG', '8493715.JPG']),
    specifications: const {
      'Height': '145 mm',
      'Width': '105 mm',
      'Card Slots': '6',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '4',
      'Closure Type': 'Button Snap',
      'Passport Slots': '1',
    },
  ),

  // ── Men Belts (p8–p11) ──────────────────────────────────────────────────────
  // p8: Hand-woven / braided leather belt with pin buckle.
  _WebsiteProduct(
    sourceProductId: 8,
    name: "MOSPL Men's Genuine Leather Belt - Hand Woven (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 875,
    oldPrice: 1250,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(8, ['652892.JPG', '7926995.JPG', '8224742.JPG', '3770165.JPG', '746286.JPG']),
    specifications: const {
      'Length': '120 cm (Adjustable)',
      'Width': '35 mm',
      'Pattern': 'Hand Woven / Braided',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Metal Alloy',
      'Closure Type': 'Pin Buckle',
      'Fit Type': 'Adjustable',
    },
  ),
  // p9: Plain leather belt with double stitch edge and rectangular pin buckle.
  _WebsiteProduct(
    sourceProductId: 9,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(9, ['6248711.JPG', '5277605.JPG', '2744921.JPG', '5791804.JPG', '26221.JPG']),
    specifications: const {
      'Length': '120 cm (Adjustable)',
      'Width': '35 mm',
      'Pattern': 'Plain with Contrast Stitch',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Metal Alloy',
      'Closure Type': 'Pin Buckle',
      'Fit Type': 'Adjustable',
    },
  ),
  // p10: Glossy plain leather belt with square rectangular buckle.
  _WebsiteProduct(
    sourceProductId: 10,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(10, ['2581993.JPG', '6739940.JPG', '416401.JPG', '5746914.JPG', '7960762.JPG']),
    specifications: const {
      'Length': '120 cm (Adjustable)',
      'Width': '32 mm',
      'Pattern': 'Plain',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Zinc Alloy',
      'Closure Type': 'Pin Buckle',
      'Finish': 'Glossy',
    },
  ),
  // p11: Plain belt with large square gold-tone buckle.
  _WebsiteProduct(
    sourceProductId: 11,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(11, ['7287021.JPG', '7926209.JPG', '7124796.JPG', '7582711.JPG', '9156093.JPG']),
    specifications: const {
      'Length': '120 cm (Adjustable)',
      'Width': '38 mm',
      'Pattern': 'Plain',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Gold-Tone Alloy',
      'Closure Type': 'Pin Buckle',
      'Finish': 'Matte',
    },
  ),

  // ── Men Wallets continued (p12, p13) ────────────────────────────────────────
  _WebsiteProduct(
    sourceProductId: 12,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(12, ['2404056.JPG', '582778.JPG', '7723671.JPG', '812228.JPG', '8463781.JPG']),
    specifications: const {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '6',
      'No. of Pocket': '2',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),
  _WebsiteProduct(
    sourceProductId: 13,
    name: "MOSPL Men's Genuine Leather Coat Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 1,
    galleryImages: _gallery(13, ['1618531.JPG', '3553288.JPG', '942869.JPG', '4594764.JPG', '6377884.JPG']),
    specifications: const {
      'Height': '120 mm',
      'Width': '100 mm',
      'Card Slots': '13',
      'No. of Pocket': '8',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  ),

  // ── Women Wallets (p14–p18) ─────────────────────────────────────────────────
  // p14: Envelope-style women wallet. Interior: 9 card slots, 1 zip coin pocket,
  //      2 currency slots, 1 ID window → 3 main pockets.
  _WebsiteProduct(
    sourceProductId: 14,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(14, ['9515557.JPG', '6892907.JPG', '8749304.JPG', '5513411.JPG', '3908219.JPG']),
    specifications: const {
      'Height': '110 mm',
      'Width': '180 mm',
      'Card Slots': '9',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '6',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  ),
  // p15: Same envelope style in Brown. Same internal layout as p14.
  _WebsiteProduct(
    sourceProductId: 15,
    name: 'MOSPL Women Genuine Leather Wallet (Brown)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Brown',
    reviewCount: 0,
    galleryImages: _gallery(15, ['6488801.JPG', '3995984.JPG', '9135591.JPG', '2925960.JPG', '7517531.JPG']),
    specifications: const {
      'Height': '110 mm',
      'Width': '180 mm',
      'Card Slots': '9',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '6',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  ),
  // p16: Wide flap women wallet (Black). Interior has 5 card slots, 7 compartments.
  _WebsiteProduct(
    sourceProductId: 16,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(16, ['8676670.JPG', '7011476.JPG', '8541991.JPG', '289662.JPG', '5303010.JPG']),
    specifications: const {
      'Height': '110 mm',
      'Width': '220 mm',
      'Card Slots': '5',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '7',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  ),
  // p17: Same as p16 in Brown.
  _WebsiteProduct(
    sourceProductId: 17,
    name: 'MOSPL Women Genuine Leather Wallet (Brown)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Brown',
    reviewCount: 0,
    galleryImages: _gallery(17, ['915622.JPG', '9612313.JPG', '6276838.JPG', '7410161.JPG', '4219408.JPG']),
    specifications: const {
      'Height': '110 mm',
      'Width': '220 mm',
      'Card Slots': '5',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '7',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  ),
  // p18: Long bifold women wallet (Black). Interior: 13 card slots, 4 compartments,
  //      1 ID window, 1 zip coin pocket → 3 pockets.
  _WebsiteProduct(
    sourceProductId: 18,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: _gallery(18, ['8076164.JPG', '7315913.JPG', '6518186.JPG', '5153835.JPG', '4419334.JPG']),
    specifications: const {
      'Height': '100 mm',
      'Width': '190 mm',
      'Card Slots': '13',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '4',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  ),
];

Map<String, String> _normalizedSpecifications(_WebsiteProduct record) {
  final specs = record.specifications;
  final Map<String, String> normalized = {
    'Color': record.color,
    'Material': 'Genuine Leather',
    'Stock': '30',
  };

  // Add all product-specific specs in order
  for (final entry in specs.entries) {
    normalized[entry.key] = entry.value;
  }

  return normalized;
}

String _sizeFromSpecs(Map<String, String> specifications) {
  final height = specifications['Height'];
  final width = specifications['Width'];
  final length = specifications['Length'];
  if (length != null) return length;
  if (height == null || width == null) return _notSpecified;
  return '$height x $width';
}

List<Product> buildMosplProducts() {
  return [
    for (var index = 0; index < _websiteProducts.length; index++)
      _buildProduct(_websiteProducts[index], index),
  ];
}

Product _buildProduct(_WebsiteProduct record, int index) {
  final specs = _normalizedSpecifications(record);
  final sourceUrl = 'https://onlinemadras.com/product.php?product_id=${record.sourceProductId}';
  return Product(
    productId: 'MOSPL-OM-${record.sourceProductId.toString().padLeft(3, '0')}',
    name: record.name,
    category: record.category,
    subcategory: record.subcategory,
    price: record.price,
    oldPrice: record.oldPrice,
    customDiscount: 0,
    discountPercentage: record.oldPrice > 0 ? ((record.oldPrice - record.price) * 100 / record.oldPrice).round() : 0,
    rating: 0,
    reviewCount: record.reviewCount,
    stock: 30,
    sku: _notSpecified,
    shortDescription: record.name,
    description: record.name,
    specifications: specs,
    material: 'Genuine Leather',
    size: _sizeFromSpecs(specs),
    color: record.color,
    deliveryInfo: 'Delivered by: 5 Days | Free Shipping',
    returnPolicy: record.returnPolicy,
    warranty: record.warranty,
    sourceUrl: sourceUrl,
    thumbnail: record.galleryImages.first,
    galleryImages: record.galleryImages,
    isFeatured: false,
    isTrending: false,
    isBestSeller: false,
    createdAt: _snapshotAt.subtract(Duration(days: index)),
    updatedAt: _snapshotAt,
  );
}

List<ProductCategory> buildCategories(List<Product> products) {
  final order = ['Men Wallets', 'Passport Holders', 'Men Belts', 'Women Wallets'];
  return [
    for (final name in order)
      if (products.any((product) => product.category == name))
        ProductCategory(
          id: name.toLowerCase().replaceAll(' ', '-'),
          name: name,
          subtitle: _categorySubtitle(name),
          imageUrl: products.firstWhere((product) => product.category == name).thumbnail,
          productCount: products.where((product) => product.category == name).length,
        ),
  ];
}

String _categorySubtitle(String name) {
  switch (name) {
    case 'Men Wallets':
      return 'MOSPL wallet styles currently listed';
    case 'Passport Holders':
      return 'MOSPL passport holders currently listed';
    case 'Men Belts':
      return 'MOSPL belts currently listed';
    case 'Women Wallets':
      return 'MOSPL women wallets currently listed';
    default:
      return _notSpecified;
  }
}

List<Coupon> buildCoupons() => const [
      Coupon(
        code: 'MOSPL30',
        description: '30% off reference pricing from Online Madras product pages',
        discountPercent: 30,
        minimumAmount: 595,
      ),
    ];
