import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('adds catalog item and updates its cart quantity', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var quantity = 0;
    final requests = <String>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/v1/products') {
          return http.Response(
            '{"content":[{"id":"p1","name":"Model","price":100,"active":true,"availability":"IN_STOCK"}],"last":true}',
            200,
          );
        }
        if (request.method == 'POST') {
          expect(jsonDecode(request.body), {'productId': 'p1', 'quantity': 1});
          quantity = 1;
        }
        if (request.method == 'PATCH') {
          expect(jsonDecode(request.body), {'quantity': 2});
          quantity = 2;
        }
        return http.Response(
          jsonEncode({
            'items': quantity == 0
                ? []
                : [
                    {
                      'id': 'c1',
                      'productName': 'Model',
                      'quantity': quantity,
                      'subtotal': 100 * quantity,
                    },
                  ],
            'total': 100 * quantity,
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(MaterialApp(home: ShopScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm vào giỏ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Giỏ hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(requests, contains('PATCH /api/v1/cart/items/c1'));
  });
}
