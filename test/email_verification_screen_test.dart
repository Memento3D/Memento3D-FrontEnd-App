import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/auth/data/models/email_verification_result.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/mock_email_verification_service.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/email_verification_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

class _Service implements EmailVerificationService {
  Future<EmailVerificationResult> Function(String) verify = (_) async =>
      EmailVerificationResult.success;
  Future<EmailResendResult> Function(String) send = (_) async =>
      const EmailResendResult.sent();
  int resendCount = 0;

  @override
  Future<EmailVerificationResult> verifyToken(String token) => verify(token);
  @override
  Future<EmailResendResult> resend(String email) {
    resendCount++;
    return send(email);
  }
}

Widget _app(
  EmailVerificationState state, {
  String locale = 'vi',
  double scale = 1,
  VoidCallback? onContinue,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: EmailVerificationScreen(state: state, onContinue: onContinue ?? () {}),
);

final _resend = find.byKey(const ValueKey('emailResendButton'));

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
}

void main() {
  testWidgets('waiting shows target email, instructions and enabled resend', (
    tester,
  ) async {
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: const MockEmailVerificationService(),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    expect(find.text('bach@example.com'), findsOneWidget);
    expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
    expect(find.text('Đang chờ xác thực...'), findsOneWidget);
    expect(tester.widget<FilledButton>(_resend).onPressed, isNotNull);
    expect(state.retryAt, isNull);
    await tester.pump(const Duration(seconds: 3));
    expect(state.status, EmailVerificationStatus.waiting);
  });

  testWidgets('resend loading prevents duplicates and shows success', (
    tester,
  ) async {
    final pending = Completer<EmailResendResult>();
    final service = _Service()..send = (_) => pending.future;
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: service,
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await _reveal(tester, _resend);
    await tester.tap(_resend);
    await tester.tap(_resend);
    await tester.pump();
    expect(service.resendCount, 1);
    expect(find.text('Đang gửi...'), findsOneWidget);
    expect(tester.widget<FilledButton>(_resend).onPressed, isNull);
    pending.complete(const EmailResendResult.sent());
    await tester.pump();
    expect(
      find.textContaining('Email xác thực mới đã được gửi.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(_resend).onPressed, isNotNull);
  });

  testWidgets('resend failure offers another attempt', (tester) async {
    final service = _Service()..send = (_) async => throw StateError('offline');
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: service,
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await _reveal(tester, _resend);
    await tester.tap(_resend);
    await tester.pump();
    expect(find.text('Chưa thể gửi email. Vui lòng thử lại.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_resend).onPressed, isNotNull);
    service.send = (_) async => const EmailResendResult.sent();
    await _reveal(tester, _resend);
    await tester.tap(_resend);
    await tester.pump();
    expect(state.feedback, EmailVerificationFeedback.resendSent);
  });

  testWidgets('deadline drives countdown and resume recalculates expiry', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 1, 1);
    final state = EmailVerificationState(
      email: 'bach@example.com',
      now: () => now,
      service: MockEmailVerificationService(
        resendOutcome: MockResendOutcome.rateLimited,
        retryAt: now.add(const Duration(seconds: 7)),
      ),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await _reveal(tester, _resend);
    await tester.tap(_resend);
    await tester.pump();
    expect(find.text('Gửi lại sau 7 giây'), findsOneWidget);
    expect(tester.widget<FilledButton>(_resend).onPressed, isNull);
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại sau 4 giây'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(state.remainingSeconds, 0);
    expect(find.text('Gửi lại email xác thực'), findsOneWidget);
    expect(tester.widget<FilledButton>(_resend).onPressed, isNotNull);
  });

  testWidgets('verifying hides resend and success continues once', (
    tester,
  ) async {
    final pending = Completer<EmailVerificationResult>();
    final service = _Service()..verify = (_) => pending.future;
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: service,
    );
    addTearDown(state.dispose);
    var continued = 0;
    await tester.pumpWidget(_app(state, onContinue: () => continued++));
    final work = state.verifyToken('private-token-never-render');
    await tester.pump();
    expect(find.text('Đang xác thực email...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_resend, findsNothing);
    expect(find.textContaining('private-token-never-render'), findsNothing);
    pending.complete(EmailVerificationResult.success);
    await work;
    await tester.pump();
    expect(find.text('Email đã được xác thực!'), findsOneWidget);
    expect(continued, 0);
    final button = find.widgetWithText(FilledButton, 'Tiếp tục');
    await _reveal(tester, button);
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(continued, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets(
    'invalid token offers recovery without losing rate-limit context',
    (tester) async {
      var now = DateTime.utc(2026, 1, 1);
      final state = EmailVerificationState(
        email: 'bach@example.com',
        now: () => now,
        service: MockEmailVerificationService(
          verification: MockVerificationOutcome.invalidOrExpired,
          resendOutcome: MockResendOutcome.rateLimited,
          retryAt: now.add(const Duration(minutes: 1)),
        ),
      );
      addTearDown(state.dispose);
      await state.verifyToken('invalid');
      await tester.pumpWidget(_app(state));
      expect(find.text('Liên kết không còn hiệu lực'), findsOneWidget);
      expect(find.text('Gửi email xác thực mới'), findsOneWidget);
      expect(tester.widget<FilledButton>(_resend).onPressed, isNotNull);
      await _reveal(tester, _resend);
      await tester.tap(_resend);
      await tester.pump();
      expect(find.text('Liên kết không còn hiệu lực'), findsOneWidget);
      expect(state.status, EmailVerificationStatus.rateLimited);
      now = now.add(const Duration(minutes: 1));
      state.refreshTime();
      await tester.pump();
      expect(find.text('Gửi email xác thực mới'), findsOneWidget);
      expect(state.status, EmailVerificationStatus.invalidOrExpired);
    },
  );

  testWidgets('network failure keeps waiting and exposes verification retry', (
    tester,
  ) async {
    final service = _Service()
      ..verify = (_) async => throw StateError('offline');
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: service,
    );
    addTearDown(state.dispose);
    await state.verifyToken('private');
    await tester.pumpWidget(_app(state));
    expect(find.text('Liên kết không còn hiệu lực'), findsNothing);
    expect(find.textContaining('Chưa thể kiểm tra liên kết.'), findsOneWidget);
    expect(find.text('Đang chờ xác thực...'), findsOneWidget);
    service.verify = (_) async => EmailVerificationResult.success;
    final retry = find.widgetWithText(OutlinedButton, 'Thử lại');
    await _reveal(tester, retry);
    await tester.tap(retry);
    await tester.pump();
    expect(find.text('Email đã được xác thực!'), findsOneWidget);
  });

  for (final locale in ['vi', 'en']) {
    testWidgets(
      '$locale fits narrow mobile with enlarged text in every phase',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _Service();
        final state = EmailVerificationState(
          email: 'bach@example.com',
          service: service,
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(_app(state, locale: locale, scale: 2));
        expect(
          find.text(
            locale == 'en' ? 'Check your email' : 'Kiểm tra email của bạn',
          ),
          findsOneWidget,
        );
        await _reveal(tester, _resend);
        expect(tester.takeException(), isNull);
        service.send = (_) async => EmailResendResult.rateLimited(
          DateTime.now().add(const Duration(seconds: 9)),
        );
        await state.resend();
        await tester.pump();
        expect(tester.takeException(), isNull);
        final pending = Completer<EmailVerificationResult>();
        service.verify = (_) => pending.future;
        final work = state.verifyToken('test');
        await tester.pump();
        expect(_resend, findsNothing);
        expect(tester.takeException(), isNull);
        pending.complete(EmailVerificationResult.invalidOrExpired);
        await work;
        await tester.pump();
        await _reveal(tester, _resend);
        expect(tester.takeException(), isNull);
        service.verify = (_) async => EmailVerificationResult.success;
        await state.verifyToken('new');
        await tester.pump();
        expect(
          find.text(
            locale == 'en' ? 'Email verified!' : 'Email đã được xác thực!',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('disposing screen and state cancels active countdown', (
    tester,
  ) async {
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: MockEmailVerificationService(
        resendOutcome: MockResendOutcome.rateLimited,
        retryAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await tester.pumpWidget(_app(state));
    await state.resend();
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
