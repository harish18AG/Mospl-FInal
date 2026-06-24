/**
 * Intent Classification Service
 * Detects user intent locally to route simple queries without invoking Gemini API.
 */

const INTENTS = {
  GEMINI: 'GEMINI',
  FAQ_RETURN: 'FAQ_RETURN',
  FAQ_SHIPPING: 'FAQ_SHIPPING',
  FAQ_REFUND: 'FAQ_REFUND',
  FAQ_DELIVERY_TIME: 'FAQ_DELIVERY_TIME',
  FAQ_CONTACT: 'FAQ_CONTACT',
  FAQ_STORE: 'FAQ_STORE',
  PRODUCT_SEARCH: 'PRODUCT_SEARCH',
  ORDER_SUPPORT: 'ORDER_SUPPORT'
};

/**
 * Classifies a user's message into an intent.
 * 
 * @param {string} text User query
 * @returns {string} One of INTENTS values
 */
function detectIntent(text) {
  const clean = String(text || '').trim().toLowerCase();

  // 1. GEMINI: Shopping advice, gifts, comparisons, reasoning, recommendations
  const geminiKeywords = [
    'suggest', 'recommend', 'gift', 'present', 'compare', 'comparison', 
    'opinion', 'advice', 'advisor', 'which is best', 'which one', 'which to buy',
    'what is best', 'what to buy', 'personalized', 'premium', 'luxury', 
    'choose', 'pick', 'suit', 'ideal', 'best', 'father', 'husband', 'wife', 
    'mother', 'brother', 'sister', 'friend', 'birthday', 'anniversary',
    'business travel', 'traveler', 'help me buy', 'help me choose'
  ];
  if (geminiKeywords.some(keyword => clean.includes(keyword))) {
    return INTENTS.GEMINI;
  }

  // 2. ORDER SUPPORT: Track order, order status, order history, delivery status
  // Note: Check order tracking before general shipping/delivery FAQs
  const orderKeywords = ['track', 'status', 'history', 'order', 'orders', 'package', 'ord-'];
  const hasOrderWord = orderKeywords.some(k => clean.includes(k));
  const hasWhereIsMy = clean.includes('where is my') || clean.includes('delivery status');
  if (hasOrderWord || hasWhereIsMy) {
    return INTENTS.ORDER_SUPPORT;
  }

  // 3. FAQ: Return policy
  if (clean.includes('return') || clean.includes('exchange') || clean.includes('replace') || clean.includes('policy') && clean.includes('return')) {
    return INTENTS.FAQ_RETURN;
  }

  // 4. FAQ: Refund policy
  if (clean.includes('refund') || clean.includes('money back') || clean.includes('reimbursement')) {
    return INTENTS.FAQ_REFUND;
  }

  // 5. FAQ: Shipping policy
  if (clean.includes('shipping') || clean.includes('shipment') || clean.includes('charge') || clean.includes('delivery charge')) {
    return INTENTS.FAQ_SHIPPING;
  }

  // 6. FAQ: Delivery time
  if (clean.includes('how long') || clean.includes('delivery time') || clean.includes('delivery speed') || clean.includes('arrive') || clean.includes('shipping time') || clean.includes('take to deliver')) {
    return INTENTS.FAQ_DELIVERY_TIME;
  }

  // 7. FAQ: Contact information
  const contactKeywords = ['contact', 'email', 'phone', 'support', 'help', 'number', 'call', 'helpline', 'reach'];
  if (contactKeywords.some(k => clean.includes(k))) {
    return INTENTS.FAQ_CONTACT;
  }

  // 8. FAQ: Store information
  const storeKeywords = ['about', 'store', 'location', 'address', 'where are you', 'who are you', 'mospl'];
  if (storeKeywords.some(k => clean.includes(k))) {
    return INTENTS.FAQ_STORE;
  }

  // 9. PRODUCT SEARCH: Wallets, belts, passport covers, categories, availability, pricing
  const productKeywords = [
    'wallet', 'wallets', 'belt', 'belts', 'passport', 'passports', 'cover', 'covers', 'holder', 'holders',
    'categories', 'category', 'subcategory', 'accessories', 'avail', 'availability', 'available',
    'pricing', 'price', 'prices', 'cost', 'how much', 'stock', 'in stock', 'sold out'
  ];
  if (productKeywords.some(k => clean.includes(k))) {
    return INTENTS.PRODUCT_SEARCH;
  }

  // 10. Fallback: Open conversational text goes to Gemini for intelligent assistance
  return INTENTS.GEMINI;
}

module.exports = { detectIntent, INTENTS };
