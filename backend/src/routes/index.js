const router = require('express').Router();

router.use('/auth', require('./authRoutes'));
router.use('/products', require('./productRoutes'));
router.use('/categories', require('./categoryRoutes'));
router.use('/cart', require('./cartRoutes'));
router.use('/wishlist', require('./wishlistRoutes'));
router.use('/orders', require('./orderRoutes'));
router.use('/addresses', require('./addressRoutes'));
router.use('/payments', require('./paymentRoutes'));
router.use('/reviews', require('./reviewRoutes'));
router.use('/notifications', require('./notificationRoutes'));
router.use('/chatbot', require('./chatbotRoutes'));
router.use('/coupons', require('./couponRoutes'));
router.use('/banners', require('./bannerRoutes'));
router.use('/inventory', require('./inventoryRoutes'));
router.use('/returns', require('./returnRoutes'));
router.use('/support-tickets', require('./supportTicketRoutes'));
router.use('/admin', require('./adminRoutes'));
router.use('/daily-offers', require('./dailyOfferRoutes'));

module.exports = router;
