# MOSPL Ecommerce Mobile App

MOSPL is a production-structured Flutter + Node.js + Firebase ecommerce project for leather products inspired by the public Online Madras MOSPL catalog.

## What Is Included

- Flutter Android app with Email/Password auth flow, onboarding, home, categories, search, filters, sorting, product detail gallery with zoom, wishlist, cart, checkout, Razorpay test payment UI, orders, profile, settings, support pages, chatbot, and admin dashboard.
- Node.js Express backend with Firebase Admin integration, JWT-protected APIs, product/category/cart/wishlist/order/payment/review/admin/notification/chatbot routes, Razorpay test order creation, and crypto signature verification.
- Firestore schema reference, security rules, indexes, and seed script.
- 144 generated MOSPL leather product records using real product patterns, prices, dimensions, and image URLs from onlinemadras.com.

## Local Run

Flutter:

```bash
cd mospl
flutter pub get
flutter run
```

Backend:

```bash
cd backend
npm install
copy .env.example .env
npm start
```

Seed preview or Firestore seed:

```bash
cd backend
npm run seed
```

Without Firebase credentials the backend and app run with local in-memory seed data. Add Firebase service account credentials and a Firebase Web API key in `.env` for production auth/database use.

## Test Credentials

- Customer: `shopper@mospl.test` / `password123`
- Admin: `admin@mospl.test` / `password123`
- Razorpay test card: `4111 1111 1111 1111`

## Firestore Collections

`users`, `admins`, `products`, `categories`, `carts`, `wishlists`, `orders`, `order_items`, `addresses`, `payments`, `reviews`, `notifications`, `chatbot_messages`, `coupons`, `banners`, `inventory`, `returns`, `support_tickets`.

## API Prefix

All backend routes are under `/api`.

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `GET /api/auth/me`
- `PATCH /api/auth/profile`
- `GET /api/products`
- `GET /api/products/search`
- `GET /api/products/:productId`
- `POST /api/products`
- `PUT /api/products/:productId`
- `DELETE /api/products/:productId`
- `GET /api/categories`
- `GET /api/cart`
- `POST /api/cart/items`
- `PATCH /api/cart/items/:productId`
- `DELETE /api/cart/items/:productId`
- `GET /api/wishlist`
- `POST /api/wishlist/:productId`
- `DELETE /api/wishlist/:productId`
- `GET /api/orders`
- `POST /api/orders`
- `GET /api/orders/:orderId`
- `PATCH /api/orders/:orderId/status`
- `GET /api/addresses`
- `POST /api/addresses`
- `PATCH /api/addresses/:addressId`
- `DELETE /api/addresses/:addressId`
- `POST /api/payments/create-order`
- `POST /api/payments/verify`
- `GET /api/payments/history`
- `POST /api/payments/:orderId/retry`
- `GET /api/reviews`
- `GET /api/reviews/product/:productId`
- `POST /api/reviews`
- `GET /api/notifications`
- `POST /api/notifications`
- `PATCH /api/notifications/:notificationId/read`
- `POST /api/chatbot/message`
- `GET /api/chatbot/history`
- `GET /api/coupons`
- `POST /api/coupons`
- `PATCH /api/coupons/:code`
- `GET /api/banners`
- `POST /api/banners`
- `PATCH /api/banners/:bannerId`
- `GET /api/inventory`
- `PATCH /api/inventory/:productId`
- `GET /api/returns`
- `POST /api/returns`
- `PATCH /api/returns/:returnId`
- `GET /api/support-tickets`
- `POST /api/support-tickets`
- `PATCH /api/support-tickets/:ticketId`
- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `GET /api/admin/analytics`

## Collaborative GitHub Actions & Self-Hosted Runner
The GitHub Actions workflow has been configured to use a self-hosted Windows runner. The E2E tests execute locally using the collaborator account (`1923247102.simats@saveetha.com`) configured for git pushes.

