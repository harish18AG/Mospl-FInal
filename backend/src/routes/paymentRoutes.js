const router = require('express').Router();

const controller = require('../controllers/paymentController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.post('/create-order', requireFields(['amount']), controller.createOrder);
router.post('/verify', requireFields(['razorpayOrderId', 'razorpayPaymentId', 'razorpaySignature']), controller.verifyPayment);
router.get('/history', controller.paymentHistory);
router.post('/:orderId/retry', controller.retryPayment);

module.exports = router;
