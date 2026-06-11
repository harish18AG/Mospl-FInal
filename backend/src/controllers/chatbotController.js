const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const chatbotService = require('../services/chatbotService');
const productService = require('../services/productService');
const store = require('../services/store');

const sendMessage = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const products = await productService.getAllProducts({});
    const clean = String(req.body.text || '').toLowerCase();
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
    const recommendations = products
      .filter((product) => {
        const haystack = `${product.name} ${product.category} ${product.subcategory}`.toLowerCase();
        return clean.split(/\s+/).some((word) => word.length > 3 && haystack.includes(word));
      })
      .slice(0, 4)
      .map((product) => product.productId);
    const now = new Date().toISOString();
    const userRef = db.collection('chatbot_messages').doc();
    const botRef = db.collection('chatbot_messages').doc();
    const userMessage = {
      messageId: userRef.id,
      userId: req.user.uid,
      text: req.body.text,
      isUser: true,
      createdAt: now,
    };
    const botMessage = {
      messageId: botRef.id,
      userId: req.user.uid,
      text: response,
      isUser: false,
      recommendedProductIds: recommendations.length ? recommendations : products.slice(0, 4).map((product) => product.productId),
      createdAt: now,
    };
    const batch = db.batch();
    batch.set(userRef, userMessage);
    batch.set(botRef, botMessage);
    await batch.commit();
    res.status(201).json({ ok: true, message: botMessage });
    return;
  }
  const message = chatbotService.replyToMessage({ userId: req.user.uid, text: req.body.text });
  res.status(201).json({ ok: true, message });
});

const history = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('chatbot_messages').where('userId', '==', req.user.uid).get();
    const messages = snapshot.docs
      .map((doc) => ({ messageId: doc.id, ...doc.data() }))
      .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0));
    res.json({ ok: true, messages });
    return;
  }
  const messages = store.chatbotMessages.filter((message) => message.userId === req.user.uid);
  res.json({ ok: true, messages });
});

module.exports = { sendMessage, history };
