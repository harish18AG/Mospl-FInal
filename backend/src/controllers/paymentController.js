const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const paymentService = require('../services/paymentService');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

const createOrder = asyncHandler(async (req, res) => {
  const razorpayOrder = await paymentService.createPaymentOrder({
    amount: req.body.amount,
    receipt: req.body.receipt || `mospl_${Date.now()}`,
  });
  res.status(201).json({ ok: true, razorpayOrder, keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_1234567890abcdef' });
});

const verifyPayment = asyncHandler(async (req, res) => {
  const valid = paymentService.verifyPaymentSignature(req.body);
  if (!valid) throw httpError(400, 'Invalid Razorpay signature.');
  const payment = paymentService.recordPayment({ ...req.body, status: 'paid' });
  payment.userId = req.user.uid;
  if (isFirebaseConfigured && db) {
    const ref = db.collection('payments').doc(payment.paymentId);
    await ref.set(payment, { merge: true });
    if (payment.orderId) {
      await db.collection('orders').doc(payment.orderId).set({
        paymentStatus: 'Paid',
        razorpayOrderId: payment.razorpayOrderId,
        razorpayPaymentId: payment.razorpayPaymentId,
        updatedAt: new Date().toISOString(),
      }, { merge: true });
    }
  }
  res.json({ ok: true, payment });
});

const paymentHistory = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = req.user.role === 'admin'
      ? await db.collection('payments').get()
      : await db.collection('payments').where('userId', '==', req.user.uid).get();
    const payments = snapshot.docs
      .map((doc) => ({ paymentId: doc.id, ...doc.data() }))
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    res.json({ ok: true, payments });
    return;
  }
  const payments = req.user.role === 'admin' ? store.payments : store.payments.filter((payment) => payment.userId === req.user.uid);
  res.json({ ok: true, payments });
});

const retryPayment = asyncHandler(async (req, res) => {
  const order = isFirebaseConfigured && db
    ? (await db.collection('orders').doc(req.params.orderId).get()).data()
    : store.orders.find((item) => item.orderId === req.params.orderId);
  if (!order) throw httpError(404, 'Order not found.');
  const razorpayOrder = await paymentService.createPaymentOrder({ amount: order.total, receipt: order.orderId });
  res.json({ ok: true, razorpayOrder });
});

module.exports = { createOrder, verifyPayment, paymentHistory, retryPayment };
