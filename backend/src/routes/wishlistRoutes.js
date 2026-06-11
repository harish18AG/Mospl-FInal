const router = require('express').Router();

const controller = require('../controllers/wishlistController');
const { requireAuth } = require('../middleware/authMiddleware');

router.use(requireAuth);
router.get('/', controller.getWishlistProducts);
router.post('/:productId', controller.addWishlistProduct);
router.delete('/:productId', controller.removeWishlistProduct);

module.exports = router;
