const router = require('express').Router();

const controller = require('../controllers/inventoryController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');

router.use(requireAuth, requireAdmin);
router.get('/', controller.list);
router.patch('/:productId', controller.update);

module.exports = router;
