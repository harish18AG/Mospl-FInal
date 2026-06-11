require('dotenv').config();

const { db, isFirebaseConfigured } = require('../config/firebase');
const { buildBanners, buildCategories, buildCoupons, buildProducts } = require('./productSeed');

async function commitInChunks(items, writeItem, chunkSize = 400) {
  for (let index = 0; index < items.length; index += chunkSize) {
    const batch = db.batch();
    items.slice(index, index + chunkSize).forEach((item) => writeItem(batch, item));
    await batch.commit();
  }
}

async function deleteMatching(collectionName, predicate) {
  const snapshot = await db.collection(collectionName).get();
  const refs = snapshot.docs.filter(predicate).map((doc) => doc.ref);
  await commitInChunks(refs, (batch, ref) => batch.delete(ref));
  return refs.length;
}

async function deleteDocsById(collectionName, ids) {
  const refs = ids.map((id) => db.collection(collectionName).doc(id));
  await commitInChunks(refs, (batch, ref) => batch.delete(ref));
  return refs.length;
}

async function main() {
  const products = buildProducts();
  const categories = buildCategories(products);
  const coupons = buildCoupons();
  const banners = buildBanners();
  const inventory = products.map((product) => ({
    productId: product.productId,
    stock: product.stock,
    lowStockThreshold: 15,
    lastRestockedAt: product.updatedAt,
  }));

  if (!isFirebaseConfigured || !db) {
    console.log('Firebase Admin is not configured. Seed preview only.');
    console.log(JSON.stringify({ products: products.length, categories: categories.length, coupons: coupons.length, banners: banners.length }, null, 2));
    return;
  }

  const removedProducts = await deleteMatching('products', (doc) => /^MOSPL-\d{4}$/.test(doc.id));
  const removedInventory = await deleteMatching('inventory', (doc) => /^MOSPL-\d{4}$/.test(doc.id));
  await deleteDocsById('categories', ['leather-accessories', 'gift-collections']);
  await deleteDocsById('coupons', ['LEATHER100', 'FIRSTBUY']);
  await deleteDocsById('banners', ['banner-gift']);

  await commitInChunks(products, (batch, product) => {
    batch.set(db.collection('products').doc(product.productId), product);
  });
  await commitInChunks(categories, (batch, category) => {
    batch.set(db.collection('categories').doc(category.categoryId), category);
  });
  await commitInChunks(coupons, (batch, coupon) => {
    batch.set(db.collection('coupons').doc(coupon.code), coupon);
  });
  await commitInChunks(banners, (batch, banner) => {
    batch.set(db.collection('banners').doc(banner.bannerId), banner);
  });
  await commitInChunks(inventory, (batch, item) => {
    batch.set(db.collection('inventory').doc(item.productId), item);
  });

  await db.collection('admins').doc('dev-admin').set({
    uid: 'dev-admin',
    email: 'admin@mospl.test',
    permissions: ['products', 'orders', 'analytics', 'notifications'],
    active: true,
    createdAt: new Date().toISOString(),
  });

  console.log(
    `Seeded ${products.length} MOSPL products, ${categories.length} categories, ${coupons.length} coupons, and ${banners.length} banners. Removed ${removedProducts} old generated products and ${removedInventory} old inventory rows.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
