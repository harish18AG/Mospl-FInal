const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

const getReviews = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    let query = db.collection('reviews');
    if (req.params.productId) query = query.where('productId', '==', req.params.productId);
    const snapshot = await query.get();
    const reviews = snapshot.docs
      .map((doc) => ({ reviewId: doc.id, ...doc.data() }))
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    res.json({ ok: true, reviews });
    return;
  }
  const reviews = req.params.productId
    ? store.reviews.filter((review) => review.productId === req.params.productId)
    : store.reviews;
  res.json({ ok: true, reviews });
});

const addReview = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('reviews').doc();
    const review = {
      reviewId: ref.id,
      userId: req.user.uid,
      userName: req.user.email?.split('@')[0] || 'MOSPL Customer',
      productId: req.body.productId,
      rating: Number(req.body.rating || 5),
      comment: req.body.comment || '',
      createdAt: new Date().toISOString(),
    };
    await ref.set(review);

    // Update product rating and reviewCount in Firestore
    try {
      const productId = req.body.productId;
      const reviewsSnapshot = await db.collection('reviews').where('productId', '==', productId).get();
      const count = reviewsSnapshot.docs.length;
      let avgRating = 0;
      if (count > 0) {
        const sum = reviewsSnapshot.docs.reduce((total, doc) => total + (Number(doc.data().rating) || 0), 0);
        avgRating = sum / count;
      }
      await db.collection('products').doc(productId).update({
        rating: avgRating,
        reviewCount: count
      });
    } catch (e) {
      console.error('Failed to update product rating in Firestore:', e);
    }

    res.status(201).json({ ok: true, review });
    return;
  }
  const review = {
    reviewId: `REV-${Date.now()}`,
    userId: req.user.uid,
    userName: req.user.email?.split('@')[0] || 'MOSPL Customer',
    productId: req.body.productId,
    rating: Number(req.body.rating || 5),
    comment: req.body.comment || '',
    createdAt: new Date().toISOString(),
  };
  store.reviews.unshift(review);
  res.status(201).json({ ok: true, review });
});

module.exports = { getReviews, addReview };
