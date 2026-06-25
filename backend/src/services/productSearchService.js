/**
 * Product Search Service
 * Handles local queries for product lists, categories, prices, and availability.
 */

const productService = require('./productService');

/**
 * Searches the catalog locally based on user message text.
 * 
 * @param {string} text User query text
 * @returns {Promise<Object>} { text: string, recommendedProductIds: Array<string> }
 */
async function searchProductsLocally(text) {
  const clean = String(text || '').toLowerCase();
  const query = {};

  // Extract Category
  if (
    clean.includes('women wallet') || 
    clean.includes("women's wallet") || 
    clean.includes('women wallets') || 
    clean.includes("women's wallets") ||
    (clean.includes('women') && (clean.includes('wallet') || clean.includes('wallets'))) ||
    (clean.includes('woman') && (clean.includes('wallet') || clean.includes('wallets'))) ||
    (clean.includes('lady') && (clean.includes('wallet') || clean.includes('wallets'))) ||
    (clean.includes('ladies') && (clean.includes('wallet') || clean.includes('wallets')))
  ) {
    query.category = 'Women Wallets';
  } else if (
    clean.includes('men wallet') || 
    clean.includes("men's wallet") || 
    clean.includes('men wallets') || 
    clean.includes("men's wallets") ||
    (clean.includes('men') && (clean.includes('wallet') || clean.includes('wallets'))) ||
    (clean.includes('man') && (clean.includes('wallet') || clean.includes('wallets'))) ||
    clean.includes('coat wallet') ||
    clean.includes('coat wallets')
  ) {
    query.category = 'Men Wallets';
  } else if (clean.includes('passport') || clean.includes('passports') || clean.includes('travel')) {
    query.category = 'Passport Holders';
  } else if (clean.includes('belt') || clean.includes('belts')) {
    query.category = 'Men Belts';
  } else if (clean.includes('wallet') || clean.includes('wallets')) {
    query.category = 'Men Wallets'; // Default wallets to Men Wallets
  }

  // Extract Price Constraints (under, below, less than, range)
  const rangeMatch = clean.match(/(\d+)\s*(?:to|-)\s*(\d+)/);
  if (rangeMatch) {
    query.minPrice = Number(rangeMatch[1]);
    query.maxPrice = Number(rangeMatch[2]);
  } else {
    const maxPriceMatch = clean.match(/(?:under|below|less than|max|maximum|rs\.?|inr|₹)\s*(\d+)/i);
    if (maxPriceMatch) {
      query.maxPrice = Number(maxPriceMatch[1]);
    }
    const minPriceMatch = clean.match(/(?:above|greater than|more than|over|min|minimum)\s*(\d+)/i);
    if (minPriceMatch) {
      query.minPrice = Number(minPriceMatch[1]);
    }
  }

  // Fetch all products using existing service
  let products = await productService.getAllProducts(query);

  // If a general search term might be present, filter further
  // Extract search term by removing common words/stop words
  const stopWords = [
    'show', 'search', 'find', 'me', 'under', 'below', 'above', 'price', 'pricing', 'cost', 'how much', 
    'is', 'are', 'there', 'any', 'available', 'availability', 'stock', 'in stock', 'inr', 'rs', 
    'wallet', 'wallets', 'belt', 'belts', 'passport', 'passports', 'cover', 'covers', 'holder', 'holders',
    'women', "women's", 'woman', "woman's", 'lady', 'ladies', 'men', "men's", 'man', "man's", 'gent', 'gents', 'gentlemen', 'travel'
  ];
  const words = clean.split(/\s+/).filter(w => !stopWords.includes(w) && w.length > 2 && !/^\d+$/.test(w));
  
  if (words.length > 0) {
    products = products.filter(p => {
      const haystack = `${p.name} ${p.category} ${p.subcategory} ${p.color} ${p.description}`.toLowerCase();
      return words.some(word => haystack.includes(word));
    });
  }

  // Filter out of stock products if user asks for "available" or "in stock"
  if (clean.includes('available') || clean.includes('in stock') || clean.includes('availability')) {
    products = products.filter(p => p.stock > 0);
  }

  // Limit to at most 4 products
  const matched = products.slice(0, 4);
  const recommendedProductIds = matched.map(p => p.productId);

  if (matched.length === 0) {
    return {
      text: "I couldn't find any matching products in our catalog. We have premium leather Men Wallets, Women Wallets, Passport Holders, and Men Belts available with free shipping and 7-day easy returns.",
      recommendedProductIds: []
    };
  }

  // Build conversational response
  let responseText = "Here are matching MOSPL genuine leather products from our catalog:\n";
  matched.forEach(p => {
    const stockStatus = p.stock > 0 ? `In Stock (${p.stock} left)` : "Sold Out";
    responseText += `- ${p.name} | Price: ₹${p.price} | Color: ${p.color} | Status: ${stockStatus}\n`;
  });
  responseText += "\nAll orders include free shipping and 5-day delivery!";

  return {
    text: responseText,
    recommendedProductIds
  };
}

module.exports = { searchProductsLocally };
