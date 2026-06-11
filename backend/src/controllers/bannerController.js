const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('banners').get();
    const banners = snapshot.docs
      .map((doc) => ({ bannerId: doc.id, ...doc.data() }))
      .filter((banner) => banner.isActive !== false);
    res.json({ ok: true, banners });
    return;
  }
  res.json({ ok: true, banners: store.banners.filter((banner) => banner.isActive !== false) });
});

const create = asyncHandler(async (req, res) => {
  const banner = {
    bannerId: req.body.bannerId || `BANNER-${Date.now()}`,
    title: req.body.title,
    subtitle: req.body.subtitle,
    imageUrl: req.body.imageUrl,
    isActive: req.body.isActive !== false,
    createdAt: new Date().toISOString(),
  };
  if (isFirebaseConfigured && db) {
    await db.collection('banners').doc(banner.bannerId).set(banner, { merge: true });
    res.status(201).json({ ok: true, banner });
    return;
  }
  store.banners.unshift(banner);
  res.status(201).json({ ok: true, banner });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('banners').doc(req.params.bannerId);
    await ref.set({ ...req.body, updatedAt: new Date().toISOString() }, { merge: true });
    const doc = await ref.get();
    res.json({ ok: true, banner: { bannerId: doc.id, ...doc.data() } });
    return;
  }
  const banner = store.banners.find((item) => item.bannerId === req.params.bannerId);
  if (banner) Object.assign(banner, req.body, { updatedAt: new Date().toISOString() });
  res.json({ ok: true, banner });
});

module.exports = { list, create, update };
