import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PipelineOwner;
import 'package:flutter/semantics.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';

import 'recovery_test_service.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

Widget _app({String locale = 'vi', Widget? home, double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home ?? const ForgotPasswordScreen(),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<State> _openFromLogin(WidgetTester tester) async {
  await tester.pumpWidget(_app(home: const LoginScreen()));
  await tester.pumpAndSettle();
  final loginState = tester.state(find.byType(LoginScreen));
  await _tap(tester, find.text('Forgot password?'));
  expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  expect(find.byType(SnackBar), findsNothing);
  return loginState;
}

void _expectEmailHidden(WidgetTester tester, String email) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    expect(
      text.data ?? text.textSpan?.toPlainText() ?? '',
      isNot(contains(email)),
    );
  }
  for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
    expect(text.text.toPlainText(), isNot(contains(email)));
  }
  var nodes = 0;
  void inspectNode(SemanticsNode node) {
    nodes++;
    final data = node.getSemanticsData();
    expect(data.label, isNot(contains(email)));
    expect(data.value, isNot(contains(email)));
    expect(data.hint, isNot(contains(email)));
    node.visitChildren((child) {
      inspectNode(child);
      return true;
    });
  }

  void inspectOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) inspectNode(root);
    owner.visitChildren(inspectOwner);
  }

  inspectOwner(tester.binding.rootPipelineOwner);
  expect(
    nodes,
    greaterThan(0),
    reason: 'A real pumped semantics tree is required',
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in ['vi', 'en']) {
    testWidgets('$locale entry copy and controls are localized', (
      tester,
    ) async {
      await tester.pumpWidget(_app(locale: locale));
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      for (final text in [
        strings.forgotPasswordHeader,
        strings.forgotPasswordTitle,
        strings.forgotPasswordSubtitle,
        strings.forgotPasswordEmailLabel,
        strings.forgotPasswordEmailHint,
        strings.forgotPasswordEmailHelper,
        strings.forgotPasswordSubmit,
        strings.forgotPasswordCancel,
        strings.forgotPasswordBackToLogin,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip(strings.back), findsOneWidget);
      expect(
        find.text(locale == 'vi' ? 'Quên mật khẩu' : 'Forgot password'),
        findsOneWidget,
      );
      expect(
        find.text(
          locale == 'vi' ? 'Gửi hướng dẫn đặt lại' : 'Send reset instructions',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('empty and whitespace email cannot invoke the submission seam', (
    tester,
  ) async {
    final emails = <String>[];
    await tester.pumpWidget(
      _app(
        home: ForgotPasswordScreen(
          service: RecoveryTestService(onEmail: emails.add),
        ),
      ),
    );
    final button = find.text('Gửi hướng dẫn đặt lại');
    await _tap(tester, button);
    expect(find.text('Vui lòng nhập địa chỉ email.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '   ');
    await _tap(tester, button);
    expect(emails, isEmpty);
  });

  testWidgets('valid email invokes the seam once with trimmed input', (
    tester,
  ) async {
    final emails = <String>[];
    await tester.pumpWidget(
      _app(
        home: ForgotPasswordScreen(
          service: RecoveryTestService(onEmail: emails.add),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), ' person@example.com ');
    await _tap(tester, find.text('Gửi hướng dẫn đặt lại'));
    expect(emails, ['person@example.com']);
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'unavailable default service shows recoverable technical failure',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.enterText(find.byType(TextFormField), 'person@example.com');
      await _tap(tester, find.text('Gửi hướng dẫn đặt lại'));
      final strings = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(find.text(strings.forgotPasswordTechnicalFailure), findsOneWidget);
      expect(find.text(strings.forgotPasswordRetry), findsOneWidget);
      expect(find.text(strings.forgotPasswordSentTitle), findsNothing);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in ['header', 'system', 'login', 'cancel']) {
    testWidgets('$action returns to the original Login route', (tester) async {
      final loginState = await _openFromLogin(tester);
      if (action == 'system') {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        await _tap(tester, switch (action) {
          'header' => find.byTooltip('Quay lại'),
          'login' => find.text('Quay lại đăng nhập'),
          _ => find.text('Hủy'),
        });
      }
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);
      expect(tester.state(find.byType(LoginScreen)), same(loginState));
      final context = tester.element(find.byType(LoginScreen));
      expect(Navigator.of(context).canPop(), isFalse);
    });
  }

  for (final locale in ['vi', 'en']) {
    testWidgets('$locale narrow layout supports enlarged text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(_app(locale: locale, scale: 2));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byType(TextFormField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '');
      await _tap(tester, find.byType(FilledButton));
      expect(tester.takeException(), isNull);
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await tester.ensureVisible(find.text(strings.forgotPasswordBackToLogin));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  for (final locale in ['vi', 'en']) {
    for (final scenario in ['existing account', 'unknown account']) {
      testWidgets('$locale $scenario has identical generic sent presentation', (
        tester,
      ) async {
        final service = RecoveryTestService();
        await tester.pumpWidget(
          _app(
            locale: locale,
            home: ForgotPasswordScreen(service: service),
          ),
        );
        final strings = await AppLocalizations.delegate.load(Locale(locale));
        await tester.enterText(
          find.byType(TextFormField),
          'secret-user@example.com',
        );
        await _tap(tester, find.text(strings.forgotPasswordSubmit));
        for (final text in [
          strings.forgotPasswordSentTitle,
          strings.forgotPasswordSentBody,
          strings.forgotPasswordSentSupport,
          strings.forgotPasswordGuidanceTitle,
          strings.forgotPasswordSpamGuidance,
          strings.forgotPasswordDeliveryGuidance,
          strings.forgotPasswordResend,
          strings.forgotPasswordBackToLogin,
        ]) {
          expect(find.text(text), findsOneWidget);
        }
        if (locale == 'vi') {
          expect(
            find.text(
              'Nếu email tồn tại, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.',
            ),
            findsOneWidget,
          );
          expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
        }
        expect(find.byType(TextFormField), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data ?? '').contains('secret-user@example.com'),
          ),
          findsNothing,
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpAndSettle();
        _expectEmailHidden(tester, 'secret-user@example.com');
        await _tap(tester, find.text(strings.forgotPasswordResend));
        expect(service.calls, 2);
        expect(find.text(strings.forgotPasswordSentBody), findsOneWidget);
        expect(find.textContaining('secret-user@example.com'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        _expectEmailHidden(tester, 'secret-user@example.com');
        semantics.dispose();
      });
    }
    testWidgets('$locale narrow sent layout supports enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          locale: locale,
          scale: 2,
          home: ForgotPasswordScreen(service: RecoveryTestService()),
        ),
      );
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await tester.enterText(
        find.byType(TextFormField),
        'secret-user@example.com',
      );
      await _tap(tester, find.text(strings.forgotPasswordSubmit));
      await tester.ensureVisible(find.text(strings.forgotPasswordBackToLogin));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pending submit and resend disable duplicate actions', (
    tester,
  ) async {
    final service = RecoveryTestService()..pending = Completer();
    await tester.pumpWidget(_app(home: ForgotPasswordScreen(service: service)));
    final strings = await AppLocalizations.delegate.load(const Locale('vi'));
    await tester.enterText(
      find.byType(TextFormField),
      'secret-user@example.com',
    );
    await tester.ensureVisible(find.text(strings.forgotPasswordSubmit));
    await tester.tap(find.text(strings.forgotPasswordSubmit));
    await tester.pump();
    expect(find.text(strings.forgotPasswordSubmitting), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text(strings.forgotPasswordSubmitting));
    expect(service.calls, 1);
    service.pending!.complete(ForgotPasswordResult.accepted);
    await tester.pumpAndSettle();
    service.pending = Completer();
    await tester.ensureVisible(find.text(strings.forgotPasswordResend));
    await tester.tap(find.text(strings.forgotPasswordResend));
    await tester.pump();
    expect(find.text(strings.forgotPasswordResending), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text(strings.forgotPasswordResending));
    expect(service.calls, 2);
    expect(find.textContaining('secret-user@example.com'), findsNothing);
    service.pending!.complete(ForgotPasswordResult.accepted);
    await tester.pumpAndSettle();
  });

  testWidgets('technical failure is generic and retry succeeds', (
    tester,
  ) async {
    final service = RecoveryTestService()..throws = true;
    await tester.pumpWidget(_app(home: ForgotPasswordScreen(service: service)));
    final strings = await AppLocalizations.delegate.load(const Locale('vi'));
    await tester.enterText(
      find.byType(TextFormField),
      'secret-user@example.com',
    );
    await _tap(tester, find.text(strings.forgotPasswordSubmit));
    expect(find.text(strings.forgotPasswordTechnicalFailure), findsOneWidget);
    expect(find.textContaining('Sensitive backend'), findsNothing);
    expect(find.text(strings.forgotPasswordRetry), findsOneWidget);
    service.throws = false;
    await _tap(tester, find.text(strings.forgotPasswordRetry));
    expect(find.text(strings.forgotPasswordSentBody), findsOneWidget);
    service.result = ForgotPasswordResult.recoverableFailure;
    await _tap(tester, find.text(strings.forgotPasswordResend));
    expect(find.text(strings.forgotPasswordTechnicalFailure), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('secret-user@example.com'), findsNothing);
    service.result = ForgotPasswordResult.accepted;
    await _tap(tester, find.text(strings.forgotPasswordResend));
    expect(find.text(strings.forgotPasswordTechnicalFailure), findsNothing);
  });

  testWidgets('sent back action pops to the original Login', (tester) async {
    await tester.pumpWidget(_app(home: const LoginScreen()));
    await tester.pumpAndSettle();
    final loginState = tester.state(find.byType(LoginScreen));
    Navigator.of(tester.element(find.byType(LoginScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(service: RecoveryTestService()),
      ),
    );
    await tester.pumpAndSettle();
    final strings = await AppLocalizations.delegate.load(const Locale('vi'));
    await tester.enterText(
      find.byType(TextFormField),
      'secret-user@example.com',
    );
    await _tap(tester, find.text(strings.forgotPasswordSubmit));
    await _tap(tester, find.text(strings.forgotPasswordBackToLogin));
    expect(tester.state(find.byType(LoginScreen)), same(loginState));
    expect(
      Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('leaving during a pending request is safe', (tester) async {
    final service = RecoveryTestService()..pending = Completer();
    await tester.pumpWidget(_app(home: ForgotPasswordScreen(service: service)));
    final strings = await AppLocalizations.delegate.load(const Locale('vi'));
    await tester.enterText(
      find.byType(TextFormField),
      'secret-user@example.com',
    );
    await _tap(tester, find.text(strings.forgotPasswordSubmit));
    await tester.pumpWidget(_app(home: const SizedBox()));
    service.pending!.complete(ForgotPasswordResult.accepted);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('accepted fixtures produce identical rendered text', (
    tester,
  ) async {
    List<String>? previous;
    for (final email in ['existing@example.com', 'unknown@example.com']) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _app(home: ForgotPasswordScreen(service: RecoveryTestService())),
      );
      final strings = await AppLocalizations.delegate.load(const Locale('vi'));
      await tester.enterText(find.byType(TextFormField), email);
      await _tap(tester, find.text(strings.forgotPasswordSubmit));
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .toList();
      expect(rendered.any((text) => text.contains(email)), isFalse);
      if (previous != null) expect(rendered, previous);
      previous = rendered;
    }
  });
  testWidgets(
    'Login Forgot guard blocks rapid callbacks and resets after return',
    (tester) async {
      await tester.pumpWidget(_app(home: const LoginScreen()));
      await tester.pumpAndSettle();
      final trigger = tester
          .widget<GestureDetector>(
            find
                .ancestor(
                  of: find.text('Forgot password?'),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .onTap!;
      trigger();
      trigger();
      trigger();
      await tester.pumpAndSettle();
      expect(
        find.byType(ForgotPasswordScreen, skipOffstage: false),
        findsOneWidget,
      );
      await _tap(tester, find.text('Hủy'));
      expect(
        find.byType(ForgotPasswordScreen, skipOffstage: false),
        findsNothing,
      );
      trigger();
      trigger();
      await tester.pumpAndSettle();
      expect(
        find.byType(ForgotPasswordScreen, skipOffstage: false),
        findsOneWidget,
      );
      await _tap(tester, find.text('Hủy'));
      expect(
        Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
        isFalse,
      );
    },
  );
  testWidgets('Login Forgot guard completion after Login disposal is safe', (
    tester,
  ) async {
    await _openFromLogin(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
