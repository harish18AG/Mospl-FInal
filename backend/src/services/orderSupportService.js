/**
 * Order Support Service
 * Fetches order tracking, status, and history locally from Firestore or store.
 */

const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('./store');

/**
 * Handles user query about order support (tracking, history, status).
 * 
 * @param {Object} params
 * @param {string} params.userId User ID
 * @param {string} params.text User message
 * @returns {Promise<Object>} { text: string, recommendedProductIds: Array<string> }
 */
async function handleOrderSupport({ userId, text }) {
  const clean = String(text || '').toLowerCase();
  
  // 1. Fetch user orders
  let orders = [];
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('orders')
      .where('userId', '==', userId)
      .get();
    orders = snapshot.docs.map(doc => ({ orderId: doc.id, ...doc.data() }));
  } else {
    orders = store.orders.filter(order => order.userId === userId);
  }

  // Sort orders newest first
  orders.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));

  if (orders.length === 0) {
    return {
      text: "You haven't placed any orders with MOSPL yet. Browse our premium leather catalog to place your first order!",
      recommendedProductIds: []
    };
  }

  // 2. Check if a specific order ID is requested
  const orderIdMatch = clean.match(/ord-[a-z0-9-]+/i);
  if (orderIdMatch) {
    const targetOrderId = orderIdMatch[0].toUpperCase();
    const order = orders.find(o => o.orderId.toUpperCase() === targetOrderId);
    if (order) {
      const itemsCount = order.items ? order.items.reduce((sum, i) => sum + i.quantity, 0) : 0;
      const formattedDate = new Date(order.createdAt).toLocaleDateString();
      return {
        text: `Order ${order.orderId} status:
- Status: ${order.status}
- Payment Status: ${order.paymentStatus}
- Order Date: ${formattedDate}
- Total: ₹${order.total} (${itemsCount} items)
- Delivery Info: Delivered within 5 days with Free Shipping.

You can view full details in the 'My Orders' section of your profile.`,
        recommendedProductIds: []
      };
    } else {
      return {
        text: `I couldn't find an order with ID ${targetOrderId} in your account. Please check your order history or double-check the ID.`,
        recommendedProductIds: []
      };
    }
  }

  // 3. Check if user is asking for full order history
  if (clean.includes('history') || clean.includes('all') || clean.includes('list')) {
    let historyText = "Here is your order history:\n";
    // Show up to 5 recent orders
    orders.slice(0, 5).forEach(o => {
      const formattedDate = new Date(o.createdAt).toLocaleDateString();
      historyText += `- Order ${o.orderId} | Status: ${o.status} | Date: ${formattedDate} | Total: ₹${o.total}\n`;
    });
    if (orders.length > 5) {
      historyText += `\nGo to the 'My Orders' page in the app to view all of your ${orders.length} orders.`;
    }
    return {
      text: historyText,
      recommendedProductIds: []
    };
  }

  // 4. Default: Show status of the most recent order
  const recentOrder = orders[0];
  const itemsCount = recentOrder.items ? recentOrder.items.reduce((sum, i) => sum + i.quantity, 0) : 0;
  const formattedDate = new Date(recentOrder.createdAt).toLocaleDateString();
  return {
    text: `Here is the status of your most recent order (${recentOrder.orderId}):
- Status: ${recentOrder.status}
- Payment Status: ${recentOrder.paymentStatus}
- Order Date: ${formattedDate}
- Total: ₹${recentOrder.total} (${itemsCount} items)

You can track all order details directly in 'My Orders' under your profile.`,
    recommendedProductIds: []
  };
}

module.exports = { handleOrderSupport };
