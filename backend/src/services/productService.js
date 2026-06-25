const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('./store');

const NOT_SPECIFIED = 'Not Specified';

function normalizeProduct(payload, existing = {}) {
  const now = new Date().toISOString();
  const oldPrice = Number(payload.oldPrice ?? existing.oldPrice ?? payload.price ?? existing.price ?? 0);
  const customDiscount = payload.customDiscount !== undefined
    ? (payload.customDiscount === null ? 0 : Number(payload.customDiscount))
    : (existing.customDiscount !== undefined ? Number(existing.customDiscount) : 0);

  let price = Number(payload.price ?? existing.price ?? 0);
  if (customDiscount > 0) {
    price = oldPrice - Math.round((oldPrice * customDiscount) / 100);
  }

  const galleryImages = payload.galleryImages || existing.galleryImages || [];
  const thumbnail = payload.thumbnail || existing.thumbnail || galleryImages[0] || '/static/products/product_fallback.png';
  return {
    productId: payload.productId || existing.productId || `MOSPL-API-${Date.now()}`,
    name: payload.name || existing.name || NOT_SPECIFIED,
    category: payload.category || existing.category || NOT_SPECIFIED,
    subcategory: payload.subcategory || existing.subcategory || payload.category || existing.category || NOT_SPECIFIED,
    price,
    oldPrice,
    customDiscount,
    discountPercentage: Number(
      payload.discountPercentage ??
        existing.discountPercentage ??
        (oldPrice > 0 ? Math.round(((oldPrice - price) * 100) / oldPrice) : 0),
    ),
    rating: Number(payload.rating ?? existing.rating ?? 0),
    reviewCount: Number(payload.reviewCount ?? existing.reviewCount ?? 0),
    stock: Math.min(30, Math.max(0, Number(payload.stock ?? existing.stock ?? 1))),
    sku: payload.sku || existing.sku || NOT_SPECIFIED,
    shortDescription: payload.shortDescription || existing.shortDescription || payload.description || existing.description || payload.name || existing.name || NOT_SPECIFIED,
    description: payload.description || existing.description || payload.shortDescription || existing.shortDescription || payload.name || existing.name || NOT_SPECIFIED,
    specifications: payload.specifications || existing.specifications || {},
    material: payload.material || existing.material || NOT_SPECIFIED,
    size: payload.size || existing.size || NOT_SPECIFIED,
    color: payload.color || existing.color || NOT_SPECIFIED,
    deliveryInfo: payload.deliveryInfo || existing.deliveryInfo || NOT_SPECIFIED,
    returnPolicy: payload.returnPolicy || existing.returnPolicy || NOT_SPECIFIED,
    warranty: payload.warranty || existing.warranty || NOT_SPECIFIED,
    sourceUrl: payload.sourceUrl || existing.sourceUrl || existing.specifications?.['Source URL'] || NOT_SPECIFIED,
    thumbnail,
    galleryImages: galleryImages.length ? galleryImages : [thumbnail],
    isFeatured: payload.isFeatured ?? existing.isFeatured ?? false,
    isTrending: payload.isTrending ?? existing.isTrending ?? false,
    isBestSeller: payload.isBestSeller ?? existing.isBestSeller ?? false,
    createdAt: payload.createdAt || existing.createdAt || now,
    updatedAt: now,
  };
}

