import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/core/widgets/m3_ui.dart';
import 'package:memento3d_frontend_app/features/orders/presentation/screens/checkout_screen.dart';
import 'package:memento3d_frontend_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _order({
  String status = 'PENDING',
  String paymentStatus = 'PENDING',
}) => {
  'id': 'o1',
  'orderCode': 'ORD-20261029-A1B2',
  'status': status,
  'paymentMethod': 'CASH',
  'paymentStatus': paymentStatus,
  'recipientName': 'An',
  'phone': '0123456789',
  'shippingAddress': '12 Phố A, Phường A, Hà Nội',
  'subtotal': 200000,
  'discountAmount': 0,
  'shippingFee': 0,
  'totalPrice': 200000,
  'paidAmount': 0,
  'remainingAmount': 200000,
  'itemCount': 1,
  'representativeProductName': 'Tượng mini',
  'items': [
    {
      'id': 'i1',
      'productName': 'Tượng mini',
      'unitPrice': 100000,
      'quantity': 2,
      'subtotal': 200000,
      'material': 'Resin',
    },
  ],
};

void main() {
  testWidgets('checkout posts the selected address and confirms the order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Map<String, dynamic>? placed;
    final client = ApiClient(
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/cart':
            return _json({
              'items': [
                {
                  'id': 'c1',
                  'productName': 'Tượng mini',
                  'unitPrice': 100000,
                  'quantity': 2,
                  'subtotal': 200000,
                },
              ],
              'subtotal': 200000,
              'discount': 0,
              'shippingFee': 0,
              'total': 200000,
            });
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
            placed = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
            return _json(_order(), 201);
          default:
            return _json({}, 404);
        }
      }),
    );

    await tester.pumpWidget(MaterialApp(home: CheckoutScreen(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('200.000 ₫'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Đặt hàng'));
    await tester.pumpAndSettle();

    expect(placed?['recipientName'], 'An');
    expect(placed?['shippingAddress'], '12 Phố A, Phường A, Hà Nội');
    expect(placed?['paymentMethod'], 'CASH');
    expect(placed?['paymentType'], 'COD');
    expect(placed?['idempotencyKey'], isNotNull);
    expect(find.text('Đặt hàng thành công'), findsOneWidget);
    expect(find.textContaining('ORD-20261029-A1B2'), findsOneWidget);
  });

  testWidgets('order history filters by status and opens the detail', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final requests = <String>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add('${request.url.path}?${request.url.query}');
        if (request.url.path == '/api/v1/orders/me/counts') {
          return _json({'PENDING': 1});
        }
        if (request.url.path == '/api/v1/orders/me') {
          return _json({
            'orders': [_order()],
            'page': 1,
            'limit': 10,
            'total': 1,
          });
        }
        if (request.url.path == '/api/v1/orders/o1') {
          return _json(_order());
        }
        return _json({}, 404);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: OrdersScreen(client: client)));
    await tester.pumpAndSettle();
    final pendingChip = find.widgetWithText(M3FilterChip, 'Chờ xác nhận');
    expect(pendingChip, findsOneWidget);
    expect(
      find.descendant(of: pendingChip, matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(pendingChip);
    await tester.pumpAndSettle();
    expect(requests.any((entry) => entry.contains('status=PENDING')), isTrue);

    await tester.tap(find.text('ORD-20261029-A1B2'));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái đơn hàng'), findsOneWidget);
    expect(find.text('Hủy đơn hàng'), findsOneWidget);
  });
}
