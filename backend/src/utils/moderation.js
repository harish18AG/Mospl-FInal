/**
 * Chatbot Moderation Utility
 *
 * Provides functions to detect and block profane, inappropriate,
 * or foul language in user messages.
 */

// A basic lexicon of inappropriate/foul/offensive words
const PROFANITY_WORDS = new Set([
  // Common english swear/foul words
  'fuck', 'fucking', 'fucker', 'shit', 'shitty', 'asshole', 'bitch', 'bitches',
  'bastard', 'cunt', 'dick', 'pussy', 'slut', 'whore', 'crap', 'bullshit',
  'damn', 'cock', 'fag', 'faggot', 'nigger', 'chink', 'retard', 'idiot', 'stupid',
  'jerk', 'dumbass', 'kill yourself', 'kys', 'die', 'hate', 'trash', 'garbage',
  // Common hindi/indian foul words transliterated
  'chutiya', 'bhenchod', 'madarchod', 'bhonsdike', 'harami', 'saala', 'kamina',
  'gandu', 'randi', 'bhadva', 'loda', 'lauda', 'muth', 'bhosda', 'bhosdike'
]);

/**
 * Checks if the text input contains any profane or inappropriate words.
 *
 * @param {string} text - User message input
 * @returns {boolean} True if profanity is detected
 */
function hasProfanity(text) {
  if (!text) return false;
  
  // Clean punctuation and tokenize text
  const cleanText = text
    .toLowerCase()
    .replace(/[^a-z0-9\s'-]/g, ' ')
    .trim();
    
  const tokens = cleanText.split(/\s+/);
  
  // Check exact matches or phrase matches
  for (const token of tokens) {
    if (PROFANITY_WORDS.has(token)) {
      return true;
    }
  }

  // Check sub-phrase combinations for common toxic patterns
  const lowerText = text.toLowerCase();
  if (lowerText.includes('kill yourself') || lowerText.includes('go die') || lowerText.includes('fuck you')) {
    return true;
  }
  
  return false;
}

module.exports = {
  hasProfanity
};
