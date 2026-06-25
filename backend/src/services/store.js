const bcrypt = require('bcryptjs');

const { buildBanners, buildCategories, buildCoupons, buildProducts } = require('../seed/productSeed');

const products = buildProducts();
const categories = buildCategories(products);
const coupons = buildCoupons();
const banners = buildBanners();

const store = {
  users: new Map(),
  admins: new Map(),
  products,
  categories,
  dailyOffers: {
    monday: 10,
    tuesday: 15,
    wednesday: 20,
    thursday: 25,
    friday: 30,
    saturday: 35,
    sunday: 40
  },
  carts: new Map(),
  wishlists: new Map(),
  orders: [],
  orderItems: [],
  addresses: new Map(),
  payments: [],
  reviews: [],
  notifications: [],
  chatbotMessages: [],
  coupons,
  banners,
  inventory: products.map((product) => ({
    productId: product.productId,
    stock: product.stock,
    lowStockThreshold: 5,
    lastRestockedAt: product.updatedAt,
  })),
  returns: [],
  supportTickets: [],
};

function seedDevUsers() {
  const admin = {
    uid: 'dev-admin',
    email: 'admin@mospl.test',
    name: 'MOSPL Admin',
    role: 'admin',
    passwordHash: bcrypt.hashSync('password123', 10),
    createdAt: new Date().toISOString(),
  };
  const user = {
    uid: 'dev-user',
    email: 'shopper@mospl.test',
    name: 'MOSPL Shopper',
    role: 'customer',
    passwordHash: bcrypt.hashSync('password123', 10),
    createdAt: new Date().toISOString(),
  };
  store.users.set(admin.email, admin);
  store.users.set(user.email, user);
  store.admins.set(admin.uid, { uid: admin.uid, email: admin.email, permissions: ['products', 'orders', 'analytics'], active: true });
}

seedDevUsers();

module.exports = store;
