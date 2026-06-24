const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const productService = require('../services/productService');
const geminiService = require('../services/geminiService');
const store = require('../services/store');

const sendMessage = asyncHandler(async (req, res) => {
  const products = isFirebaseConfigured && db
    ? await productService.getAllProducts({})
    : store.products;

  // 1. Load context history (last 10 messages)
  let history = [];
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('chatbot_messages')
      .where('userId', '==', req.user.uid)
      .get();
    history = snapshot.docs
      .map(doc => doc.data())
      .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0))
      .slice(-10);
  } else {
    history = store.chatbotMessages
      .filter(msg => msg.userId === req.user.uid)
      .sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0))
      .slice(-10);
  }

  // 2. Generate chat response from Gemini LLM
  const geminiResponse = await geminiService.generateChatResponse({
    text: req.body.text || '',
    history,
    products
  });

  const now = new Date().toISOString();

  // 3. Persist messages and reply
  if (isFirebaseConfigured && db) {
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
      text: geminiResponse.text,
      isUser: false,
      recommendedProductIds: geminiResponse.recommendedProductIds,
      createdAt: now,
    };
    const batch = db.batch();
    batch.set(userRef, userMessage);
    batch.set(botRef, botMessage);
    await batch.commit();
    res.status(201).json({ ok: true, message: botMessage });
    return;
  }

  const userMessage = {
    messageId: `msg_${Date.now()}_user`,
    userId: req.user.uid,
    text: req.body.text,
    isUser: true,
    createdAt: now,
  };
  const botMessage = {
    messageId: `msg_${Date.now()}_bot`,
    userId: req.user.uid,
    text: geminiResponse.text,
    isUser: false,
    recommendedProductIds: geminiResponse.recommendedProductIds,
    createdAt: now,
  };
  store.chatbotMessages.push(userMessage, botMessage);
  res.status(201).json({ ok: true, message: botMessage });
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
