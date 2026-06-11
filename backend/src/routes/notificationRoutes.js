const router = require('express').Router();

const controller = require('../controllers/notificationController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.get('/', controller.getNotifications);
router.post('/', requireAdmin, requireFields(['title', 'body']), controller.createNotification);
router.patch('/:notificationId/read', controller.markRead);

module.exports = router;
