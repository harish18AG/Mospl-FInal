const router = require('express').Router();

const controller = require('../controllers/adminController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');

router.use(requireAuth, requireAdmin);
router.get('/dashboard', controller.dashboard);
router.get('/users', controller.users);
router.get('/analytics', controller.analytics);
router.get('/revenue', controller.analytics);
router.get('/sales-charts', controller.analytics);

module.exports = router;
