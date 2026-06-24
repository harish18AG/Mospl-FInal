const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const productService = require('../services/productService');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

function getCart(userId) {
  if (!store.carts.has(userId)) store.carts.set(userId, []);
  return store.carts.get(userId);
}

async function getFirestoreCart(userId) {
  const doc = await db.collection('carts').doc(userId).get();
  return doc.exists ? doc.data().items || [] : [];
}

async function saveFirestoreCart(userId, items) {
  await db.collection('carts').doc(userId).set({
    userId,
    items,
    updatedAt: new Date().toISOString(),
  }, { merge: true });
  return items;
}

const getMyCart = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    res.json({ ok: true, items: await getFirestoreCart(req.user.uid) });
    return;
  }
  res.json({ ok: true, items: getCart(req.user.uid) });
});

const addItem = asyncHandler(async (req, res) => {
  const product = isFirebaseConfigured && db
    ? await productService.getProductById(req.body.productId)
    : store.products.find((item) => item.productId === req.body.productId);
  if (!product) throw httpError(404, 'Product not found.');
  const cart = isFirebaseConfigured && db ? await getFirestoreCart(req.user.uid) : getCart(req.user.uid);
  const existing = cart.find((item) => item.productId === product.productId);

  const currentQuantity = existing ? existing.quantity : 0;
  const requestedQuantity = Number(req.body.quantity || 1);
  const targetQuantity = currentQuantity + requestedQuantity;

  if (targetQuantity > product.stock) {
    throw httpError(400, `Cannot add more. Only ${product.stock} items are available in stock.`);
  }

  if (existing) existing.quantity = targetQuantity;
  else cart.push({ productId: product.productId, quantity: targetQuantity, price: product.price, product });
  if (isFirebaseConfigured && db) {
    await saveFirestoreCart(req.user.uid, cart);
  }
  res.status(201).json({ ok: true, items: cart });
});

const updateItem = asyncHandler(async (req, res) => {
  const cart = isFirebaseConfigured && db ? await getFirestoreCart(req.user.uid) : getCart(req.user.uid);
  const item = cart.find((line) => line.productId === req.params.productId);
  if (!item) throw httpError(404, 'Cart item not found.');

  const product = isFirebaseConfigured && db
    ? await productService.getProductById(req.params.productId)
    : store.products.find((p) => p.productId === req.params.productId);
  if (!product) throw httpError(404, 'Product not found.');

  const requestedQuantity = Number(req.body.quantity || item.quantity);
  if (requestedQuantity > product.stock) {
    throw httpError(400, `Cannot update quantity. Only ${product.stock} items are available in stock.`);
  }

  item.quantity = requestedQuantity;
  const updated = cart.filter((line) => line.quantity > 0);
  if (isFirebaseConfigured && db) await saveFirestoreCart(req.user.uid, updated);
  res.json({ ok: true, items: updated });
});

const removeItem = asyncHandler(async (req, res) => {
  const current = isFirebaseConfigured && db ? await getFirestoreCart(req.user.uid) : getCart(req.user.uid);
  const cart = current.filter((item) => item.productId !== req.params.productId);
  if (isFirebaseConfigured && db) await saveFirestoreCart(req.user.uid, cart);
  else store.carts.set(req.user.uid, cart);
  res.json({ ok: true, items: cart });
});

const clearCart = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) await saveFirestoreCart(req.user.uid, []);
  else store.carts.set(req.user.uid, []);
  res.json({ ok: true, items: [] });
});

module.exports = { getMyCart, addItem, updateItem, removeItem, clearCart };
