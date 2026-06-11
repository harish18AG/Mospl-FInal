const crypto = require('crypto');
const Razorpay = require('razorpay');

const store = require('./store');

function razorpayClient() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret || keyId.includes('replace')) return null;
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

async function createPaymentOrder({ amount, receipt }) {
  const client = razorpayClient();
  if (!client) {
    return {
      id: `order_test_${Date.now()}`,
      amount: Number(amount) * 100,
      currency: 'INR',
      receipt,
      status: 'created',
      mode: 'local-test',
    };
  }
  return client.orders.create({
    amount: Number(amount) * 100,
    currency: 'INR',
    receipt,
    payment_capture: 1,
  });
}

function verifyPaymentSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
  const secret = process.env.RAZORPAY_KEY_SECRET || 'local-test-secret';
  const body = `${razorpayOrderId}|${razorpayPaymentId}`;
  const expected = crypto.createHmac('sha256', secret).update(body).digest('hex');
  return expected === razorpaySignature || process.env.NODE_ENV === 'development';
}

function recordPayment(payload) {
  const payment = {
    paymentId: payload.razorpayPaymentId || `pay_local_${Date.now()}`,
    orderId: payload.orderId,
    razorpayOrderId: payload.razorpayOrderId,
    razorpayPaymentId: payload.razorpayPaymentId,
    status: payload.status || 'paid',
    amount: payload.amount,
    currency: 'INR',
    createdAt: new Date().toISOString(),
  };
  store.payments.unshift(payment);
  return payment;
}

module.exports = { createPaymentOrder, verifyPaymentSignature, recordPayment };
