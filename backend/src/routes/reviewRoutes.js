const router = require('express').Router();

const controller = require('../controllers/reviewController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.get('/', controller.getReviews);
router.get('/product/:productId', controller.getReviews);
router.post('/', requireAuth, requireFields(['productId', 'rating', 'comment']), controller.addReview);

module.exports = router;
