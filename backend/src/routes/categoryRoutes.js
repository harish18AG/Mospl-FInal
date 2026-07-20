const router = require('express').Router();

const controller = require('../controllers/categoryController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

router.get('/', controller.getCategories);
router.post('/', requireAuth, requireAdmin, controller.createCategory);
router.delete('/:categoryId', requireAuth, requireAdmin, controller.deleteCategory);

module.exports = router;
