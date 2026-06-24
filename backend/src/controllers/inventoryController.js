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
    if (!existing.exists) throw httpError(404, 'Inventory record not found.');
    const inventory = {
      productId: req.params.productId,
      stock: Number(req.body.stock ?? existing.data().stock),
      lowStockThreshold: Number(req.body.lowStockThreshold ?? existing.data().lowStockThreshold ?? 5),
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
  const item = store.inventory.find((entry) => entry.productId === req.params.productId);
  if (!item) throw httpError(404, 'Inventory record not found.');
  item.stock = Number(req.body.stock ?? item.stock);
  item.lowStockThreshold = Number(req.body.lowStockThreshold ?? item.lowStockThreshold);
  item.lastRestockedAt = new Date().toISOString();
  const product = store.products.find((entry) => entry.productId === req.params.productId);
  if (product) product.stock = item.stock;
  res.json({ ok: true, inventory: item });
});

module.exports = { list, update };
