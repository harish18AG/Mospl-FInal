const router = require('express').Router();

const controller = require('../controllers/addressController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.use(requireAuth);
router.get('/', controller.list);
router.post('/', requireFields(['name', 'phone', 'line1', 'city', 'state', 'pincode']), controller.create);
router.patch('/:addressId', controller.update);
router.delete('/:addressId', controller.remove);

module.exports = router;
