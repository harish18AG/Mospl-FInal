/**
 * FAQ Service
 * Returns pre-configured responses for FAQ queries to save on Gemini API calls.
 */

const { INTENTS } = require('./intentService');

const FAQ_RESPONSES = {
  [INTENTS.FAQ_RETURN]: "MOSPL supports a 7-day easy return or replacement policy for unused products with original tags. To request a return or replacement, please open a support ticket in the app.",
  [INTENTS.FAQ_SHIPPING]: "We offer free shipping on all orders across the country. There are no delivery fees or hidden charges.",
  [INTENTS.FAQ_REFUND]: "Once your returned product is received and inspected, refunds are processed securely back to your original payment method (via Razorpay) within 5-7 business days.",
  [INTENTS.FAQ_DELIVERY_TIME]: "Standard delivery takes approximately 5 business days from the date of order confirmation.",
  [INTENTS.FAQ_CONTACT]: "You can reach MOSPL customer support by opening a support ticket in the app, emailing us at support@mospl.com, or calling our helpline at +1-800-MOSPL-HELP.",
  [INTENTS.FAQ_STORE]: "MOSPL is a premium leather goods store specializing in genuine leather wallets, passport holders, and hand-woven belts. We focus on premium quality, craftsmanship, and customer satisfaction."
};

/**
 * Returns response for the given FAQ intent.
 * 
 * @param {string} intent One of INTENTS FAQ values
 * @returns {string} FAQ answer string
 */
function getFAQResponse(intent) {
  return FAQ_RESPONSES[intent] || "For more information, please check our help center or open a support ticket.";
}

module.exports = { getFAQResponse };
