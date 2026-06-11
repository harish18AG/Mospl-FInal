const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('coupons').get();
    const coupons = snapshot.docs
      .map((doc) => ({ code: doc.id, ...doc.data() }))
      .filter((coupon) => coupon.isActive !== false);
    res.json({ ok: true, coupons });
    return;
  }
  res.json({ ok: true, coupons: store.coupons.filter((coupon) => coupon.isActive !== false) });
});

const create = asyncHandler(async (req, res) => {
  const coupon = { ...req.body, isActive: req.body.isActive !== false, createdAt: new Date().toISOString() };
  if (isFirebaseConfigured && db) {
    await db.collection('coupons').doc(coupon.code).set(coupon, { merge: true });
    res.status(201).json({ ok: true, coupon });
    return;
  }
  store.coupons.unshift(coupon);
  res.status(201).json({ ok: true, coupon });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('coupons').doc(req.params.code);
    await ref.set({ ...req.body, updatedAt: new Date().toISOString() }, { merge: true });
    const doc = await ref.get();
    res.json({ ok: true, coupon: { code: doc.id, ...doc.data() } });
    return;
  }
  const coupon = store.coupons.find((item) => item.code === req.params.code);
  if (coupon) Object.assign(coupon, req.body, { updatedAt: new Date().toISOString() });
  res.json({ ok: true, coupon });
});

module.exports = { list, create, update };
