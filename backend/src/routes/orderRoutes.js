const router = require('express').Router();

const controller = require('../controllers/orderController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');

router.use(requireAuth);
router.get('/', controller.getOrders);
router.post('/', controller.createOrder);
router.get('/:orderId', controller.getOrder);
router.patch('/:orderId/status', requireAdmin, controller.updateOrderStatus);

module.exports = router;
