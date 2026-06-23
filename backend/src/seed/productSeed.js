const NOT_SPECIFIED = 'Not Specified';
const SOURCE_HOST = 'https://onlinemadras.com';
const SNAPSHOT_AT = '2026-06-10T00:00:00.000Z';

function image(productId, file) {
  return `/static/products/p${productId}_${file.toLowerCase().replace('.jpeg', '.jpg')}`;
}

function gallery(productId, files) {
  return files.map((file) => image(productId, file));
}

const websiteProducts = [
  {
    sourceProductId: 1,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(1, ['2186188.JPG', '4475235.JPG', '1381835.JPG', '9756552.JPG', '8885992.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '7',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 2,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(2, ['215679.JPG', '9528665.JPG', '6118426.JPG', '5442007.JPG', '4114825.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 3,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(3, ['4841724.JPG', '9719345.JPG', '3675476.JPG', '2839403.JPG', '3130607.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 4,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(4, ['4924639.JPG', '4674009.JPG', '8795280.JPG', '556440.JPG', '2082995.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '8',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 5,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(5, ['7392122.JPG', '5773488.JPG', '8596671.JPG', '3186778.JPG', '3493921.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '7',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 6,
    name: 'MOSPL Genuine Leather Passport Holder (Black)',
    category: 'Passport Holders',
    subcategory: 'Passport Holder',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(6, ['1140001.JPG', '9990583.JPG', '7696777.JPG', '3321365.JPG', '3680334.JPG']),
    specifications: {
      'Height': '145 mm',
      'Width': '105 mm',
      'Card Slots': '4',
      'No. of Pocket': '3',
      'Pattern': 'Plain',
      'No. of Compartments': '3',
      'Closure Type': 'Zipper',
      'Passport Slots': '1',
    },
  },
  {
    sourceProductId: 7,
    name: 'MOSPL Genuine Leather Passport Holder (Black)',
    category: 'Passport Holders',
    subcategory: 'Passport Holder',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(7, ['3345797.JPG', '7005130.JPG', '621840.JPG', '3975609.JPG', '8493715.JPG']),
    specifications: {
      'Height': '145 mm',
      'Width': '105 mm',
      'Card Slots': '6',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '4',
      'Closure Type': 'Button Snap',
      'Passport Slots': '1',
    },
  },
  {
    sourceProductId: 8,
    name: "MOSPL Men's Genuine Leather Belt - Hand Woven (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 875,
    oldPrice: 1250,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(8, ['652892.JPG', '7926995.JPG', '8224742.JPG', '3770165.JPG', '746286.JPG']),
    specifications: {
      'Length': '120 cm (Adjustable)',
      'Width': '35 mm',
      'Pattern': 'Hand Woven / Braided',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Metal Alloy',
      'Closure Type': 'Pin Buckle',
      'Fit Type': 'Adjustable',
    },
  },
  {
    sourceProductId: 9,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(9, ['6248711.JPG', '5277605.JPG', '2744921.JPG', '5791804.JPG', '26221.JPG']),
    specifications: {
      'Length': '120 cm (Adjustable)',
      'Width': '35 mm',
      'Pattern': 'Plain with Contrast Stitch',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Metal Alloy',
      'Closure Type': 'Pin Buckle',
      'Fit Type': 'Adjustable',
    },
  },
  {
    sourceProductId: 10,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(10, ['2581993.JPG', '6739940.JPG', '416401.JPG', '5746914.JPG', '7960762.JPG']),
    specifications: {
      'Length': '120 cm (Adjustable)',
      'Width': '32 mm',
      'Pattern': 'Plain',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Zinc Alloy',
      'Closure Type': 'Pin Buckle',
      'Finish': 'Glossy',
    },
  },
  {
    sourceProductId: 11,
    name: "MOSPL Men's Genuine Leather Belt (Black)",
    category: 'Men Belts',
    subcategory: 'Belts',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(11, ['7287021.JPG', '7926209.JPG', '7124796.JPG', '7582711.JPG', '9156093.JPG']),
    specifications: {
      'Length': '120 cm (Adjustable)',
      'Width': '38 mm',
      'Pattern': 'Plain',
      'Buckle Type': 'Pin Buckle',
      'Buckle Material': 'Gold-Tone Alloy',
      'Closure Type': 'Pin Buckle',
      'Finish': 'Matte',
    },
  },
  {
    sourceProductId: 12,
    name: "MOSPL Men's Genuine Leather Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(12, ['2404056.JPG', '582778.JPG', '7723671.JPG', '812228.JPG', '8463781.JPG']),
    specifications: {
      'Height': '90 mm',
      'Width': '120 mm',
      'Card Slots': '6',
      'No. of Pocket': '2',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 13,
    name: "MOSPL Men's Genuine Leather Coat Wallet (Black)",
    category: 'Men Wallets',
    subcategory: 'Wallets',
    price: 595,
    oldPrice: 850,
    color: 'Black',
    reviewCount: 1,
    galleryImages: gallery(13, ['1618531.JPG', '3553288.JPG', '942869.JPG', '4594764.JPG', '6377884.JPG']),
    specifications: {
      'Height': '120 mm',
      'Width': '100 mm',
      'Card Slots': '13',
      'No. of Pocket': '8',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '2',
      'Closure Type': 'Flap',
      'Stitching': 'Double Stitch',
    },
  },
  {
    sourceProductId: 14,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(14, ['9515557.JPG', '6892907.JPG', '8749304.JPG', '5513411.JPG', '3908219.JPG']),
    specifications: {
      'Height': '110 mm',
      'Width': '180 mm',
      'Card Slots': '9',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '6',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  },
  {
    sourceProductId: 15,
    name: 'MOSPL Women Genuine Leather Wallet (Brown)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Brown',
    reviewCount: 0,
    galleryImages: gallery(15, ['6488801.JPG', '3995984.JPG', '9135591.JPG', '2925960.JPG', '7517531.JPG']),
    specifications: {
      'Height': '110 mm',
      'Width': '180 mm',
      'Card Slots': '9',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '6',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  },
  {
    sourceProductId: 16,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(16, ['8676670.JPG', '7011476.JPG', '8541991.JPG', '289662.JPG', '5303010.JPG']),
    specifications: {
      'Height': '110 mm',
      'Width': '220 mm',
      'Card Slots': '5',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '7',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  },
  {
    sourceProductId: 17,
    name: 'MOSPL Women Genuine Leather Wallet (Brown)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Brown',
    reviewCount: 0,
    galleryImages: gallery(17, ['915622.JPG', '9612313.JPG', '6276838.JPG', '7410161.JPG', '4219408.JPG']),
    specifications: {
      'Height': '110 mm',
      'Width': '220 mm',
      'Card Slots': '5',
      'No. of Pocket': '4',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '7',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  },
  {
    sourceProductId: 18,
    name: 'MOSPL Women Genuine Leather Wallet (Black)',
    category: 'Women Wallets',
    subcategory: 'Wallets',
    price: 980,
    oldPrice: 1400,
    color: 'Black',
    reviewCount: 0,
    galleryImages: gallery(18, ['8076164.JPG', '7315913.JPG', '6518186.JPG', '5153835.JPG', '4419334.JPG']),
    specifications: {
      'Height': '100 mm',
      'Width': '190 mm',
      'Card Slots': '13',
      'No. of Pocket': '3',
      'Pattern': 'Brand Embossed',
      'No. of Compartments': '4',
      'Closure Type': 'Button Snap',
      'Coin Pocket': 'Yes (Zip)',
    },
  },
];

function sourceUrl(sourceProductId) {
  return `${SOURCE_HOST}/product.php?product_id=${sourceProductId}`;
}

function sizeFromSpecs(specifications) {
  const height = specifications['Height'];
  const width = specifications['Width'];
  const length = specifications['Length'];
  if (length) return length;
  if (!height || !width || height === NOT_SPECIFIED || width === NOT_SPECIFIED) return NOT_SPECIFIED;
  return `${height} x ${width}`;
}

function normalizeSpecifications(record) {
  const specs = {
    Color: record.color || NOT_SPECIFIED,
    Material: 'Genuine Leather',
    Stock: '30',
  };
  
  if (record.specifications) {
    for (const [key, value] of Object.entries(record.specifications)) {
      specs[key] = value || NOT_SPECIFIED;
    }
  }
  
  return specs;
}

function buildProducts() {
  return websiteProducts.map((record, index) => {
    const productId = `MOSPL-OM-${String(record.sourceProductId).padStart(3, '0')}`;
    const specifications = normalizeSpecifications(record);
    return {
      productId,
      name: record.name,
      category: record.category,
      subcategory: record.subcategory,
      price: record.price,
      oldPrice: record.oldPrice,
      discountPercentage: Math.round(((record.oldPrice - record.price) * 100) / record.oldPrice),
      rating: 0,
      reviewCount: record.reviewCount,
      stock: 30,
      sku: NOT_SPECIFIED,
      shortDescription: record.name,
      description: record.name,
      specifications,
      material: 'Genuine Leather',
      size: sizeFromSpecs(specifications),
      color: record.color || NOT_SPECIFIED,
      deliveryInfo: 'Delivered by: 5 Days | Free Shipping',
      returnPolicy: '7-Day Easy Return | No Questions Asked',
      warranty: '6-Month Brand Warranty',
      sourceUrl: sourceUrl(record.sourceProductId),
      thumbnail: record.galleryImages[0],
      galleryImages: record.galleryImages,
      isFeatured: false,
      isTrending: false,
      isBestSeller: false,
      createdAt: new Date(Date.parse(SNAPSHOT_AT) - index * 86400000).toISOString(),
      updatedAt: SNAPSHOT_AT,
    };
  });
}

function buildCategories(products = buildProducts()) {
  return ['Men Wallets', 'Passport Holders', 'Men Belts', 'Women Wallets']
    .map((name) => {
      const items = products.filter((product) => product.category === name);
      const sample = items[0] || products[0];
      return {
        categoryId: name.toLowerCase().replace(/\s+/g, '-'),
        name,
        subtitle: categorySubtitle(name),
        imageUrl: sample.thumbnail,
        productCount: items.length,
        isActive: true,
        createdAt: SNAPSHOT_AT,
      };
    })
    .filter((category) => category.productCount > 0);
}

function categorySubtitle(name) {
  return {
    'Men Wallets': 'MOSPL wallet styles currently listed',
    'Passport Holders': 'MOSPL passport holders currently listed',
    'Men Belts': 'MOSPL belts currently listed',
    'Women Wallets': 'MOSPL women wallets currently listed',
  }[name] || NOT_SPECIFIED;
}

function buildCoupons() {
  return [
    { code: 'MOSPL30', description: '30% off reference pricing from Online Madras product pages', discountPercent: 30, minimumAmount: 595, isActive: true },
  ];
}

function buildBanners() {
  return [
    {
      bannerId: 'banner-mospl-wallets',
      title: 'MOSPL leather wallets',
      subtitle: 'Current Online Madras MOSPL wallet listings',
      imageUrl: image(4, '4924639.JPG'),
      isActive: true,
    },
    {
      bannerId: 'banner-mospl-belts',
      title: 'MOSPL leather belts',
      subtitle: 'Formal and hand woven belt listings',
      imageUrl: image(8, '652892.JPG'),
      isActive: true,
    },
    {
      bannerId: 'banner-mospl-passport',
      title: 'MOSPL passport holders',
      subtitle: 'Current travel holder listings',
      imageUrl: image(6, '1140001.JPG'),
      isActive: true,
    },
  ];
}

module.exports = { buildProducts, buildCategories, buildCoupons, buildBanners };
