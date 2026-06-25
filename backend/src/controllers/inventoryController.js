const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('inventory').get();
    let inventory = snapshot.docs.map((doc) => ({ productId: doc.id, ...doc.data() }));
    if (req.query.lowStock === 'true') {
      inventory = inventory.filter((item) => Number(item.stock || 0) <= Number(item.lowStockThreshold || 5));
    }
    res.json({ ok: true, inventory });
    return;
  }
  const lowOnly = req.query.lowStock === 'true';
  const inventory = lowOnly
    ? store.inventory.filter((item) => item.stock <= item.lowStockThreshold)
    : store.inventory;
  res.json({ ok: true, inventory });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('inventory').doc(req.params.productId);
    const existing = await ref.get();
    const existingData = existing.exists ? existing.data() : {};
    let stockVal = Number(req.body.stock !== undefined ? req.body.stock : (existingData.stock ?? 0));
    stockVal = Math.min(30, Math.max(0, stockVal));
    const inventory = {
      productId: req.params.productId,
      stock: stockVal,
      lowStockThreshold: Number(req.body.lowStockThreshold !== undefined ? req.body.lowStockThreshold : (existingData.lowStockThreshold ?? 5)),
      lastRestockedAt: new Date().toISOString(),
    };
    await ref.set(inventory, { merge: true });
    await db.collection('products').doc(req.params.productId).set({
      stock: inventory.stock,
      updatedAt: inventory.lastRestockedAt,
    }, { merge: true });
    res.json({ ok: true, inventory });
    return;
  }
  let item = store.inventory.find((entry) => entry.productId === req.params.productId);
  if (!item) {
    item = {
      productId: req.params.productId,
      stock: 0,
      lowStockThreshold: 5,
      lastRestockedAt: new Date().toISOString(),
    };
    store.inventory.push(item);
  }
  let stockVal = Number(req.body.stock !== undefined ? req.body.stock : item.stock);
  stockVal = Math.min(30, Math.max(0, stockVal));
  item.stock = stockVal;
  item.lowStockThreshold = Number(req.body.lowStockThreshold !== undefined ? req.body.lowStockThreshold : item.lowStockThreshold);
  item.lastRestockedAt = new Date().toISOString();
  const product = store.products.find((entry) => entry.productId === req.params.productId);
  if (product) product.stock = item.stock;
  res.json({ ok: true, inventory: item });
});

module.exports = { list, update };
