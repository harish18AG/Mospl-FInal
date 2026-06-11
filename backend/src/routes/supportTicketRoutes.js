const router = require('express').Router();

const controller = require('../controllers/supportTicketController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.get('/', controller.list);
router.post('/', requireFields(['subject', 'message']), controller.create);
router.patch('/:ticketId', requireAdmin, controller.update);

module.exports = router;
