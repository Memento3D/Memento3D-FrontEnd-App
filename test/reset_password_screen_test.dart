import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PipelineOwner;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

import 'recovery_test_service.dart';

const _token = 'SUPER_SECRET_RESET_TOKEN_123';
Finder get _newField => find.byType(TextFormField).at(0);
Finder get _confirmField => find.byType(TextFormField).at(1);
Finder get _button => find.byType(FilledButton);

Widget _app(
  RecoveryTestService service, {
  String locale = 'vi',
  double scale = 1,
  Widget? home,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home ?? ResetPasswordScreen(resetToken: _token, service: service),
);
Future<void> _fill(
  WidgetTester tester,
  String password,
  String confirmation,
) async {
  await tester.ensureVisible(_newField);
  await tester.enterText(_newField, password);
  await tester.ensureVisible(_confirmField);
  await tester.enterText(_confirmField, confirmation);
}

Future<void> _submit(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.ensureVisible(_button);
  await tester.pumpAndSettle();
  await tester.tap(_button);
  await tester.pumpAndSettle();
}

void _noToken(WidgetTester tester) {
  expect(find.textContaining(_token), findsNothing);
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    expect(rich.text.toPlainText(), isNot(contains(_token)));
  }
  expect(find.bySemanticsLabel(RegExp(_token)), findsNothing);
  void inspectNode(SemanticsNode node) {
    final data = node.getSemanticsData();
    expect(data.label, isNot(contains(_token)));
    expect(data.value, isNot(contains(_token)));
    expect(data.hint, isNot(contains(_token)));
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
  expect(find.byType(SnackBar), findsNothing);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final locale in ['vi', 'en']) {
    testWidgets('$locale core copy and obscure defaults', (tester) async {
      await tester.pumpWidget(_app(RecoveryTestService(), locale: locale));
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      expect(find.text(strings.resetPasswordHeader), findsNWidgets(2));
      expect(
        find.text(locale == 'vi' ? 'Đặt lại mật khẩu' : 'Reset password'),
        findsNWidgets(2),
      );
      for (final text in [
        strings.resetPasswordTitle,
        strings.resetPasswordSupport,
        strings.resetPasswordNewPassword,
        strings.resetPasswordConfirmPassword,
        strings.resetPasswordCancel,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(
        find.text(
          locale == 'vi' ? 'Tạo mật khẩu mới' : 'Create a new password',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.obscureText),
        isTrue,
      );
      expect(
        find.byTooltip(strings.resetPasswordShowPassword),
        findsNWidgets(2),
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
    testWidgets('$locale visibility controls are independent and accessible', (
      tester,
    ) async {
      await tester.pumpWidget(_app(RecoveryTestService(), locale: locale));
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      final semantics = tester.ensureSemantics();
      await tester.ensureVisible(
        find.byTooltip(strings.resetPasswordShowPassword).first,
      );
      await tester.tap(find.byTooltip(strings.resetPasswordShowPassword).first);
      await tester.pumpAndSettle();
      var fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].obscureText, isFalse);
      expect(fields[1].obscureText, isTrue);
      expect(
        find.bySemanticsLabel(strings.resetPasswordHidePassword),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byTooltip(strings.resetPasswordShowPassword),
      );
      await tester.tap(find.byTooltip(strings.resetPasswordShowPassword));
      await tester.pumpAndSettle();
      fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.every((field) => !field.obscureText), isTrue);
      await tester.tap(find.byTooltip(strings.resetPasswordHidePassword).last);
      await tester.pumpAndSettle();
      fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[0].obscureText, isFalse);
      expect(fields[1].obscureText, isTrue);
      semantics.dispose();
    });
    testWidgets('$locale technical failure copy and retry', (tester) async {
      final service = RecoveryTestService()..resetThrows = true;
      await tester.pumpWidget(_app(service, locale: locale));
      final semantics = tester.ensureSemantics();
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await _fill(tester, 'Password1!', 'Password1!');
      await _submit(tester);
      expect(find.text(strings.resetPasswordTechnicalFailure), findsOneWidget);
      expect(find.text(strings.resetPasswordRetry), findsOneWidget);
      expect(
        find.textContaining('Sensitive reset backend message'),
        findsNothing,
      );
      _noToken(tester);
      service.resetThrows = false;
      await _submit(tester);
      expect(service.resetCalls, 2);
      expect(find.text(strings.resetPasswordSuccessTitle), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(ResetPasswordScreen))).canPop(),
        isFalse,
      );
      _noToken(tester);
      semantics.dispose();
    });
    testWidgets('$locale narrow enlarged layout and keyboard', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final service = RecoveryTestService()
        ..resetResult = ResetPasswordResult.recoverableFailure;
      await tester.pumpWidget(_app(service, locale: locale, scale: 2));
      await _fill(tester, 'Password1!', 'different');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(_confirmField);
      await tester.enterText(_confirmField, 'Password1!');
      await _submit(tester);
      expect(tester.takeException(), isNull);
      service.resetResult = ResetPasswordResult.accepted;
      await _submit(tester);
      expect(tester.takeException(), isNull);
    });
  }
  for (final empty in ['new', 'confirmation', 'both']) {
    testWidgets('empty $empty prevents submission', (tester) async {
      final service = RecoveryTestService();
      await tester.pumpWidget(_app(service));
      final strings = await AppLocalizations.delegate.load(const Locale('vi'));
      await _fill(
        tester,
        empty == 'confirmation' ? 'x' : '',
        empty == 'new' ? 'x' : '',
      );
      await _submit(tester);
      expect(service.resetCalls, 0);
      if (empty != 'confirmation') {
        expect(find.text(strings.resetPasswordNewRequired), findsOneWidget);
      }
      if (empty != 'new') {
        expect(find.text(strings.resetPasswordConfirmRequired), findsOneWidget);
      }
    });
  }
  testWidgets(
    'mismatch affects only confirmation and correcting it clears error',
    (tester) async {
      final service = RecoveryTestService();
      await tester.pumpWidget(_app(service));
      final strings = await AppLocalizations.delegate.load(const Locale('vi'));
      await _fill(tester, 'Password1!', 'wrong');
      await _submit(tester);
      expect(service.resetCalls, 0);
      expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
      expect(tester.state<FormFieldState<String>>(_newField).errorText, isNull);
      expect(
        tester.state<FormFieldState<String>>(_confirmField).errorText,
        strings.resetPasswordMismatch,
      );
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.ensureVisible(_confirmField);
      await tester.enterText(_confirmField, 'Password1!');
      await tester.pump();
      expect(find.text(strings.resetPasswordMismatch), findsNothing);
      await _submit(tester);
      expect(service.resetCalls, 1);
    },
  );
  testWidgets('editing new password also reevaluates confirmation mismatch', (
    tester,
  ) async {
    final service = RecoveryTestService();
    await tester.pumpWidget(_app(service));
    await _fill(tester, 'first', 'second');
    await _submit(tester);
    await tester.ensureVisible(_newField);
    await tester.enterText(_newField, 'second');
    await tester.pump();
    expect(
      tester.state<FormFieldState<String>>(_confirmField).errorText,
      isNull,
    );
    await _submit(tester);
    expect(service.resetCalls, 1);
  });
  for (final password in [' Password1! ', 'x', '   ', 'e\u0301']) {
    testWidgets(
      'exact matching value is sent without policy or normalization: ${password.length}',
      (tester) async {
        final service = RecoveryTestService();
        await tester.pumpWidget(_app(service));
        await _fill(tester, password, password);
        await _submit(tester);
        expect(service.resetCalls, 1);
        expect(service.resetArguments.single, (
          token: _token,
          newPassword: password,
        ));
      },
    );
  }
  for (final confirmation in ['Password1! ', ' Password1!', 'password1!']) {
    testWidgets('exact equality rejects differing whitespace or case', (
      tester,
    ) async {
      final service = RecoveryTestService();
      await tester.pumpWidget(_app(service));
      await _fill(tester, 'Password1!', confirmation);
      await _submit(tester);
      expect(service.resetCalls, 0);
      expect(tester.state<FormFieldState<String>>(_newField).errorText, isNull);
      expect(
        tester.state<FormFieldState<String>>(_confirmField).hasError,
        isTrue,
      );
    });
  }
  testWidgets(
    'pending request disables duplicate submit and hides token in all states',
    (tester) async {
      final service = RecoveryTestService()..resetPending = Completer();
      await tester.pumpWidget(_app(service));
      final semantics = tester.ensureSemantics();
      _noToken(tester);
      await _fill(tester, 'Password1!', 'Password1!');
      await _submit(tester);
      final strings = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(find.text(strings.resetPasswordSubmitting), findsOneWidget);
      expect(tester.widget<FilledButton>(_button).onPressed, isNull);
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        isTrue,
      );
      await tester.tap(_button);
      await tester.pump();
      expect(service.resetCalls, 1);
      _noToken(tester);
      service.resetPending!.complete(ResetPasswordResult.accepted);
      await tester.pumpAndSettle();
      _noToken(tester);
      semantics.dispose();
    },
  );
  testWidgets('accepted clears local controllers and does not navigate', (
    tester,
  ) async {
    final service = RecoveryTestService();
    await tester.pumpWidget(_app(service));
    await _fill(tester, 'Password1!', 'Password1!');
    final controllers = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!)
        .toList();
    await _submit(tester);
    expect(controllers.every((controller) => controller.text.isEmpty), isTrue);
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });
  testWidgets('recoverable outcome preserves values for retry', (tester) async {
    final service = RecoveryTestService()
      ..resetResult = ResetPasswordResult.recoverableFailure;
    await tester.pumpWidget(_app(service));
    await _fill(tester, ' Password1! ', ' Password1! ');
    await _submit(tester);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.controller!.text == ' Password1! '),
      isTrue,
    );
    service.resetResult = ResetPasswordResult.accepted;
    await _submit(tester);
    expect(service.resetCalls, 2);
    expect(service.resetArguments.last.newPassword, ' Password1! ');
  });
  for (final action in ['header', 'cancel', 'system']) {
    testWidgets('$action safely pops during pending request', (tester) async {
      final service = RecoveryTestService()..resetPending = Completer();
      await tester.pumpWidget(
        _app(service, home: const Scaffold(body: Text('Origin'))),
      );
      final context = tester.element(find.text('Origin'));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ResetPasswordScreen(resetToken: _token, service: service),
        ),
      );
      await tester.pumpAndSettle();
      await _fill(tester, 'Password1!', 'Password1!');
      await _submit(tester);
      if (action == 'system') {
        await tester.binding.handlePopRoute();
      } else {
        final strings = await AppLocalizations.delegate.load(
          const Locale('vi'),
        );
        final finder = action == 'header'
            ? find.byTooltip(strings.back)
            : find.text(strings.resetPasswordCancel);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
      }
      await tester.pumpAndSettle();
      service.resetPending!.complete(ResetPasswordResult.accepted);
      await tester.pumpAndSettle();
      expect(find.text('Origin'), findsOneWidget);
      expect(find.byType(ResetPasswordScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final locale in ['vi', 'en']) {
    testWidgets('$locale invalid/expired is generic and clears passwords', (
      tester,
    ) async {
      final service = RecoveryTestService()
        ..resetResult = ResetPasswordResult.invalidOrExpired;
      await tester.pumpWidget(_app(service, locale: locale));
      final semantics = tester.ensureSemantics();
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await _fill(tester, 'SecretPassword1!', 'SecretPassword1!');
      final controllers = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller!)
          .toList();
      await _submit(tester);
      expect(find.text(strings.resetPasswordInvalidTitle), findsOneWidget);
      expect(
        find.text(locale == 'vi' ? 'Quên mật khẩu' : 'Forgot password'),
        findsOneWidget,
      );
      expect(
        find.text(locale == 'vi' ? 'Liên kết đã hết hạn' : 'Link expired'),
        findsOneWidget,
      );
      expect(find.text(strings.resetPasswordHeader), findsNothing);
      expect(find.text(strings.resetPasswordInvalidBody), findsOneWidget);
      expect(find.text(strings.resetPasswordRequestNewLink), findsOneWidget);
      expect(find.text(strings.resetPasswordBackToLogin), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(
        controllers.every((controller) => controller.text.isEmpty),
        isTrue,
      );
      expect(find.textContaining('SecretPassword1!'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('SecretPassword1!')), findsNothing);
      _noToken(tester);
      semantics.dispose();
    });
    for (final result in [
      ResetPasswordResult.accepted,
      ResetPasswordResult.invalidOrExpired,
    ]) {
      testWidgets(
        '$locale $result terminal layout handles narrow enlarged text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final service = RecoveryTestService()..resetResult = result;
          await tester.pumpWidget(_app(service, locale: locale, scale: 2));
          await _fill(tester, 'Password1!', 'Password1!');
          await _submit(tester);
          final strings = await AppLocalizations.delegate.load(Locale(locale));
          await tester.ensureVisible(
            find.text(strings.resetPasswordBackToLogin),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final hasBoundary in [false, true]) {
      testWidgets(
        '$locale request new link preserves unrelated routes; boundary=$hasBoundary',
        (tester) async {
          final service = RecoveryTestService()
            ..resetResult = ResetPasswordResult.invalidOrExpired;
          await tester.pumpWidget(
            _app(
              service,
              locale: locale,
              home: const Scaffold(body: Text('Unrelated sentinel')),
            ),
          );
          final navigator = Navigator.of(
            tester.element(find.text('Unrelated sentinel')),
          );
          Route<void>? loginRoute;
          if (hasBoundary) {
            loginRoute = MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            );
            navigator.push(loginRoute);
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => ForgotPasswordScreen(service: service),
              ),
            );
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => ResetPasswordScreen(
                resetToken: _token,
                service: service,
                loginRoute: loginRoute,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final strings = await AppLocalizations.delegate.load(Locale(locale));
          await _fill(tester, 'Password1!', 'Password1!');
          await _submit(tester);
          await tester.ensureVisible(
            find.text(strings.resetPasswordRequestNewLink),
          );
          await tester.tap(find.text(strings.resetPasswordRequestNewLink));
          await tester.pumpAndSettle();
          expect(
            find.byType(ForgotPasswordScreen, skipOffstage: false),
            findsOneWidget,
          );
          expect(
            find.byType(ResetPasswordScreen, skipOffstage: false),
            findsNothing,
          );
          expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);
          expect(
            find.text('Unrelated sentinel', skipOffstage: false),
            findsOneWidget,
          );
          await tester.enterText(
            find.byType(TextFormField),
            'private@example.com',
          );
          await tester.ensureVisible(find.text(strings.forgotPasswordSubmit));
          await tester.tap(find.text(strings.forgotPasswordSubmit));
          await tester.pumpAndSettle();
          expect(service.calls, 1);
          expect(find.text(strings.forgotPasswordSentBody), findsOneWidget);
          expect(find.textContaining('private@example.com'), findsNothing);
          await tester.ensureVisible(
            find.text(strings.forgotPasswordBackToLogin),
          );
          await tester.tap(find.text(strings.forgotPasswordBackToLogin));
          await tester.pumpAndSettle();
          expect(find.byType(LoginScreen), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Unrelated sentinel'), findsOneWidget);
          expect(
            find.byType(ResetPasswordScreen, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.byType(ForgotPasswordScreen, skipOffstage: false),
            findsNothing,
          );
        },
      );
    }
  }
  for (final token in <String?>[null, '', '   ']) {
    testWidgets(
      'missing/empty token renders invalid presentation without service request: $token',
      (tester) async {
        final service = RecoveryTestService();
        await tester.pumpWidget(
          _app(
            service,
            home: ResetPasswordScreen(resetToken: token, service: service),
          ),
        );
        final strings = await AppLocalizations.delegate.load(
          const Locale('vi'),
        );
        expect(find.text(strings.resetPasswordInvalidTitle), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(service.resetCalls, 0);
      },
    );
  }

  for (final result in [
    ResetPasswordResult.accepted,
    ResetPasswordResult.invalidOrExpired,
  ]) {
    for (final hasBoundary in [false, true]) {
      for (final action in ['login', 'header', 'system']) {
        testWidgets(
          '$result via $action preserves sentinel; boundary=$hasBoundary',
          (tester) async {
            final service = RecoveryTestService()..resetResult = result;
            await tester.pumpWidget(
              _app(
                service,
                home: const Scaffold(body: Text('Unrelated sentinel')),
              ),
            );
            final navigator = Navigator.of(
              tester.element(find.text('Unrelated sentinel')),
            );
            Route<void>? loginRoute;
            if (hasBoundary) {
              loginRoute = MaterialPageRoute<void>(
                builder: (_) => const LoginScreen(),
              );
              navigator.push(loginRoute);
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => ForgotPasswordScreen(service: service),
                ),
              );
            }
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => ResetPasswordScreen(
                  resetToken: _token,
                  service: service,
                  loginRoute: loginRoute,
                ),
              ),
            );
            await tester.pumpAndSettle();
            await _fill(tester, 'Password1!', 'Password1!');
            await _submit(tester);
            final strings = await AppLocalizations.delegate.load(
              const Locale('vi'),
            );
            if (action == 'system') {
              await tester.binding.handlePopRoute();
            } else {
              final finder = action == 'header'
                  ? find.byTooltip(strings.back)
                  : find.text(strings.resetPasswordBackToLogin);
              await tester.ensureVisible(finder);
              await tester.tap(finder);
            }
            await tester.pumpAndSettle();
            expect(
              find.byType(LoginScreen, skipOffstage: false),
              findsOneWidget,
            );
            expect(
              find.byType(ForgotPasswordScreen, skipOffstage: false),
              findsNothing,
            );
            expect(
              find.byType(ResetPasswordScreen, skipOffstage: false),
              findsNothing,
            );
            expect(
              find.text('Unrelated sentinel', skipOffstage: false),
              findsOneWidget,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(find.text('Unrelated sentinel'), findsOneWidget);
            expect(
              find.byType(ResetPasswordScreen, skipOffstage: false),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final destination in [
    'success Login',
    'expired Login',
    'expired Forgot',
  ]) {
    for (final hasBoundary in [false, true]) {
      testWidgets(
        'rapid terminal actions create only one $destination; boundary=$hasBoundary',
        (tester) async {
          final service = RecoveryTestService()
            ..resetResult = destination == 'success Login'
                ? ResetPasswordResult.accepted
                : ResetPasswordResult.invalidOrExpired;
          await tester.pumpWidget(
            _app(
              service,
              home: const Scaffold(body: Text('Unrelated sentinel')),
            ),
          );
          final navigator = Navigator.of(
            tester.element(find.text('Unrelated sentinel')),
          );
          Route<void>? loginRoute;
          if (hasBoundary) {
            loginRoute = MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            );
            navigator.push(loginRoute);
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => ResetPasswordScreen(
                resetToken: _token,
                service: service,
                loginRoute: loginRoute,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _fill(tester, 'Password1!', 'Password1!');
          await _submit(tester);
          final strings = await AppLocalizations.delegate.load(
            const Locale('vi'),
          );
          final finder = find.text(
            destination == 'expired Forgot'
                ? strings.resetPasswordRequestNewLink
                : strings.resetPasswordBackToLogin,
          );
          final primary = find.ancestor(
            of: finder,
            matching: find.byType(FilledButton),
          );
          final VoidCallback trigger = primary.evaluate().isNotEmpty
              ? tester.widget<FilledButton>(primary).onPressed!
              : tester
                    .widget<TextButton>(
                      find.ancestor(
                        of: finder,
                        matching: find.byType(TextButton),
                      ),
                    )
                    .onPressed!;
          trigger();
          trigger();
          trigger();
          await tester.pumpAndSettle();
          expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);
          expect(
            find.byType(ForgotPasswordScreen, skipOffstage: false),
            destination == 'expired Forgot' ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(ResetPasswordScreen, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.text('Unrelated sentinel', skipOffstage: false),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
