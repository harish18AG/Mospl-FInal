const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured, admin } = require('../config/firebase');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

function nowIso() {
  return new Date().toISOString();
}

function createReadableOrderId() {
  return `ORD-${Date.now()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
}

function normalizeItems(items) {
  return (items || []).map((item) => {
    const quantity = Number(item.quantity || 1);
    const price = Number(item.price || item.product?.price || 0);
    return {
      productId: (item.productId || item.product?.productId || '').toString(),
      name: (item.name || item.product?.name || 'Not Specified').toString(),
      sku: (item.sku || item.product?.sku || 'Not Specified').toString(),
      thumbnail: (item.thumbnail || item.product?.thumbnail || '').toString(),
      color: (item.color || item.product?.color || 'Not Specified').toString(),
      size: (item.size || item.product?.size || 'Not Specified').toString(),
      quantity,
      price,
      subtotal: price * quantity,
    };
  });
}

function sortNewestFirst(orders) {
  return orders.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
}

async function getFirestoreOrders(user) {
  const collection = db.collection('orders');
  const snapshot = user.role === 'admin'
    ? await collection.get()
    : await collection.where('userId', '==', user.uid).get();
  return sortNewestFirst(snapshot.docs.map((doc) => ({ orderId: doc.id, ...doc.data() })));
}

async function getFirestoreOrder(orderId) {
  const doc = await db.collection('orders').doc(orderId).get();
  if (!doc.exists) return null;
  return { orderId: doc.id, ...doc.data() };
}

async function saveFirestoreOrder(req, items) {
  const address = req.body.address && typeof req.body.address === 'object' ? req.body.address : null;
  if (!address) throw httpError(400, 'Delivery address is required.');
  const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryFee = Number(req.body.deliveryFee || 0);
  const discount = Number(req.body.discount || 0);
  const total = Number(req.body.total || (subtotal + deliveryFee - discount));
  const orderId = (req.body.orderId || createReadableOrderId()).toString();
  const timestamp = nowIso();
  const order = {
    orderId,
    userId: req.user.uid,
    customerEmail: req.user.email,
    items,
    address,
    addressId: address.addressId || address.id || null,
    status: req.body.status || 'Confirmed',
    paymentStatus: req.body.paymentStatus || 'Pending',
    paymentMethod: req.body.paymentMethod || 'Razorpay',
    subtotal,
    deliveryFee,
    discount,
    total,
    razorpayOrderId: req.body.razorpayOrderId || null,
    razorpayPaymentId: req.body.razorpayPaymentId || null,
    createdAt: timestamp,
    updatedAt: timestamp,
  };

  const orderRef = db.collection('orders').doc(orderId);

  // Fetch current stock for each item to clamp decrement at 0
  const stockSnapshots = await Promise.all(
    items.map((item) => db.collection('products').doc(item.productId).get())
  );
  const currentStocks = {};
  stockSnapshots.forEach((snap) => {
    if (snap.exists) {
      const data = snap.data();
      currentStocks[data.productId] = Math.max(0, Number(data.stock ?? 0));
    }
  });

  const batch = db.batch();
  batch.set(orderRef, order);
  items.forEach((item, index) => {
    const orderItemId = `${orderId}-${index + 1}`;
    batch.set(db.collection('order_items').doc(orderItemId), {
      orderItemId,
      orderId,
      userId: req.user.uid,
      ...item,
      createdAt: timestamp,
    });

    // Decrement stock but never go below 0
    const currentStock = currentStocks[item.productId] ?? 0;
    const newStock = Math.max(0, currentStock - Number(item.quantity));
    batch.set(db.collection('products').doc(item.productId), {
      stock: newStock,
      updatedAt: timestamp,
    }, { merge: true });

    batch.set(db.collection('inventory').doc(item.productId), {
      stock: newStock,
    }, { merge: true });
  });
  batch.set(db.collection('carts').doc(req.user.uid), { userId: req.user.uid, items: [], updatedAt: timestamp }, { merge: true });
  await batch.commit();
  return order;
}

const getOrders = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const orders = await getFirestoreOrders(req.user);
    res.json({ ok: true, count: orders.length, orders });
    return;
  }
  const orders = req.user.role === 'admin' ? store.orders : store.orders.filter((order) => order.userId === req.user.uid);
  res.json({ ok: true, count: orders.length, orders });
});

const createOrder = asyncHandler(async (req, res) => {
  const cart = store.carts.get(req.user.uid) || [];
  const items = normalizeItems(req.body.items || cart);
  if (!items.length) throw httpError(400, 'Order requires at least one item.');

  if (isFirebaseConfigured && db) {
    const order = await saveFirestoreOrder(req, items);
    res.status(201).json({ ok: true, order });
    return;
  }

  const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryFee = Number(req.body.deliveryFee || 0);
  const discount = Number(req.body.discount || 0);
  const total = Number(req.body.total || (subtotal + deliveryFee - discount));
  const order = {
    orderId: createReadableOrderId(),
    userId: req.user.uid,
    customerEmail: req.user.email,
    items,
    address: req.body.address,
    addressId: req.body.address?.addressId || req.body.address?.id || null,
    status: 'Confirmed',
    paymentStatus: 'Pending',
    paymentMethod: req.body.paymentMethod || 'Razorpay',
    subtotal,
    deliveryFee,
    discount,
    total,
    razorpayOrderId: req.body.razorpayOrderId || null,
    razorpayPaymentId: req.body.razorpayPaymentId || null,
    createdAt: nowIso(),
  };
  store.orders.unshift(order);
  store.orderItems.push(...items.map((item, index) => ({ orderItemId: `${order.orderId}-${index}`, orderId: order.orderId, ...item })));
  store.carts.set(req.user.uid, []);

  // Decrement stock in-memory fallback
  items.forEach((item) => {
    const prod = store.products.find((p) => p.productId === item.productId);
    if (prod) {
      prod.stock = Math.max(0, prod.stock - item.quantity);
    }
    const inv = store.inventory.find((i) => i.productId === item.productId);
    if (inv) {
      inv.stock = Math.max(0, inv.stock - item.quantity);
    }
  });

  res.status(201).json({ ok: true, order });
});

const getOrder = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const order = await getFirestoreOrder(req.params.orderId);
    if (!order) throw httpError(404, 'Order not found.');
    if (req.user.role !== 'admin' && order.userId !== req.user.uid) throw httpError(403, 'Not allowed to view this order.');
    res.json({ ok: true, order });
    return;
  }
  const order = store.orders.find((item) => item.orderId === req.params.orderId);
  if (!order) throw httpError(404, 'Order not found.');
  if (req.user.role !== 'admin' && order.userId !== req.user.uid) throw httpError(403, 'Not allowed to view this order.');
  res.json({ ok: true, order });
});

const updateOrderStatus = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('orders').doc(req.params.orderId);
    const existing = await ref.get();
    if (!existing.exists) throw httpError(404, 'Order not found.');
    const changes = {
      status: req.body.status || existing.data().status,
      paymentStatus: req.body.paymentStatus || existing.data().paymentStatus,
      updatedAt: nowIso(),
    };
    await ref.set(changes, { merge: true });
    const updated = await ref.get();
    res.json({ ok: true, order: { orderId: updated.id, ...updated.data() } });
    return;
  }
  const order = store.orders.find((item) => item.orderId === req.params.orderId);
  if (!order) throw httpError(404, 'Order not found.');
  order.status = req.body.status || order.status;
  order.paymentStatus = req.body.paymentStatus || order.paymentStatus;
  order.updatedAt = new Date().toISOString();
  res.json({ ok: true, order });
});

module.exports = { getOrders, createOrder, getOrder, updateOrderStatus };