async function getDailyOffers() {
  if (isFirebaseConfigured && db) {
    try {
      const doc = await db.collection('settings').doc('daily_offers').get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
  }
  return store.dailyOffers;
}

function applyDynamicPrice(product, dailyOffers) {
  if (!product) return product;
  const customDiscount = Number(product.customDiscount ?? 0);
  let discountPercentage = 0;
  if (customDiscount > 0) {
    discountPercentage = customDiscount;
  } else {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const dayName = days[new Date().getDay()];
    discountPercentage = Number(dailyOffers[dayName] ?? 0);
  }
  const oldPrice = Number(product.oldPrice || product.price || 0);
  const price = oldPrice - Math.round((oldPrice * discountPercentage) / 100);
  return {
    ...product,
    discountPercentage,
    price,
  };
}

function applyQuery(products, query) {
  let result = [...products];
  const search = (query.search || '').trim().toLowerCase();
  if (search) {
    result = result.filter((product) => {
      const text = `${product.name} ${product.category} ${product.subcategory} ${product.color} ${product.material}`.toLowerCase();
      return text.includes(search);
    });
  }
  if (query.category) result = result.filter((product) => product.category === query.category);
  if (query.subcategory) result = result.filter((product) => product.subcategory === query.subcategory);
  if (query.minPrice) result = result.filter((product) => product.price >= Number(query.minPrice));
  if (query.maxPrice) result = result.filter((product) => product.price <= Number(query.maxPrice));
  switch (query.sort) {
    case 'price_asc':
      result.sort((a, b) => a.price - b.price);
      break;
    case 'price_desc':
      result.sort((a, b) => b.price - a.price);
      break;
    case 'rating':
      result.sort((a, b) => b.rating - a.rating);
      break;
    case 'newest':
      result.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      break;
    default:
      result.sort((a, b) => Number(b.isBestSeller) - Number(a.isBestSeller) || Number(b.isTrending) - Number(a.isTrending));
  }
  return result;
}

async function getAllProducts(query = {}) {
  const dailyOffers = await getDailyOffers();
  if (!isFirebaseConfigured) {
    const mapped = store.products.map((p) => applyDynamicPrice(p, dailyOffers));
    return applyQuery(mapped, query);
  }
  const snapshot = await db.collection('products').get();
  const mapped = snapshot.docs.map((doc) => applyDynamicPrice(doc.data(), dailyOffers));
  return applyQuery(mapped, query);
}

async function getProductById(productId) {
  const dailyOffers = await getDailyOffers();
  if (!isFirebaseConfigured) {
    const found = store.products.find((product) => product.productId === productId) || null;
    return found ? applyDynamicPrice(found, dailyOffers) : null;
  }
  const doc = await db.collection('products').doc(productId).get();
  return doc.exists ? applyDynamicPrice(doc.data(), dailyOffers) : null;
}

async function createProduct(payload) {
  const product = normalizeProduct(payload);
  const index = store.products.findIndex((item) => item.productId === product.productId);
  if (index >= 0) {
    store.products[index] = product;
  } else {
    store.products.unshift(product);
  }
  const invIndex = store.inventory.findIndex((item) => item.productId === product.productId);
  if (invIndex >= 0) {
    store.inventory[invIndex].stock = product.stock;
    store.inventory[invIndex].lastRestockedAt = product.updatedAt;
  } else {
    store.inventory.push({
      productId: product.productId,
      stock: product.stock,
      lowStockThreshold: 5,
      lastRestockedAt: product.updatedAt,
    });
  }
  if (!isFirebaseConfigured) {
    const dailyOffers = await getDailyOffers();
    return applyDynamicPrice(product, dailyOffers);
  }
  await db.collection('products').doc(product.productId).set(product);
  await db.collection('inventory').doc(product.productId).set({
    productId: product.productId,
    stock: product.stock,
    lowStockThreshold: 5,
    lastRestockedAt: product.updatedAt,
  });
  const dailyOffers = await getDailyOffers();
  return applyDynamicPrice(product, dailyOffers);
}

async function updateProduct(productId, payload) {
  const product = await getProductById(productId);
  if (!product) return null;
  const updated = normalizeProduct({ ...payload, productId }, product);
  const index = store.products.findIndex((item) => item.productId === productId);
  if (index >= 0) {
    store.products[index] = updated;
  } else {
    store.products.unshift(updated);
  }
  const invIndex = store.inventory.findIndex((item) => item.productId === productId);
  if (invIndex >= 0) {
    store.inventory[invIndex].stock = updated.stock;
    store.inventory[invIndex].lastRestockedAt = updated.updatedAt;
  } else {
    store.inventory.push({
      productId,
      stock: updated.stock,
      lowStockThreshold: 5,
      lastRestockedAt: updated.updatedAt,
    });
  }
  if (!isFirebaseConfigured) {
    const dailyOffers = await getDailyOffers();
    return applyDynamicPrice(updated, dailyOffers);
  }
  await db.collection('products').doc(productId).set(updated, { merge: true });
  await db.collection('inventory').doc(productId).set({
    productId,
    stock: updated.stock,
    lastRestockedAt: updated.updatedAt,
  }, { merge: true });
  const dailyOffers = await getDailyOffers();
  return applyDynamicPrice(updated, dailyOffers);
}

async function deleteProduct(productId) {
  const before = store.products.length;
  store.products = store.products.filter((product) => product.productId !== productId);
  if (!isFirebaseConfigured) {
    return before !== store.products.length;
  }
  await db.collection('products').doc(productId).delete();
  return true;
}

module.exports = { getAllProducts, getProductById, createProduct, updateProduct, deleteProduct, getDailyOffers };
