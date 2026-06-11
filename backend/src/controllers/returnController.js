const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = req.user.role === 'admin'
      ? await db.collection('returns').get()
      : await db.collection('returns').where('userId', '==', req.user.uid).get();
    const returns = snapshot.docs
      .map((doc) => ({ returnId: doc.id, ...doc.data() }))
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    res.json({ ok: true, returns });
    return;
  }
  const returns = req.user.role === 'admin'
    ? store.returns
    : store.returns.filter((item) => item.userId === req.user.uid);
  res.json({ ok: true, returns });
});

const create = asyncHandler(async (req, res) => {
  const order = isFirebaseConfigured && db
    ? (await db.collection('orders').doc(req.body.orderId).get()).data()
    : store.orders.find((item) => item.orderId === req.body.orderId);
  if (!order) throw httpError(404, 'Order not found.');
  if (isFirebaseConfigured && db && order.userId !== req.user.uid && req.user.role !== 'admin') {
    throw httpError(403, 'Not allowed to return this order.');
  }
  if (isFirebaseConfigured && db) {
    const ref = db.collection('returns').doc();
    const returnRequest = {
      returnId: ref.id,
      orderId: req.body.orderId,
      userId: req.user.uid,
      reason: req.body.reason,
      status: 'Requested',
      createdAt: new Date().toISOString(),
    };
    await ref.set(returnRequest);
    res.status(201).json({ ok: true, returnRequest });
    return;
  }
  const returnRequest = {
    returnId: `RET-${Date.now()}`,
    orderId: req.body.orderId,
    userId: req.user.uid,
    reason: req.body.reason,
    status: 'Requested',
    createdAt: new Date().toISOString(),
  };
  store.returns.unshift(returnRequest);
  res.status(201).json({ ok: true, returnRequest });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('returns').doc(req.params.returnId);
    const doc = await ref.get();
    if (!doc.exists) throw httpError(404, 'Return request not found.');
    await ref.set({
      status: req.body.status || doc.data().status,
      updatedAt: new Date().toISOString(),
    }, { merge: true });
    const updated = await ref.get();
    res.json({ ok: true, returnRequest: { returnId: updated.id, ...updated.data() } });
    return;
  }
  const returnRequest = store.returns.find((item) => item.returnId === req.params.returnId);
  if (!returnRequest) throw httpError(404, 'Return request not found.');
  returnRequest.status = req.body.status || returnRequest.status;
  returnRequest.updatedAt = new Date().toISOString();
  res.json({ ok: true, returnRequest });
});

module.exports = { list, create, update };
