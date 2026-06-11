import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mospl/src/data/mospl_catalog.dart';
import 'package:mospl/src/services/api_client.dart';

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
}
