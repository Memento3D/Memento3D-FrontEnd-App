import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/customization/data/customization_api.dart';
import 'package:memento3d_frontend_app/features/customization/presentation/custom_print_checkout_screen.dart';
import 'package:memento3d_frontend_app/features/orders/data/services/order_service.dart';
import 'package:memento3d_frontend_app/features/orders/presentation/screens/order_detail_screen.dart';

import 'customization_api_test.dart' as fixtures;

Map<String, dynamic> order(String feasibility) => {
  'id': 'order',
  'orderCode': 'ORDER',
  'status': 'PENDING',
  'paymentStatus': 'PENDING',
  'scanId': 'scan',
  'feasibilityStatus': feasibility,
  'totalAmount': feasibility == 'PENDING_REVIEW' ? 0 : 450000,
  'totalPrice': feasibility == 'PENDING_REVIEW' ? 0 : 450000,
  'currency': 'VND',
  'items': [
    {
      'id': 'item',
      'productNameSnapshot': 'Custom keepsake',
      'quantity': 1,
      'unitPrice': 0,
      'subtotal': 0,
      'customization': {'kind': 'CUSTOM_PRINT_V1'},
    },
  ],
};
http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> design() => {
  'status': 'READY',
  'revision': 1,
  'requestedHeightCm': 12,
  'assets': [
    {'name': 'Cap'},
  ],
  'reviewNotes': null,
  'downloadUrl': null,
};
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'custom checkout retries identical frozen revision without client prices',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final posts = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/orders') {
          posts.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
          return posts.length == 1
              ? json({'message': 'Response lost'}, 503)
              : json(order('PENDING_REVIEW'), 201);
        }
        if (request.url.path.endsWith('/custom-design')) return json(design());
        return json(order('PENDING_REVIEW'));
      });
      addTearDown(client.close);
      final raw = fixtures.scene();
      raw['customization'] = {
        ...fixtures.draft(),
        'revision': 1,
        'exists': true,
      };
      for (final asset in raw['assets'] as List) {
        asset['name'] = asset['assetVersionId'];
      }
      final scene = DesignScene.fromJson(raw);
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPrintCheckoutScreen(
            scene: scene,
            draft: scene.draft,
            client: ApiClient(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Customer');
      await tester.enterText(find.byType(TextFormField).at(1), '0901234567');
      await tester.enterText(find.byType(TextFormField).at(2), 'Demo address');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Gửi yêu cầu đặt sản xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi lại cùng yêu cầu'));
      await tester.pumpAndSettle();
      expect(posts.length, 2);
      expect(posts[0], posts[1]);
      expect(posts[0].containsKey('totalPrice'), false);
      expect(posts[0]['customizationRevision'], 1);
      expect(posts[0]['idempotencyKey'], startsWith('custom:'));
      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'workshop quote must be accepted before custom payment action appears',
    (tester) async {
      var accepted = false;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/accept-quote')) accepted = true;
        if (request.url.path.endsWith('/custom-design')) return json(design());
        return json(order(accepted ? 'ACCEPTED' : 'FEASIBLE'));
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailScreen(
            orderId: 'order',
            client: ApiClient(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsNothing);
    await tester.scrollUntilVisible(find.text('Đồng ý báo giá'),300,scrollable:find.byType(Scrollable).first);
      await tester.tap(find.text('Đồng ý báo giá'));
      await tester.pumpAndSettle();
      expect(accepted, true);
      expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('VNPAY uses server checkout and BE return verification, with no client amount', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/payments/vnpay/create');
      final body = jsonDecode(request.body) as Map;
      expect(body['orderId'], 'order');
      expect(body.containsKey('amount'), false);
      expect(body['returnUrl'], endsWith('/api/v1/payments/vnpay/return'));
      return json({'paymentUrl': 'https://sandbox.vnpayment.vn/checkout'});
    });
    addTearDown(client.close);
    await OrderService(client: ApiClient(client: client))
        .initiatePayment(orderId: 'order', paymentMethod: 'VNPAY');
  });
}
