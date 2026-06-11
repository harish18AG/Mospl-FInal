const router = require('express').Router();

const controller = require('../controllers/returnController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.get('/', controller.list);
router.post('/', requireFields(['orderId', 'reason']), controller.create);
router.patch('/:returnId', requireAdmin, controller.update);

module.exports = router;
