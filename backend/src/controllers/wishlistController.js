const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const productService = require('../services/productService');
const store = require('../services/store');

function getWishlist(userId) {
  if (!store.wishlists.has(userId)) store.wishlists.set(userId, new Set());
  return store.wishlists.get(userId);
}

async function getFirestoreWishlist(userId) {
  const doc = await db.collection('wishlists').doc(userId).get();
  return doc.exists ? doc.data().productIds || [] : [];
}

async function saveFirestoreWishlist(userId, productIds) {
  await db.collection('wishlists').doc(userId).set({
    userId,
    productIds,
    updatedAt: new Date().toISOString(),
  }, { merge: true });
  return productIds;
}

const getWishlistProducts = asyncHandler(async (req, res) => {
  const ids = isFirebaseConfigured && db ? await getFirestoreWishlist(req.user.uid) : [...getWishlist(req.user.uid)];
  const products = isFirebaseConfigured && db
    ? (await productService.getAllProducts({})).filter((product) => ids.includes(product.productId))
    : store.products.filter((product) => ids.includes(product.productId));
  res.json({ ok: true, productIds: ids, products });
});

const addWishlistProduct = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ids = new Set(await getFirestoreWishlist(req.user.uid));
    ids.add(req.params.productId);
    res.status(201).json({ ok: true, productIds: await saveFirestoreWishlist(req.user.uid, [...ids]) });
    return;
  }
  getWishlist(req.user.uid).add(req.params.productId);
  res.status(201).json({ ok: true, productIds: [...getWishlist(req.user.uid)] });
});

const removeWishlistProduct = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ids = (await getFirestoreWishlist(req.user.uid)).filter((id) => id !== req.params.productId);
    res.json({ ok: true, productIds: await saveFirestoreWishlist(req.user.uid, ids) });
    return;
  }
  getWishlist(req.user.uid).delete(req.params.productId);
  res.json({ ok: true, productIds: [...getWishlist(req.user.uid)] });
});

module.exports = { getWishlistProducts, addWishlistProduct, removeWishlistProduct };
