import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mospl/src/data/mospl_catalog.dart';
import 'package:mospl/src/services/api_client.dart';
import 'package:mospl/src/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mospl/src/models.dart';
import 'package:mospl/src/screens/checkout_screens.dart';
import 'package:mospl/src/screens/shop_screens.dart';
import 'package:mospl/src/widgets/widgets.dart';

void main() {
  testWidgets('MOSPL test harness loads', (WidgetTester tester) async {
    expect(1 + 1, 2);
  });

  test('bundled MOSPL catalog uses real local product images', () {
    final products = buildMosplProducts();
    expect(products.length, 18);
    expect(products.first.thumbnail, startsWith('assets/products/p'));
    expect(products.every((product) => product.galleryImages.isNotEmpty), isTrue);
    expect(products.every((product) => product.shortDescription.isNotEmpty), isTrue);
    expect(
      products.any((product) => product.thumbnail.endsWith('p4_4924639.jpg')),
      isTrue,
    );
  });

  test('ApiClient loads products from backend and absolutizes image URLs', () async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/products');
        return http.Response(
          jsonEncode({
            'ok': true,
            'products': [
              {
                'productId': 'MOSPL-TEST',
                'name': 'MOSPL Test Wallet',
                'category': 'Men Wallets',
                'subcategory': 'Classic Wallets',
                'price': 595,
                'oldPrice': 850,
                'discountPercentage': 30,
                'rating': 4.5,
                'reviewCount': 10,
                'stock': 25,
                'sku': 'MOSPL-TEST-SKU',
                'shortDescription': 'Backend product',
                'description': 'Backend product',
                'specifications': {'Material': 'Genuine leather'},
                'material': 'Genuine leather',
                'size': '90 mm x 120 mm',
                'color': 'Black',
                'deliveryInfo': 'Delivered by: 5 Days | Free Shipping',
                'returnPolicy': '7 day return',
                'warranty': '6 months',
                'thumbnail': '/static/products/p1_2186188.jpg',
                'galleryImages': ['/static/products/p1_2186188.jpg'],
                'isFeatured': true,
                'isTrending': true,
                'isBestSeller': true,
                'createdAt': '2026-05-23T09:00:00.000Z',
                'updatedAt': '2026-05-23T09:00:00.000Z',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final products = await client.fetchProducts();
 
    expect(products.single.productId, 'MOSPL-TEST');
    expect(products.single.thumbnail, 'http://127.0.0.1:8080/static/products/p1_2186188.jpg');
  });

  test('AppState sendChat fallback logic selects correct products', () async {
    final state = AppState();
    
    // For "women wallet"
    await state.sendChat('women wallet');
    // The last message is the reply
    final womenReply = state.chatMessages.last;
    expect(womenReply.isUser, isFalse);
    // It should recommend Women Wallets (MOSPL-OM-014 to MOSPL-OM-018)
    expect(womenReply.recommendedProductIds.isNotEmpty, isTrue);
    expect(womenReply.recommendedProductIds.every((id) => 
      id.startsWith('MOSPL-OM-014') || 
      id.startsWith('MOSPL-OM-015') || 
      id.startsWith('MOSPL-OM-016') || 
      id.startsWith('MOSPL-OM-017') || 
      id.startsWith('MOSPL-OM-018')
    ), isTrue);

    // For "coat wallet"
    await state.sendChat('coat wallet');
    final coatReply = state.chatMessages.last;
    expect(coatReply.isUser, isFalse);
    // It should recommend the coat wallet (p13: MOSPL-OM-013)
    expect(coatReply.recommendedProductIds, contains('MOSPL-OM-013'));
  });

  test('AppState visibleProducts robust query matching handles variations', () {
    final state = AppState();

    // Test 1: "womens wallet"
    state.updateSearch('womens wallet');
    expect(state.visibleProducts.isNotEmpty, isTrue);
    expect(state.visibleProducts.every((p) => p.category == 'Women Wallets'), isTrue);

    // Test 2: "mens wallet"
    state.updateSearch('mens wallet');
    expect(state.visibleProducts.isNotEmpty, isTrue);
    expect(state.visibleProducts.every((p) => p.category == 'Men Wallets'), isTrue);

    // Test 3: "men's wallet"
    state.updateSearch("men's wallet");
    expect(state.visibleProducts.isNotEmpty, isTrue);
    expect(state.visibleProducts.every((p) => p.category == 'Men Wallets'), isTrue);

    // Reset search
    state.updateSearch('');
  });

  testWidgets('TrackOrderScreen shows Icons.close for cancelled orders', (WidgetTester tester) async {
    final state = AppState();
    final cancelledOrder = AppOrder(
      orderId: 'ORD-CANCELLED',
      items: [CartLine(product: state.allProducts.first, quantity: 1)],
      address: const ShippingAddress(
        id: '1',
        name: 'User',
        phone: '123',
        line1: 'street',
        line2: '',
        city: 'chennai',
        state: 'TN',
        pincode: '600001',
      ),
      status: 'Cancelled',
      paymentStatus: 'Pending',
      paymentMethod: 'Razorpay',
      total: 595,
      createdAt: DateTime.now(),
    );
    state.orders.add(cancelledOrder);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: TrackOrderScreen(orderId: 'ORD-CANCELLED'),
        ),
      ),
    );

    // Verify that the TrackOrderScreen shows the receipt and order status
    expect(find.text('ORD-CANCELLED'), findsOneWidget);
    
    // Verify that it renders the Icons.close (wrong/cross symbol) for Confirmed step
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('AddAddressScreen validates phone number and pincode format', (WidgetTester tester) async {
    final state = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          home: AddAddressScreen(),
        ),
      ),
    );

    // Enter name
    await tester.enterText(find.widgetWithText(TextField, 'Full name'), 'Harish');
    
    // Enter invalid phone
    await tester.enterText(find.widgetWithText(TextField, 'Phone for delivery only'), '1234abc');
    await tester.enterText(find.widgetWithText(TextField, 'House / building / street'), '123 Street');
    await tester.enterText(find.widgetWithText(TextField, 'City'), 'Chennai');
    await tester.enterText(find.widgetWithText(TextField, 'State'), 'Tamil Nadu');
    await tester.enterText(find.widgetWithText(TextField, 'Pincode'), '600001');

    // Click save
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Address'));
    await tester.pump();

    // Verify error is shown
    expect(find.text('Invalid phone number'), findsOneWidget);

    // Fix phone, enter invalid pincode
    await tester.enterText(find.widgetWithText(TextField, 'Phone for delivery only'), '9876543210');
    await tester.enterText(find.widgetWithText(TextField, 'Pincode'), '600abc');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Address'));
    await tester.pump();

    // Verify error is shown
    expect(find.text('Invalid pincode'), findsOneWidget);

    // Fix pincode
    await tester.enterText(find.widgetWithText(TextField, 'Pincode'), '600001');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Address'));
    await tester.pump();

    // Verify it doesn't show invalid error
    expect(find.text('Invalid pincode'), findsNothing);
  });

  test('AppState sendChat off-topic fallback response echoes user input', () async {
    final state = AppState();
    
    // Send off-topic message "i wnt food"
    await state.sendChat('i wnt food');
    final foodReply = state.chatMessages.last;
    expect(foodReply.isUser, isFalse);
    expect(foodReply.text, contains('I cannot help with "i wnt food"'));
    
    // Send off-topic message "bye"
    await state.sendChat('bye');
    final byeReply = state.chatMessages.last;
    expect(byeReply.isUser, isFalse);
    expect(byeReply.text, contains('I cannot help with "bye"'));
  });

  test('StockLimitTextInputFormatter restricts input to 0-30', () {
    final formatter = StockLimitTextInputFormatter();

    // Valid inputs
    expect(
      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '25'),
      ).text,
      '25',
    );
    expect(
      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '30'),
      ).text,
      '30',
    );
    expect(
      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0'),
      ).text,
      '0',
    );
    expect(
      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      ).text,
      '',
    );

    // Invalid inputs
    expect(
      formatter.formatEditUpdate(
        const TextEditingValue(text: '25'),
        const TextEditingValue(text: '35'),
      ).text,
      '25', // rejected
    );
    expect(
      formatter.formatEditUpdate(
        const TextEditingValue(text: '3'),
        const TextEditingValue(text: '300'),
      ).text,
      '3', // rejected
    );
  });

  test('Product model customDiscount serialization and copyWith', () {
    final p = buildMosplProducts().first;
    expect(p.customDiscount, 0);

    final copied = p.copyWith(customDiscount: 20);
    expect(copied.customDiscount, 20);

    final map = copied.toMap();
    expect(map['customDiscount'], 20);

    final fromMap = Product.fromMap(map);
    expect(fromMap.customDiscount, 20);
  });

  test('AppState applyDynamicPriceToProduct pricing logic', () {
    final state = AppState();
    final p = buildMosplProducts().first.copyWith(oldPrice: 1000, price: 1000);

    state.dailyOffers = {
      'monday': 10,
      'tuesday': 15,
      'wednesday': 20,
      'thursday': 25,
      'friday': 30,
      'saturday': 35,
      'sunday': 40,
    };

    final days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final weekday = DateTime.now().weekday;
    final dayName = days[weekday % 7];
    final expectedDiscount = state.dailyOffers[dayName]!;

    final dynamicProduct = state.applyDynamicPriceToProduct(p);
    expect(dynamicProduct.discountPercentage, expectedDiscount);
    expect(dynamicProduct.price, 1000 - (1000 * expectedDiscount / 100).round());

    final customProduct = state.applyDynamicPriceToProduct(p.copyWith(customDiscount: 50));
    expect(customProduct.discountPercentage, 50);
    expect(customProduct.price, 500);
  });

  testWidgets('Rebuild test for Cart/Wishlist updates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = AppState();
    state.notificationsEnabled = false;
    
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final cartButton = find.byIcon(Icons.add_shopping_cart).first;
    await tester.ensureVisible(cartButton);
    await tester.pumpAndSettle();

    debugPrint('--- START CART TAP TEST ---');
    await tester.tap(cartButton);
    await tester.pump();
    debugPrint('--- END CART TAP TEST ---');

    debugPrint('--- START WISHLIST TAP TEST ---');
    final wishlistButton = find.byIcon(Icons.favorite_border).first;
    await tester.ensureVisible(wishlistButton);
    await tester.pumpAndSettle();
    await tester.tap(wishlistButton);
    await tester.pump();
    debugPrint('--- END WISHLIST TAP TEST ---');
  });
}
