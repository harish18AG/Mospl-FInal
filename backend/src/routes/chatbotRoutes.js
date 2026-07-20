const router = require('express').Router();

const controller = require('../controllers/chatbotController');
const { requireAuth, optionalAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.post('/message', optionalAuth, requireFields(['text']), controller.sendMessage);
router.get('/history', requireAuth, controller.history);

module.exports = router;

