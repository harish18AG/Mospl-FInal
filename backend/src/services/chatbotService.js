const store = require('./store');

function replyToMessage({ userId, text }) {
  const clean = String(text || '').toLowerCase();
  let response = 'Tell me what you are shopping for: men wallet, coat wallet, hand woven belt, passport holder, or women wallet.';
  if (clean.includes('order') || clean.includes('track')) {
    response = 'Open My Orders to view confirmation, payment status, and delivery tracking.';
  } else if (clean.includes('return')) {
    response = 'MOSPL supports 7 day return or replacement for unused products with original tags.';
  } else if (clean.includes('gift')) {
    response = 'I recommend MOSPL wallets, passport holders, hand woven belts, and women wallets from the current catalog.';
  } else if (clean.includes('wallet') || clean.includes('belt') || clean.includes('passport')) {
    response = 'Here are matching MOSPL leather products with 30% off, free shipping, and 5 day delivery.';
  }

  const recommendations = store.products
    .filter((product) => {
      const haystack = `${product.name} ${product.category} ${product.subcategory}`.toLowerCase();
      return clean.split(/\s+/).some((word) => word.length > 3 && haystack.includes(word));
    })
    .slice(0, 4)
    .map((product) => product.productId);

  const userMessage = {
    messageId: `msg_${Date.now()}_user`,
    userId,
    text,
    isUser: true,
    createdAt: new Date().toISOString(),
  };
  const botMessage = {
    messageId: `msg_${Date.now()}_bot`,
    userId,
    text: response,
    isUser: false,
    recommendedProductIds: recommendations.length ? recommendations : store.products.slice(0, 4).map((product) => product.productId),
    createdAt: new Date().toISOString(),
  };
  store.chatbotMessages.push(userMessage, botMessage);
  return botMessage;
}

module.exports = { replyToMessage };
