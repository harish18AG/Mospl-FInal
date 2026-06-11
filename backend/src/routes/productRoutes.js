const router = require('express').Router();

const controller = require('../controllers/productController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.get('/', controller.getProducts);
router.get('/search', controller.getProducts);
router.get('/:productId', controller.getProduct);
router.post('/', requireAuth, requireAdmin, requireFields(['name', 'category', 'price']), controller.createProduct);
router.put('/:productId', requireAuth, requireAdmin, controller.updateProduct);
router.delete('/:productId', requireAuth, requireAdmin, controller.deleteProduct);

module.exports = router;
