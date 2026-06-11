const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

function getUserAddresses(userId) {
  if (!store.addresses.has(userId)) store.addresses.set(userId, []);
  return store.addresses.get(userId);
}

async function getFirestoreAddresses(userId) {
  const snapshot = await db.collection('addresses').where('userId', '==', userId).get();
  return snapshot.docs
    .map((doc) => doc.data())
    .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
}

async function clearDefaultAddress(userId) {
  const snapshot = await db.collection('addresses').where('userId', '==', userId).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.set(doc.ref, { isDefault: false, updatedAt: new Date().toISOString() }, { merge: true });
  });
  await batch.commit();
}

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const addresses = await getFirestoreAddresses(req.user.uid);
    res.json({ ok: true, addresses });
    return;
  }
  res.json({ ok: true, addresses: getUserAddresses(req.user.uid) });
});

const create = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const existing = await getFirestoreAddresses(req.user.uid);
    const isDefault = existing.length === 0 || req.body.isDefault !== false;
    if (isDefault) await clearDefaultAddress(req.user.uid);
    const doc = db.collection('addresses').doc();
    const now = new Date().toISOString();
    const address = {
      addressId: doc.id,
      userId: req.user.uid,
      name: req.body.name,
      phone: req.body.phone,
      line1: req.body.line1,
      line2: req.body.line2 || '',
      city: req.body.city,
      state: req.body.state,
      pincode: req.body.pincode,
      isDefault,
      createdAt: now,
      updatedAt: now,
    };
    await doc.set(address);
    res.status(201).json({ ok: true, address });
    return;
  }
  const addresses = getUserAddresses(req.user.uid);
  if (req.body.isDefault) addresses.forEach((address) => { address.isDefault = false; });
  const address = {
    addressId: `ADDR-${Date.now()}`,
    userId: req.user.uid,
    name: req.body.name,
    phone: req.body.phone,
    line1: req.body.line1,
    line2: req.body.line2 || '',
    city: req.body.city,
    state: req.body.state,
    pincode: req.body.pincode,
    isDefault: req.body.isDefault !== false,
    createdAt: new Date().toISOString(),
  };
  addresses.push(address);
  res.status(201).json({ ok: true, address });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('addresses').doc(req.params.addressId);
    const doc = await ref.get();
    if (!doc.exists || doc.data().userId !== req.user.uid) throw httpError(404, 'Address not found.');
    if (req.body.isDefault) await clearDefaultAddress(req.user.uid);
    await ref.set({ ...req.body, updatedAt: new Date().toISOString() }, { merge: true });
    const updated = await ref.get();
    res.json({ ok: true, address: updated.data() });
    return;
  }
  const addresses = getUserAddresses(req.user.uid);
  const address = addresses.find((item) => item.addressId === req.params.addressId);
  if (!address) throw httpError(404, 'Address not found.');
  Object.assign(address, req.body, { updatedAt: new Date().toISOString() });
  res.json({ ok: true, address });
});

const remove = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('addresses').doc(req.params.addressId);
    const doc = await ref.get();
    if (!doc.exists || doc.data().userId !== req.user.uid) throw httpError(404, 'Address not found.');
    await ref.delete();
    const addresses = await getFirestoreAddresses(req.user.uid);
    res.json({ ok: true, addresses });
    return;
  }
  const addresses = getUserAddresses(req.user.uid).filter((item) => item.addressId !== req.params.addressId);
  store.addresses.set(req.user.uid, addresses);
  res.json({ ok: true, addresses });
});

module.exports = { list, create, update, remove };
