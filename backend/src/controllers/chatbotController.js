const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const productService = require('../services/productService');
const geminiService = require('../services/geminiService');
const intentService = require('../services/intentService');
const faqService = require('../services/faqService');
const productSearchService = require('../services/productSearchService');
const orderSupportService = require('../services/orderSupportService');
const store = require('../services/store');
const { hasProfanity } = require('../utils/moderation');

const sendMessage = asyncHandler(async (req, res) => {
  const text = req.body.text || '';
  const userId = req.user ? req.user.uid : 'guest';

  // Check for profanity / inappropriate language
  if (hasProfanity(text)) {
    const now = new Date().toISOString();
    const botMessage = {
      messageId: `msg_${Date.now()}_bot`,
      userId,
      text: "I can only help you with questions about MOSPL leather products, ordering, or returns. Please keep the conversation respectful and avoid using inappropriate language.",
      isUser: false,
      recommendedProductIds: [],
      createdAt: now,
    };
    res.status(201).json({ ok: true, message: botMessage });
    return;
  }

  // 1. Detect Intent
  const intent = intentService.detectIntent(text);
  let geminiResponse;


  if (intent === intentService.INTENTS.GEMINI) {
    // Load products catalog and chat history only when calling Gemini
    const products = isFirebaseConfigured && db
      ? await productService.getAllProducts({})
      : store.products;

    let history = [];
    if (isFirebaseConfigured && db) {
      const snapshot = await db.collection('chatbot_messages')
        .where('userId', '==', userId)
        .get();
      history = snapshot.docs
        .map(doc => doc.data())
        .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0))
        .slice(-10);
    } else {
      history = store.chatbotMessages
        .filter(msg => msg.userId === userId)
        .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0))
        .slice(-10);
    }

    geminiResponse = await geminiService.generateChatResponse({
      text,
      history,
      products
    });
  } else if (intent === intentService.INTENTS.ORDER_SUPPORT) {
    if (userId === 'guest') {
      geminiResponse = {
        text: "Please sign in to your MOSPL account to view order details, track shipments, or raise support tickets.",
        recommendedProductIds: []
      };
    } else {
      geminiResponse = await orderSupportService.handleOrderSupport({
        userId,
        text
      });
    }

  } else if (intent === intentService.INTENTS.PRODUCT_SEARCH) {
    geminiResponse = await productSearchService.searchProductsLocally(text);
  } else {
    // Intent is FAQ_*
    geminiResponse = {
      text: faqService.getFAQResponse(intent),
      recommendedProductIds: []
    };
  }

  const now = new Date().toISOString();

  // Chat is session-local — messages are not persisted to Firestore.
  // Return the bot reply directly without storing anything.
  const botMessage = {
    messageId: `msg_${Date.now()}_bot`,
    userId,
    text: geminiResponse.text,
    isUser: false,
    recommendedProductIds: geminiResponse.recommendedProductIds,
    createdAt: now,
  };
  res.status(201).json({ ok: true, message: botMessage });
});

const history = asyncHandler(async (req, res) => {
  // Chat is session-local — history is not stored server-side.
  res.json({ ok: true, messages: [] });
});

module.exports = { sendMessage, history };
