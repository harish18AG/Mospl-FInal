const router = require('express').Router();

const controller = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireFields } = require('../middleware/validate');

router.post('/register', requireFields(['name', 'email', 'password']), controller.register);
router.post('/login', requireFields(['email', 'password']), controller.login);
router.post('/firebase-session', requireFields(['idToken']), controller.firebaseSession);
router.post('/logout', requireAuth, controller.logout);
router.post('/forgot-password', requireFields(['email']), controller.forgotPassword);
router.get('/me', requireAuth, controller.currentUser);
router.patch('/profile', requireAuth, controller.updateProfile);

module.exports = router;
