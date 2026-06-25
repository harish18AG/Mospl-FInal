const router = require('express').Router();
const controller = require('../controllers/dailyOfferController');
const { requireAdmin, requireAuth } = require('../middleware/authMiddleware');

router.get('/', controller.getOffers);
router.put('/', requireAuth, requireAdmin, controller.updateOffers);

module.exports = router;
