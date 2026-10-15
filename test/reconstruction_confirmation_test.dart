import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/reconstruction_summary.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/mock_reconstruction_service.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/reconstruction_confirmation_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

const _mock = MockReconstructionService();
const _green = MockReconstructionService.greenSummary;
const _amber = MockReconstructionService.amberSummary;
final _primary = find.byType(FilledButton);
final _reminder = find.byKey(const ValueKey('reconstructionAmberReminder'));

Widget _app({
  ReconstructionSummary summary = _green,
  Future<void> Function(ReconstructionSummary)? submit,
  VoidCallback? success,
  bool routeHost = false,
  Locale locale = const Locale('vi'),
  double textScale = 1,
}) {
  Widget screen() => ReconstructionConfirmationScreen(
    summary: summary,
    onSubmit: submit ?? _mock.submit,
    onSubmissionSuccess: success ?? () {},
  );

  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: routeHost
        ? Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context)
                    .push<void>(MaterialPageRoute(builder: (_) => screen())),
                child: const Text('Open confirmation'),
              ),
            ),
          )
        : screen(),
  );
}

Future<void> _showActions(WidgetTester tester) async {
  await tester.ensureVisible(_primary);
  await tester.pumpAndSettle();
}

void main() {
  test('summary retains upstream status independently of score', () {
    const summary = ReconstructionSummary(
      qualifiedImageCount: 25,
      qualityScore: 85,
      qualityStatus: ReconstructionQualityStatus.amber,
      estimatedProcessingTime: Duration(seconds: 270),
    );
    expect(summary.qualifiedImageCount, 25);
    expect(summary.qualityScore, 85);
    expect(summary.qualityStatus, ReconstructionQualityStatus.amber);
    expect(summary.estimatedProcessingTime.inSeconds, 270);
  });

  testWidgets(
    'green values and resource notice render without Amber reminder',
    (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Ảnh đạt yêu cầu'), findsOneWidget);
      expect(find.text('86%'), findsOneWidget);
      expect(find.text('Tốt'), findsOneWidget);
      expect(find.text('~4 phút'), findsOneWidget);
      expect(find.text('Thời gian dự kiến'), findsOneWidget);
      expect(
        find.textContaining('Sau khi bắt đầu, quá trình không dễ hủy.'),
        findsOneWidget,
      );
      expect(_reminder, findsNothing);
      expect(find.text('Cảnh báo đã được xác nhận'), findsNothing);
    },
  );

  testWidgets('Amber reminder is informational and does not gate submission', (
    tester,
  ) async {
    var submitted = 0;
    await tester.pumpWidget(
      _app(summary: _amber, submit: (_) async => submitted++),
    );
    expect(_reminder, findsOneWidget);
    expect(
      find.textContaining('Bạn đã xác nhận cảnh báo chất lượng trước đó.'),
      findsOneWidget,
    );
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('Còn hạn chế'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.descendant(of: _reminder, matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );
    await _showActions(tester);
    expect(tester.widget<FilledButton>(_primary).onPressed, isNotNull);
    await tester.tap(_primary);
    await tester.pumpAndSettle();
    expect(submitted, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final action in ['secondary', 'header', 'system']) {
    testWidgets('$action back pops to the existing host', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        _app(routeHost: true, submit: (_) async => submitted++),
      );
      await tester.tap(find.text('Open confirmation'));
      await tester.pumpAndSettle();
      if (action == 'secondary') {
        await tester.ensureVisible(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(OutlinedButton));
      } else if (action == 'header') {
        await tester.tap(find.byTooltip('Quay lại'));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(ReconstructionConfirmationScreen), findsNothing);
      expect(find.text('Open confirmation'), findsOneWidget);
      expect(submitted, 0);
    });
  }

  testWidgets(
    'pending submission is single-flight and success runs afterwards',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      var successes = 0;
      ReconstructionSummary? received;
      await tester.pumpWidget(
        _app(
          submit: (summary) {
            received = summary;
            calls++;
            return pending.future;
          },
          success: () => successes++,
        ),
      );
      await _showActions(tester);
      // Both events happen before the disabled button has rebuilt.
      await tester.tap(_primary);
      await tester.tap(_primary);
      await tester.pump();
      expect(calls, 1);
      expect(received, same(_green));
      expect(successes, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang gửi…'), findsOneWidget);
      expect(tester.widget<FilledButton>(_primary).onPressed, isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(successes, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(_primary).onPressed, isNull);
      expect(find.text('Đã gửi'), findsOneWidget);
    },
  );

  testWidgets('failure stays on screen and retry can succeed', (tester) async {
    var attempts = 0;
    var successes = 0;
    await tester.pumpWidget(
      _app(
        submit: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('test submission failure');
        },
        success: () => successes++,
      ),
    );
    await _showActions(tester);
    await tester.tap(_primary);
    await tester.pumpAndSettle();
    expect(find.byType(ReconstructionConfirmationScreen), findsOneWidget);
    expect(find.textContaining('Chưa thể gửi yêu cầu.'), findsOneWidget);
    expect(successes, 0);
    expect(tester.widget<FilledButton>(_primary).onPressed, isNotNull);
    await _showActions(tester);
    await tester.tap(_primary);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(successes, 1);
    expect(find.textContaining('Chưa thể gửi yêu cầu.'), findsNothing);
  });

  testWidgets('mock submission invokes success without navigating itself', (
    tester,
  ) async {
    var successes = 0;
    await tester.pumpWidget(_app(success: () => successes++));
    await _showActions(tester);
    await tester.tap(_primary);
    await tester.pumpAndSettle();
    expect(successes, 1);
    expect(find.byType(ReconstructionConfirmationScreen), findsOneWidget);
  });

  testWidgets('leaving during submit does not call a disposed route callback', (
    tester,
  ) async {
    final pending = Completer<void>();
    var successes = 0;
    await tester.pumpWidget(
      _app(
        routeHost: true,
        submit: (_) => pending.future,
        success: () => successes++,
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await _showActions(tester);
    await tester.tap(_primary);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    pending.complete();
    await tester.pumpAndSettle();
    expect(successes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['vi', 'en']) {
    testWidgets('narrow $locale layout fits with enlarged text and loading', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<void>();
      await tester.pumpWidget(
        _app(
          summary: _amber,
          locale: Locale(locale),
          textScale: 2,
          submit: (_) => pending.future,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('32'), findsOneWidget);
      expect(find.text(locale == 'en' ? '~6 min' : '~6 phút'), findsOneWidget);
      await _showActions(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(_primary);
      await tester.pump();
      expect(tester.takeException(), isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
