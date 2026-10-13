import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clearAuthData();
    await AuthStorage.saveToken('stored-test-token');
  });
  tearDown(() async {
    ApiClient.onUnauthorized = null;
    await AuthStorage.clearAuthData();
  });
  List<http.MultipartFile> files() => [
    http.MultipartFile.fromString(
      'file',
      'photo-content',
      filename: 'original.jpg',
    ),
  ];

  test(
    'injected MockClient receives generated boundary, file and auth',
    () async {
      var calls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'POST');
          expect(request.url.path, '/multipart');
          expect(request.headers['authorization'], 'Bearer stored-test-token');
          final type = request.headers['content-type']!;
          expect(type, startsWith('multipart/form-data; boundary='));
          final boundary = type.split('boundary=').last;
          expect(request.body, contains('--$boundary'));
          expect(
            request.body,
            contains('name="file"; filename="original.jpg"'),
          );
          expect(request.body, contains('photo-content'));
          expect(request.body, contains('name="note"'));
          return http.Response('{"ok":true}', 201);
        }),
      );
      expect(
        await client.postMultipart(
          '/multipart',
          files: files(),
          fields: {'note': 'text'},
          headers: {'Content-Type': 'application/json'},
        ),
        {'ok': true},
      );
      expect(calls, 1);
    },
  );
  for (final method in ['GET', 'POST', 'PATCH', 'DELETE']) {
    test('$method JSON behavior remains unchanged', () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, method);
          expect(request.headers['content-type'], 'application/json');
          if (method == 'POST' || method == 'PATCH') {
            expect(jsonDecode(request.body), {'value': 1});
          }
          return http.Response('{"ok":true}', 200);
        }),
      );
      final result = switch (method) {
        'GET' => await api.get('/json'),
        'POST' => await api.post('/json', body: {'value': 1}),
        'PATCH' => await api.patch('/json', body: {'value': 1}),
        _ => await api.delete('/json'),
      };
      expect(result, {'ok': true});
    });
  }
  for (final status in [400, 401, 500]) {
    test('$status uses shared errors and 401 callback', () async {
      var unauthorized = 0, calls = 0;
      ApiClient.onUnauthorized = () => unauthorized++;
      final api = ApiClient(
        client: MockClient((request) async {
          calls++;
          return http.Response('{"message":"error"}', status);
        }),
      );
      await expectLater(
        api.postMultipart('/multipart', files: files()),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', status),
        ),
      );
      expect(unauthorized, status == 401 ? 1 : 0);
      expect(calls, 1);
    });
  }
  for (final body in ['', 'raw response']) {
    test(
      'successful empty/raw body retains shared decoding behavior: $body',
      () async {
        final api = ApiClient(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        expect(
          await api.postMultipart('/multipart', files: files()),
          body.isEmpty ? null : body,
        );
      },
    );
  }
  testWidgets('timeout covers stalled response body and never retries', (
    tester,
  ) async {
    final stalled = StreamController<List<int>>();
    var calls = 0;
    final api = ApiClient(
      client: _StreamingClient(() {
        calls++;
        return http.StreamedResponse(stalled.stream, 201);
      }),
    );
    final result = api.postMultipart(
      '/multipart',
      files: files(),
      token: 'explicit',
    );
    final assertion = expectLater(
      result,
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 408)
            .having((e) => e.errorCode, 'code', 'ERR-009'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    await assertion;
    expect(calls, 1);
    await stalled.close();
  });
}

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.response);
  final http.StreamedResponse Function() response;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      response();
}
