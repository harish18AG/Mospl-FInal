import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/account_support_screens.dart';
import '../screens/admin_screens.dart';
import '../screens/auth_screens.dart';
import '../screens/checkout_screens.dart';
import '../screens/shop_screens.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding/:index',
        builder: (context, state) => OnboardingScreen(
          index: int.tryParse(state.pathParameters['index'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/account-created', builder: (context, state) => const AccountCreatedSuccessScreen()),
      GoRoute(path: '/admin-login', builder: (context, state) => const SignInScreen(adminMode: true)),
      ShellRoute(
        builder: (context, state, child) => ShopShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
          GoRoute(path: '/products', builder: (context, state) => const ProductListingScreen()),
          GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/search-results', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/filters', builder: (context, state) => const FiltersScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/gallery/:id',
        builder: (context, state) => ProductGalleryScreen(
          productId: state.pathParameters['id'] ?? '',
          initialIndex: int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/addresses', builder: (context, state) => const AddressListScreen()),
      GoRoute(path: '/add-address', builder: (context, state) => const AddAddressScreen()),
      GoRoute(path: '/payment-method', builder: (context, state) => const PaymentMethodScreen()),
      GoRoute(
        path: '/razorpay-payment/:orderId',
        builder: (context, state) => RazorpayPaymentScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/order-success/:orderId',
        builder: (context, state) => OrderSuccessScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/order-failed/:orderId',
        builder: (context, state) => OrderFailedScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(path: '/my-orders', builder: (context, state) => const MyOrdersScreen()),
      GoRoute(
        path: '/order-details/:orderId',
        builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/track-order/:orderId',
        builder: (context, state) => TrackOrderScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(path: '/reviews', builder: (context, state) => const ReviewsScreen()),
      GoRoute(path: '/ratings', builder: (context, state) => const RatingsScreen()),
      GoRoute(path: '/returns', builder: (context, state) => const ReturnsScreen()),
      GoRoute(path: '/support-tickets', builder: (context, state) => const SupportTicketsScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/offers', builder: (context, state) => const OffersScreen()),
      GoRoute(path: '/coupons', builder: (context, state) => const CouponsScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/about',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'About MOSPL',
          icon: Icons.storefront_outlined,
          lines: [
            'MOSPL brings Online Madras leather product listings into a fast mobile shopping experience.',
            'Shop genuine leather wallets, belts, passport holders, and women wallets with simple checkout and order support.',
          ],
        ),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'Contact',
          icon: Icons.support_agent,
          lines: [
            'Email: support@mospl.test',
            'Store support: Monday to Saturday, 10 AM to 6 PM.',
            'Our support team can help with orders, returns, payments, and product questions.',
          ],
        ),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'FAQ',
          icon: Icons.quiz_outlined,
          lines: [
            'Delivery: most MOSPL leather products show 5 day delivery with free shipping.',
            'Returns: unused products can be returned or replaced within 7 days.',
            'Payments: INR checkout is handled securely through Razorpay.',
          ],
        ),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip_outlined,
          lines: [
            'MOSPL stores user profile, carts, wishlists, orders, payments, reviews, notifications, and chatbot messages in scoped Firestore collections.',
            'Private user data is readable only by the owner. Product data is public-read and admin-write.',
          ],
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'Terms',
          icon: Icons.description_outlined,
          lines: [
            'Orders, payments, returns, coupons, and support activity follow MOSPL ecommerce policies.',
            'Product names, prices, categories, and images are based on current Online Madras MOSPL listings.',
          ],
        ),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const SimpleInfoScreen(
          title: 'Help Center',
          icon: Icons.help_outline,
          lines: [
            'Use AI Chatbot for shopping and order questions.',
            'Use My Orders for payment, shipment, and retry payment handling.',
            'Phone support: 9150478209.',
            'Use Contact for product, payment, return, and account support.',
          ],
        ),
      ),
      GoRoute(path: '/ai-chatbot', builder: (context, state) => const AIChatbotScreen()),
      GoRoute(path: '/chat-history', builder: (context, state) => const ChatHistoryScreen()),
      GoRoute(
        path: '/recently-viewed',
        builder: (context, state) => CollectionScreen(
          title: 'Recently Viewed',
          selector: (app) => app.recentlyViewed,
          emptyText: 'Open a product to build your recently viewed list.',
        ),
      ),
      GoRoute(
        path: '/recommended',
        builder: (context, state) => CollectionScreen(
          title: 'Recommended Products',
          selector: (app) => app.recommendations,
        ),
      ),
      GoRoute(
        path: '/trending',
        builder: (context, state) => CollectionScreen(
          title: 'Trending Products',
          selector: (app) => app.trendingProducts,
        ),
      ),
      GoRoute(
        path: '/flash-sale',
        builder: (context, state) => CollectionScreen(
          title: 'Flash Sale',
          selector: (app) => app.allProducts.where((p) => p.discountPercentage >= 30).take(40).toList(),
        ),
      ),
      GoRoute(
        path: '/leather-collections',
        builder: (context, state) => CollectionScreen(
          title: 'Leather Collections',
          selector: (app) => app.featuredProducts,
        ),
      ),
      GoRoute(path: '/comparison', builder: (context, state) => const ProductComparisonScreen()),
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminGate(child: AdminDashboardScreen())),
      GoRoute(path: '/admin/products', builder: (context, state) => const AdminGate(child: AdminProductsScreen())),
      GoRoute(path: '/admin/products/add', builder: (context, state) => const AdminGate(child: ProductFormScreen())),
      GoRoute(
        path: '/admin/products/edit/:id',
        builder: (context, state) => AdminGate(child: ProductFormScreen(productId: state.pathParameters['id'])),
      ),
      GoRoute(path: '/admin/categories', builder: (context, state) => const AdminGate(child: AdminCategoriesScreen())),
      GoRoute(path: '/admin/orders', builder: (context, state) => const AdminGate(child: AdminOrdersScreen())),
      GoRoute(path: '/admin/users', builder: (context, state) => const AdminGate(child: AdminSimpleScreen(title: 'Admin Users', icon: Icons.people_outline))),
      GoRoute(path: '/admin/reviews', builder: (context, state) => const AdminGate(child: AdminSimpleScreen(title: 'Admin Reviews', icon: Icons.rate_review_outlined))),
      GoRoute(path: '/admin/notifications', builder: (context, state) => const AdminGate(child: AdminSimpleScreen(title: 'Admin Notifications', icon: Icons.notifications_none))),
      GoRoute(path: '/admin/inventory', builder: (context, state) => const AdminGate(child: AdminInventoryScreen())),
      GoRoute(path: '/admin/analytics', builder: (context, state) => const AdminGate(child: AdminAnalyticsScreen(title: 'Admin Analytics'))),
      GoRoute(path: '/admin/revenue', builder: (context, state) => const AdminGate(child: AdminAnalyticsScreen(title: 'Revenue Statistics'))),
      GoRoute(path: '/admin/sales-charts', builder: (context, state) => const AdminGate(child: AdminAnalyticsScreen(title: 'Sales Charts'))),
    ],
  );
}
