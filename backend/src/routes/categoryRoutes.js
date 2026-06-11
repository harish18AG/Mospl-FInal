const router = require('express').Router();

const controller = require('../controllers/categoryController');

router.get('/', controller.getCategories);

module.exports = router;
