const router = require('express').Router();

const controller = require('../controllers/bannerController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.get('/', controller.list);
router.post('/', requireAuth, requireAdmin, requireFields(['title', 'subtitle', 'imageUrl']), controller.create);
router.patch('/:bannerId', requireAuth, requireAdmin, controller.update);

module.exports = router;
