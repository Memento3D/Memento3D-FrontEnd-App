import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads notifications and refreshes after marking one read', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var read = false;
    final requests = <String>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.method == 'PATCH') {
          read = true;
          return http.Response('', 204);
        }
        return http.Response(
          '{"content":[{"id":"notice-1","title":"Ready","message":"Finished","read":$read}],"last":true}',
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: NotificationsScreen(client: client)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    expect(requests, [
      'GET /api/v1/notifications',
      'PATCH /api/v1/notifications/notice-1/read',
      'GET /api/v1/notifications',
    ]);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
