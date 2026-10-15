import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/orders/presentation/screens/print_order_config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('quotes a scan print and carries the quote into checkout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Map<String, dynamic>? quoteRequest;
    Map<String, dynamic>? placed;
    final client = ApiClient(
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/products':
            return _json({
              'content': [
                {
                  'id': 'p1',
                  'name': 'Tượng chân dung Premium',
                  'shortDescription': 'Resin SLA, hoàn thiện thủ công',
                  'price': 1200000,
                  'active': true,
                },
              ],
              'last': true,
            });
          case '/api/v1/customization-options':
            return _json([
              {
                'id': 'm1',
                'optionType': 'MATERIAL',
                'name': 'High-Detail Resin SLA',
                'additionalPrice': 150000,
                'isActive': true,
              },
            ]);
          case '/api/v1/pricing/quotes':
            quoteRequest = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            return _json({
              'id': 'q1',
              'productId': 'p1',
              'baseAmount': 1200000,
              'customizationAmount': 150000,
              'shippingAmount': 50000,
              'totalAmount': 1400000,
              'currency': 'VND',
            }, 201);
          case '/api/v1/users/me/addresses':
            return _json([
              {
                'id': 'a1',
                'recipientName': 'An',
                'phone': '0123456789',
                'formattedAddress': '12 Phố A, Phường A, Hà Nội',
                'isDefault': true,
              },
            ]);
          case '/api/v1/orders':
            placed = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            return _json({
              'id': 'o1',
              'orderCode': 'ORD-20261029-A1B2',
              'status': 'PENDING',
              'paymentMethod': 'CASH',
              'paymentStatus': 'PENDING',
              'totalPrice': 1400000,
            }, 201);
          default:
            return _json({}, 404);
        }
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: PrintOrderConfigScreen(scanId: 's1', client: client)),
    );
    await tester.pumpAndSettle();

    // No price is shown — and no order can be placed — before a server quote.
    expect(find.text('Nhận báo giá'), findsOneWidget);
    await tester.tap(find.text('Nhận báo giá'));
    await tester.pumpAndSettle();

    expect(quoteRequest?['productId'], 'p1');
    expect(quoteRequest?['sizeCm'], 15);
    expect((quoteRequest?['customization'] as Map)['size'], '15cm');
    expect(find.text('1.400.000 ₫'), findsWidgets);

    await tester.tap(find.text('Tiếp tục đặt hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận đơn hàng'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Đặt hàng'));
    await tester.pumpAndSettle();

    expect(placed?['scanId'], 's1');
    expect(placed?['quoteId'], 'q1');
    expect(placed?['totalPrice'], 1400000);
    expect(find.text('Đặt hàng thành công'), findsOneWidget);
  });
}
