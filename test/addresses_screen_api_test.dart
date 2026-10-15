import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/addresses_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates an address and refreshes the list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Map<String, dynamic>? created;
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/users/me/addresses');
        if (request.method == 'POST') {
          created = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
          return http.Response('{}', 201);
        }
        return http.Response(
          jsonEncode(
            created == null
                ? []
                : [
                    {'id': '1', ...created!},
                  ],
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await tester.pumpWidget(MaterialApp(home: AddressesScreen(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm địa chỉ'));
    await tester.pumpAndSettle();
    for (final entry in {
      'recipientName': 'An',
      'phone': '0123456789',
      'province': 'Hà Nội',
      'ward': 'Phường A',
      'streetAddress': '12 Phố A',
    }.entries) {
      final field = find.descendant(
        of: find.byKey(ValueKey('address-${entry.key}')),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu địa chỉ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu địa chỉ'));
    await tester.pumpAndSettle();
    expect(created?['recipientName'], 'An');
    expect(created?['streetAddress'], '12 Phố A');
    expect(find.textContaining('An · 0123456789'), findsOneWidget);
  });
}
