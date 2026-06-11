const router = require('express').Router();

const controller = require('../controllers/chatbotController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.post('/message', requireFields(['text']), controller.sendMessage);
router.get('/history', controller.history);

module.exports = router;
