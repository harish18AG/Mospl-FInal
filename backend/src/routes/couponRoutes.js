const router = require('express').Router();

const controller = require('../controllers/couponController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.get('/', controller.list);
router.post('/', requireAuth, requireAdmin, requireFields(['code', 'discountPercent', 'minimumAmount']), controller.create);
router.patch('/:code', requireAuth, requireAdmin, controller.update);

module.exports = router;
