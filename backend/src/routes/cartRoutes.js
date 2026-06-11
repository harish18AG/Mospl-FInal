const router = require('express').Router();

const controller = require('../controllers/cartController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.get('/', controller.getMyCart);
router.post('/items', requireFields(['productId']), controller.addItem);
router.patch('/items/:productId', controller.updateItem);
router.delete('/items/:productId', controller.removeItem);
router.delete('/', controller.clearCart);

module.exports = router;
