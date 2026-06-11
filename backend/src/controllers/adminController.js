const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

async function collectionData(name) {
  const snapshot = await db.collection(name).get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

const dashboard = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const [products, orders, users, inventory, payments] = await Promise.all([
      collectionData('products'),
      collectionData('orders'),
      collectionData('users'),
      collectionData('inventory'),
      collectionData('payments'),
    ]);
    const revenue = orders.reduce((sum, order) => sum + Number(order.total || 0), 0);
    const lowStock = inventory.length
      ? inventory.filter((item) => Number(item.stock || 0) < Number(item.lowStockThreshold || 15)).length
      : products.filter((product) => Number(product.stock || 0) < 15).length;
    res.json({
      ok: true,
      metrics: {
        revenue,
        products: products.length,
        orders: orders.length,
        users: users.length,
        lowStock,
        payments: payments.length,
      },
      recentOrders: orders.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0)).slice(0, 10),
      productPerformance: products
        .filter((product) => product.isBestSeller)
        .sort((a, b) => Number(b.reviewCount || 0) - Number(a.reviewCount || 0))
        .slice(0, 10),
    });
    return;
  }
  const revenue = store.orders.reduce((sum, order) => sum + Number(order.total || 0), 0);
  res.json({
    ok: true,
    metrics: {
      revenue,
      products: store.products.length,
      orders: store.orders.length,
      users: store.users.size,
      lowStock: store.inventory.filter((item) => item.stock < item.lowStockThreshold).length,
      payments: store.payments.length,
    },
    recentOrders: store.orders.slice(0, 10),
    productPerformance: store.products.filter((product) => product.isBestSeller).slice(0, 10),
  });
});

const users = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const users = await collectionData('users');
    res.json({ ok: true, users });
    return;
  }
  res.json({ ok: true, users: [...store.users.values()].map(({ passwordHash, ...user }) => user) });
});

const analytics = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const [products, categories, orders, payments, inventory] = await Promise.all([
      collectionData('products'),
      collectionData('categories'),
      collectionData('orders'),
      collectionData('payments'),
      collectionData('inventory'),
    ]);
    const last7 = Array.from({ length: 7 }, (_, index) => {
      const date = new Date();
      date.setDate(date.getDate() - (6 - index));
      const key = date.toISOString().slice(0, 10);
      return orders
        .filter((order) => String(order.createdAt || '').slice(0, 10) === key)
        .reduce((sum, order) => sum + Number(order.total || 0), 0);
    });
    const categoryNames = categories.length ? categories.map((category) => category.name) : [...new Set(products.map((product) => product.category))];
    res.json({
      ok: true,
      revenueByDay: last7,
      salesByCategory: categoryNames.map((category) => ({
        category,
        sales: products.filter((product) => product.category === category).length,
      })),
      payments,
      inventoryAlerts: inventory.filter((item) => Number(item.stock || 0) < Number(item.lowStockThreshold || 15)),
    });
    return;
  }
  res.json({
    ok: true,
    revenueByDay: [1200, 2200, 3100, 2600, 4200, 5100, 4800],
    salesByCategory: store.categories.map((category) => ({
      category: category.name,
      sales: store.products.filter((product) => product.category === category.name).length,
    })),
    payments: store.payments,
    inventoryAlerts: store.inventory.filter((item) => item.stock < item.lowStockThreshold),
  });
});

module.exports = { dashboard, users, analytics };
