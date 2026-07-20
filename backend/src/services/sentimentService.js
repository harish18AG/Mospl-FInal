/**
 * Sentiment Analysis Service (Rule-Based NLP)
 *
 * Analyses review comment text to produce a sentiment score and label.
 * Uses a curated lexicon of positive/negative words with negation handling.
 * No external ML library required — mirrors the approach used in intentService.js.
 *
 * Score range: -1.0 (very negative) to +1.0 (very positive), 0.0 = neutral
 * Labels: 'positive' | 'neutral' | 'negative'
 */

// ── Positive lexicon ─────────────────────────────────────────────────────────
const POSITIVE_WORDS = new Set([
  // Quality
  'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'superb',
  'outstanding', 'perfect', 'premium', 'genuine', 'quality', 'good', 'nice',
  'fine', 'solid', 'sturdy', 'durable', 'lasting', 'strong',
  // Appearance
  'beautiful', 'gorgeous', 'elegant', 'stylish', 'classy', 'sleek',
  'attractive', 'lovely', 'pretty',
  // Leather-specific
  'soft', 'smooth', 'supple', 'rich', 'luxurious', 'crafted', 'handcrafted',
  // Experience
  'love', 'loved', 'like', 'liked', 'happy', 'satisfied', 'pleased',
  'impressed', 'delighted', 'thrilled', 'excited', 'recommend', 'recommended',
  'worth', 'value', 'affordable', 'reasonable',
  // Delivery / service
  'fast', 'quick', 'prompt', 'timely', 'early', 'packaged', 'safe', 'secure',
  // Value words
  'best', 'top', 'awesome', 'brilliant', 'phenomenal', 'fabulous',
]);

// ── Negative lexicon ─────────────────────────────────────────────────────────
const NEGATIVE_WORDS = new Set([
  // Quality
  'bad', 'poor', 'cheap', 'flimsy', 'fragile', 'weak', 'thin', 'inferior',
  'substandard', 'worst', 'terrible', 'horrible', 'awful', 'dreadful',
  'useless', 'worthless', 'rubbish', 'garbage', 'trash',
  // Fake / fraud
  'fake', 'duplicate', 'counterfeit', 'plastic', 'artificial', 'synthetic',
  // Damage
  'damaged', 'broken', 'defective', 'torn', 'ripped', 'peeling', 'cracked',
  'scratched', 'stained', 'smelly',
  // Experience
  'disappointed', 'unhappy', 'unsatisfied', 'dissatisfied', 'upset',
  'frustrated', 'angry', 'regret', 'waste', 'wasted',
  // Delivery / service
  'late', 'slow', 'delayed', 'wrong', 'missing', 'lost',
  // Return
  'returned', 'returning', 'refund', 'replacement',
]);

// ── Negation words that flip the next word's polarity ────────────────────────
const NEGATION_WORDS = new Set([
  'not', 'no', 'never', "isn't", "wasn't", "don't", "doesn't", "didn't",
  "won't", "wouldn't", "couldn't", "can't", 'hardly', 'barely', 'neither',
  'nor', 'without',
]);

// ── Intensifiers that boost score magnitude ──────────────────────────────────
const INTENSIFIERS = new Set([
  'very', 'really', 'extremely', 'absolutely', 'totally', 'completely',
  'so', 'highly', 'super', 'incredibly', 'exceptionally',
]);

/**
 * Tokenizes text into lowercase words, stripping punctuation.
 * @param {string} text
 * @returns {string[]}
 */
function tokenize(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s'-]/g, ' ')
    .split(/\s+/)
    .filter(Boolean);
}

/**
 * Analyses sentiment of a review comment.
 *
 * @param {string} text - Raw review comment text
 * @returns {{ sentimentScore: number, sentimentLabel: string }}
 *   sentimentScore: float in [-1.0, 1.0]
 *   sentimentLabel: 'positive' | 'neutral' | 'negative'
 */
function analyzeSentiment(text) {
  if (!text || text.trim().length === 0) {
    return { sentimentScore: 0.0, sentimentLabel: 'neutral' };
  }

  const tokens = tokenize(text);
  let rawScore = 0;
  let termCount = 0;
  let negated = false;
  let intensify = false;

  for (let i = 0; i < tokens.length; i++) {
    const word = tokens[i];

    // Track negation window (negation affects next word)
    if (NEGATION_WORDS.has(word)) {
      negated = true;
      continue;
    }

    // Track intensifier
    if (INTENSIFIERS.has(word)) {
      intensify = true;
      continue;
    }

    let wordScore = 0;
    if (POSITIVE_WORDS.has(word)) {
      wordScore = 1;
    } else if (NEGATIVE_WORDS.has(word)) {
      wordScore = -1;
    } else {
      // Reset negation/intensifier on neutral word
      negated = false;
      intensify = false;
      continue;
    }

    // Apply negation (flips polarity)
    if (negated) {
      wordScore *= -1;
      negated = false;
    }

    // Apply intensifier (boosts by 50%)
    if (intensify) {
      wordScore *= 1.5;
      intensify = false;
    }

    rawScore += wordScore;
    termCount++;
  }

  // Normalise to [-1, 1] — average over at least 3 terms to avoid extremes
  let score = 0.0;
  if (termCount > 0) {
    score = Math.max(-1.0, Math.min(1.0, rawScore / Math.max(termCount, 3)));
  }

  // Determine label with slight threshold to avoid noise
  let label = 'neutral';
  if (score >= 0.15) label = 'positive';
  else if (score <= -0.15) label = 'negative';

  return {
    sentimentScore: Math.round(score * 1000) / 1000, // 3 decimal places
    sentimentLabel: label,
  };
}

/**
 * Computes a composite NLP ranking score for a product given its reviews.
 * Combines star rating (50%), text sentiment (30%), and review volume confidence (20%).
 *
 * @param {Array<{rating: number, sentimentScore: number}>} reviews
 * @returns {number} Score in [0, 1]
 */
function computeProductNlpScore(reviews) {
  if (!reviews || reviews.length === 0) return 0;

  const count = reviews.length;
  const avgStars = reviews.reduce((sum, r) => sum + (Number(r.rating) || 0), 0) / count;
  const avgSentiment = reviews.reduce((sum, r) => sum + (Number(r.sentimentScore) || 0), 0) / count;

  // Normalise sentiment from [-1,1] to [0,1]
  const normSentiment = (avgSentiment + 1) / 2;

  // Volume confidence: saturates at 20 reviews
  const volumeConfidence = Math.min(count / 20, 1.0);

  return (avgStars / 5) * 0.5
    + normSentiment * 0.3
    + volumeConfidence * 0.2;
}

module.exports = { analyzeSentiment, computeProductNlpScore };
