const { GoogleGenAI } = require('@google/genai');

const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

/**
 * Generate chat response from Gemini LLM using conversation history and product context.
 *
 * @param {Object} params
 * @param {string} params.text Current user message
 * @param {Array<Object>} params.history Message history array: [{ text, isUser }]
 * @param {Array<Object>} params.products Complete catalog products
 * @returns {Promise<Object>} { text: string, recommendedProductIds: Array<string> }
 */
async function generateChatResponse({ text, history, products }) {
  if (!ai) {
    throw new Error('Gemini API is not initialized. Please set GEMINI_API_KEY.');
  }

  try {
    // Format products context list for the LLM
    const productsContext = products.map(p => ({
      productId: p.productId,
      name: p.name,
      category: p.category,
      price: p.price,
      color: p.color,
      stock: p.stock,
      description: p.description
    }));

    // Map history to Gemini API format: [{ role: 'user'|'model', parts: [{ text: '...' }] }]
    const contents = history.map(msg => ({
      role: msg.isUser ? 'user' : 'model',
      parts: [{ text: msg.text }]
    }));

    // Append the current message
    contents.push({
      role: 'user',
      parts: [{ text }]
    });

    const systemInstruction = `
You are the MOSPL AI Shopping Assistant, a helpful and expert assistant for MOSPL, a premium leather goods store specializing in genuine leather wallets, passport holders, and belts.

Our business policies:
- Shipping: Free delivery on all orders, with 5-day delivery.
- Returns: 7-day easy return or replacement for unused products with original tags.
- Payment: Secure online payment via Razorpay.
- Stock Limits: All products have a strict maximum stock limit of 30 items. If an item runs out (stock is 0), it is sold out.
- Support: For order disputes, refunds, or support, users can open support tickets in the app.

Available products in our catalog:
${JSON.stringify(productsContext, null, 2)}

Instructions:
1. Respond to the user's message naturally, answering their questions about products, shipping, returns, or gifts.
2. Be extremely concise, direct, and responsive like standard high-quality AI chatbots. Avoid conversational fluff or filler words at the start of your message (e.g., avoid saying "Sure, I can help you with that", "Okay, here is what you requested"). Get straight to the answer.
3. If they ask for recommendations or products, refer to the available products catalog. Suggest products that match their needs (e.g. matching color, price, category).
4. Do not mention product IDs (e.g., 'MOSPL-OM-001') in your text response. Instead, describe the products naturally by their name, color, and price.
5. NEVER generate or respond with any foul, offensive, or inappropriate words. If the user input contains inappropriate, hateful, or abusive remarks, politely ask them to remain respectful and restrict your response to MOSPL policies or products.
6. Output your response strictly as a JSON object with this exact schema:
{
  "response": "Your conversational response string here",
  "recommendedProductIds": ["array", "of", "up", "to", "4", "matching", "product", "IDs"]
}
If no specific products are asked for or relevant, return an empty array [] for recommendedProductIds.
`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash-lite',
      contents: contents,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: 'application/json',
        safetySettings: [
          { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_LOW_AND_ABOVE' },
          { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_LOW_AND_ABOVE' },
          { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_LOW_AND_ABOVE' },
          { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_LOW_AND_ABOVE' }
        ]
      }
    });


    const responseText = response.text || '';
    const parsed = JSON.parse(responseText.trim());
    
    return {
      text: parsed.response || "I am here to help you shop. What are you looking for?",
      recommendedProductIds: parsed.recommendedProductIds || []
    };
  } catch (error) {
    console.error('Gemini Service generation error:', error);
    // Standard rule-based fallback response if Gemini fails
    return {
      text: "I'm having trouble connecting to my Gemini brain right now. MOSPL offers high-quality leather wallets, belts, and passport covers with free shipping and 7-day easy returns. What can I help you find?",
      recommendedProductIds: products.slice(0, 4).map(p => p.productId)
    };
  }
}

module.exports = { generateChatResponse };
