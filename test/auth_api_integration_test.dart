import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/data/models/email_verification_result.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_service.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/email_verification_service.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registration sends explicit consent', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/register');
        expect(jsonDecode(request.body), {
          'email': 'a@example.com',
          'password': 'password',
          'fullName': 'Name',
          'agreeTerms': true,
        });
        return http.Response('{"message":"ok"}', 201);
      }),
    );
    await AuthService(apiClient: client).register(
      email: ' a@example.com ',
      password: 'password',
      fullName: 'Name',
      agreeTerms: true,
    );
  });

  test('reset distinguishes an invalid token from a weak password', () async {
    var count = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/reset-password');
        expect(jsonDecode(request.body), {
          'token': 'token',
          'newPassword': 'password',
        });
        final code = count++ == 0 ? 'INVALID_RESET_TOKEN' : 'WEAK_PASSWORD';
        return http.Response(
          jsonEncode({'error': code, 'message': 'bad request'}),
          400,
        );
      }),
    );
    final service = ApiPasswordRecoveryService(client: client);
    expect(
      await service.resetPassword(token: 'token', newPassword: 'password'),
      ResetPasswordResult.invalidOrExpired,
    );
    expect(
      await service.resetPassword(token: 'token', newPassword: 'password'),
      ResetPasswordResult.recoverableFailure,
    );
  });

  test(
    'verification checks server response and resend handles rate limiting',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/verify')) {
            expect(jsonDecode(request.body), {'token': 'token'});
            return http.Response('{"verified":true}', 200);
          }
          expect(request.url.path, '/api/v1/auth/email/resend-verification');
          expect(jsonDecode(request.body), {'email': 'a@example.com'});
          return http.Response('{"error":"RATE_LIMIT_EXCEEDED"}', 429);
        }),
      );
      final service = ApiEmailVerificationService(client: client);
      expect(
        await service.verifyToken('token'),
        EmailVerificationResult.success,
      );
      expect((await service.resend(' a@example.com ')).retryAt, isNotNull);
    },
  );
}
