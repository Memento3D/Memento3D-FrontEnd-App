import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_context.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_outcome.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/quality_override_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/quality_risk_details_sheet.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

import 'support/fake_quality_override_repository.dart';

QualityOverrideContext _input({
  QualityClassification classification = QualityClassification.amber,
  String scanId = 'scan',
  String runId = 'run',
  int affected = 6,
}) => QualityOverrideContext(
  scanId: scanId,
  qualityRunId: runId,
  classification: classification,
  qualifiedImageCount: 42,
  affectedImageCount: affected,
  overallQualityPercentage: 78,
);

class _Harness {
  final repository = FakeQualityOverrideRepository();
  final input = ValueNotifier(_input());
  int successes = 0;
  int backs = 0;

  Widget app({String locale = 'en', double scale = 1}) => MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: ValueListenableBuilder(
      valueListenable: input,
      builder: (context, value, _) => QualityOverrideScreen(
        context: value,
        repository: repository,
        onOverrideSuccess: () => successes++,
        onBackToQualityReport: () => backs++,
      ),
    ),
  );
}

final _mainCta = find.byKey(const Key('quality-main-cta'));
final _sheetConfirm = find.byKey(const Key('quality-sheet-confirm'));
final _checkbox = find.byKey(const Key('quality-acknowledgement'));
final _card = find.byKey(const Key('quality-caution-card'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) => _tap(tester, _card);

Future<void> _acknowledge(WidgetTester tester) async {
  await _openSheet(tester);
  await _tap(tester, _checkbox);
  await _tap(tester, _sheetConfirm);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(_mainCta);
  await tester.pumpAndSettle();
  await tester.tap(_mainCta);
  await tester.pump();
}

void main() {
  late _Harness harness;
  setUp(() => harness = _Harness());
  tearDown(() => harness.input.dispose());

  Future<void> mount(
    WidgetTester tester, {
    String locale = 'en',
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness.app(locale: locale, scale: scale));
    await tester.pumpAndSettle();
  }

  testWidgets('initial main CTA is disabled', (tester) async {
    await mount(tester);
    expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
    await _tap(tester, _mainCta);
    expect(harness.repository.requestCount, 0);
  });

  testWidgets('summary and caution count come from context', (tester) async {
    harness.input.value = _input(affected: 9);
    await mount(tester);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('9 images need review'), findsOneWidget);
  });

  testWidgets(
    'caution card opens details with an unchecked checkbox and disabled confirmation',
    (tester) async {
      await mount(tester);
      await _openSheet(tester);
      expect(find.byType(QualityRiskDetailsSheet), findsOneWidget);
      expect(find.text('Check before continuing'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(_checkbox).value, isFalse);
      expect(tester.widget<FilledButton>(_sheetConfirm).onPressed, isNull);
      expect(harness.repository.requestCount, 0);
    },
  );

  testWidgets(
    'checking then dismissing leaves main CTA disabled and resets checkbox',
    (tester) async {
      await mount(tester);
      await _openSheet(tester);
      await _tap(tester, _checkbox);
      expect(tester.widget<FilledButton>(_sheetConfirm).onPressed, isNotNull);
      expect(harness.repository.requestCount, 0);
      await _tap(tester, find.byKey(const Key('quality-sheet-close')));
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
      await _openSheet(tester);
      expect(tester.widget<CheckboxListTile>(_checkbox).value, isFalse);
    },
  );

  testWidgets(
    'sheet confirmation acknowledges and enables main CTA without submitting',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      expect(find.byType(QualityRiskDetailsSheet), findsNothing);
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNotNull);
      expect(harness.repository.requestCount, 0);
      await _openSheet(tester);
      expect(tester.widget<CheckboxListTile>(_checkbox).value, isTrue);
    },
  );

  testWidgets(
    'submission shows progress and disables duplicate taps and back controls',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      expect(find.text('Confirming…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('quality-header-back')))
            .onPressed,
        isNull,
      );
      await tester.tap(_mainCta);
      await tester.pump();
      expect(harness.repository.requestCount, 1);
      expect(harness.successes, 0);
      harness.repository.complete(0, QualityOverrideOutcome.success);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'success invokes callback exactly once across rebuilds and revisits',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      harness.repository.complete(0, QualityOverrideOutcome.success);
      await tester.pumpAndSettle();
      expect(harness.successes, 1);
      expect(_mainCta, findsNothing);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      harness.input.value = _input(runId: 'other');
      await tester.pumpAndSettle();
      harness.input.value = _input();
      await tester.pumpAndSettle();
      expect(harness.successes, 1);
      expect(_mainCta, findsNothing);
      expect(harness.repository.requestCount, 1);
    },
  );

  testWidgets('one header back and secondary back invoke caller callback', (
    tester,
  ) async {
    await mount(tester);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await _tap(tester, find.byKey(const Key('quality-header-back')));
    expect(harness.backs, 1);
    await _tap(tester, find.byKey(const Key('quality-back-to-report')));
    expect(harness.backs, 2);
    expect(harness.repository.requestCount, 0);
  });

  testWidgets('system back uses caller callback', (tester) async {
    await mount(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(harness.backs, 1);
  });

  testWidgets('caution card opens from keyboard focus', (tester) async {
    await mount(tester);
    final label = find.text('6 images need review');
    await tester.ensureVisible(label);
    Focus.of(tester.element(label)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(QualityRiskDetailsSheet), findsOneWidget);
    expect(harness.repository.requestCount, 0);
  });

  testWidgets('barrier dismissal does not acknowledge checked sheet', (
    tester,
  ) async {
    await mount(tester);
    await _openSheet(tester);
    await _tap(tester, _checkbox);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(QualityRiskDetailsSheet), findsNothing);
    expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
    await _openSheet(tester);
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isFalse);
  });

  testWidgets('system back is disabled during submission', (tester) async {
    await mount(tester);
    await _acknowledge(tester);
    await _submit(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(harness.backs, 0);
    harness.repository.complete(0, QualityOverrideOutcome.success);
    await tester.pumpAndSettle();
  });

  testWidgets('sheet remains usable with keyboard inset and safe areas', (
    tester,
  ) async {
    await mount(tester, locale: 'vi');
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPadding);
    await tester.pumpAndSettle();
    await _acknowledge(tester);
    expect(tester.widget<FilledButton>(_mainCta).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rejection removes continuation and offers caller-owned recovery',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      harness.repository.complete(0, QualityOverrideOutcome.rejected);
      await tester.pumpAndSettle();
      expect(find.text('Cannot continue with these images'), findsOneWidget);
      expect(_mainCta, findsNothing);
      expect(_card, findsNothing);
      expect(harness.successes, 0);
      await _tap(tester, find.text('Go back to the quality report'));
      expect(harness.backs, 1);
      harness.input.value = _input();
      await tester.pumpAndSettle();
      expect(_mainCta, findsNothing);
      expect(harness.repository.requestCount, 1);
    },
  );

  testWidgets(
    'recoverable failure keeps acknowledgement and allows explicit retry',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      harness.repository.complete(0, QualityOverrideOutcome.recoverableFailure);
      await tester.pumpAndSettle();
      expect(find.text('Try confirmation again'), findsOneWidget);
      expect(find.byType(QualityOverrideScreen), findsOneWidget);
      expect(harness.successes, 0);
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNotNull);
      await _submit(tester);
      expect(harness.repository.requestCount, 2);
      harness.repository.complete(1, QualityOverrideOutcome.success);
      await tester.pumpAndSettle();
      expect(harness.successes, 1);
    },
  );

  testWidgets(
    'repository exception never exposes private details or invokes success',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      harness.repository.fail(0, Exception('HTTP 403 private endpoint'));
      await tester.pumpAndSettle();
      expect(find.textContaining('HTTP 403'), findsNothing);
      expect(find.text('Try confirmation again'), findsOneWidget);
      expect(harness.successes, 0);
    },
  );

  for (final input in [
    _input(classification: QualityClassification.red),
    _input(classification: QualityClassification.green),
    _input(classification: QualityClassification.unknown),
    _input(scanId: ''),
    _input(runId: ' '),
  ]) {
    testWidgets(
      'ineligible ${input.classification}/${input.scanId}/${input.qualityRunId} cannot bypass controller',
      (tester) async {
        harness.input.value = input;
        await mount(tester);
        expect(_mainCta, findsNothing);
        expect(_card, findsNothing);
        expect(
          find.text('Please return to the quality report'),
          findsOneWidget,
        );
        expect(harness.repository.requestCount, 0);
        expect(harness.successes, 0);
      },
    );
  }

  testWidgets('missing image data renders clean placeholders', (tester) async {
    await mount(tester);
    await _openSheet(tester);
    expect(
      find.byKey(const Key('quality-image-placeholder-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('quality-image-placeholder-2')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final count in [1, 2, 3, 4, 6, 9]) {
    testWidgets('affected preview represents $count images', (tester) async {
      harness.input.value = _input(affected: count);
      await mount(tester);
      await _openSheet(tester);
      for (var index = 0; index < 3; index++) {
        expect(
          find.byKey(ValueKey('quality-image-placeholder-$index')),
          index < count ? findsOneWidget : findsNothing,
        );
      }
      final strings = AppLocalizations.of(tester.element(_checkbox))!;
      expect(find.text(strings.photoNumber(1)), findsOneWidget);
      if (count > 3) {
        expect(find.text('+${count - 2}'), findsOneWidget);
        expect(find.text(strings.photoNumber(3)), findsNothing);
        final semantics = tester.widget<Semantics>(
          find
              .ancestor(
                of: find.byKey(const Key('quality-image-placeholder-2')),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semantics.properties.label,
          strings.qualityAdditionalAffectedImages(count - 2),
        );
      } else {
        expect(find.textContaining('+'), findsNothing);
        expect(find.text(strings.photoNumber(count)), findsOneWidget);
      }
      expect(find.byType(Image), findsNothing);
      expect(harness.repository.requestCount, 0);
    });
  }

  testWidgets('acknowledgement label, row and checkbox toggle once', (
    tester,
  ) async {
    await mount(tester);
    await _openSheet(tester);
    final label = find.byKey(const Key('quality-acknowledgement-label'));
    await _tap(tester, label);
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isTrue);
    expect(tester.widget<FilledButton>(_sheetConfirm).onPressed, isNotNull);
    await _tap(tester, label);
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isFalse);
    final control = find.descendant(
      of: _checkbox,
      matching: find.byType(Checkbox),
    );
    await _tap(tester, control);
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isTrue);
    await _tap(tester, control);
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isFalse);
    await tester.ensureVisible(_checkbox);
    await tester.pumpAndSettle();
    final row = tester.getRect(_checkbox);
    expect(row.height, greaterThanOrEqualTo(48));
    await tester.tapAt(Offset(row.right - 2, row.center.dy));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isTrue);
    final strings = AppLocalizations.of(tester.element(_checkbox))!;
    await _tap(tester, find.text(strings.qualityAcknowledgementHint));
    expect(tester.widget<CheckboxListTile>(_checkbox).value, isTrue);
    expect(harness.repository.requestCount, 0);
    await _tap(tester, find.byKey(const Key('quality-sheet-close')));
    expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
  });

  testWidgets('zero affected images renders localized empty preview', (
    tester,
  ) async {
    harness.input.value = _input(affected: 0);
    await mount(tester);
    expect(find.text('Review quality warnings'), findsOneWidget);
    await _openSheet(tester);
    expect(find.text('No affected images to preview.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['en', 'vi']) {
    testWidgets('$locale renders main screen and sheet', (tester) async {
      await mount(tester, locale: locale);
      expect(
        find.text(locale == 'en' ? 'Confirm risks' : 'Xác nhận rủi ro'),
        findsOneWidget,
      );
      await _openSheet(tester);
      expect(
        find.text(
          locale == 'en'
              ? 'Check before continuing'
              : 'Kiểm tra trước khi tiếp tục',
        ),
        findsOneWidget,
      );
      await _tap(tester, _checkbox);
      await _tap(tester, _sheetConfirm);
      expect(
        find.text(
          locale == 'en' ? 'Confirm and continue' : 'Xác nhận và tiếp tục',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final layout in [
    (const Size(320, 640), 1.0),
    (const Size(390, 844), 2.0),
    (const Size(320, 640), 2.5),
    (const Size(844, 390), 1.0),
    (const Size(844, 390), 2.0),
    (const Size(390, 1000), 1.0),
  ]) {
    testWidgets(
      'screen and sheet fit ${layout.$1} at text scale ${layout.$2}',
      (tester) async {
        await mount(tester, locale: 'vi', size: layout.$1, scale: layout.$2);
        expect(tester.takeException(), isNull);
        await _acknowledge(tester);
        expect(tester.widget<FilledButton>(_mainCta).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('replacing context clears acknowledgement', (tester) async {
    await mount(tester);
    await _acknowledge(tester);
    harness.input.value = _input(runId: 'new');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
  });

  testWidgets(
    'open sheet cannot acknowledge replacement context or a revisited input',
    (tester) async {
      await mount(tester);
      final original = harness.input.value;
      await _openSheet(tester);
      await _tap(tester, _checkbox);
      harness.input.value = _input(runId: 'new');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(_sheetConfirm).onPressed, isNull);
      harness.input.value = original;
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(_sheetConfirm).onPressed, isNull);
      await _tap(tester, find.byKey(const Key('quality-sheet-close')));
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
    },
  );

  testWidgets(
    'stale successful request does not invoke callback for new context',
    (tester) async {
      await mount(tester);
      await _acknowledge(tester);
      await _submit(tester);
      harness.input.value = _input(runId: 'new');
      await tester.pumpAndSettle();
      harness.repository.complete(0, QualityOverrideOutcome.success);
      await tester.pumpAndSettle();
      expect(harness.successes, 0);
      expect(tester.widget<FilledButton>(_mainCta).onPressed, isNull);
    },
  );

  testWidgets('late success after screen disposal cannot invoke callback', (
    tester,
  ) async {
    await mount(tester);
    await _acknowledge(tester);
    await _submit(tester);
    await tester.pumpWidget(const SizedBox());
    harness.repository.complete(0, QualityOverrideOutcome.success);
    await tester.pumpAndSettle();
    expect(harness.successes, 0);
    expect(tester.takeException(), isNull);
  });
}
