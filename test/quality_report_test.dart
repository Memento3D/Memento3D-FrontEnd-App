import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_report.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/fixtures/quality_report_fixtures.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/quality_report_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

Widget app(QualityReport report, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: QualityReportScreen(report: report),
    );

void main() {
  test(
    'report snapshots its photo list and fixtures have stable identities',
    () {
      final photos = [...QualityReportFixtures.green.photos];
      final report = QualityReport(
        overallScore: 42,
        category: QualityCategory.green,
        suggestion: 'Supplied',
        photos: photos,
      );
      photos.clear();
      expect(report.photos.length, 24);
      expect(() => report.photos.clear(), throwsUnsupportedError);
      expect(report.photos.map((photo) => photo.id).toSet().length, 24);
      expect(
        report.photos.where((p) => p.status == QualityPhotoStatus.pass).length,
        18,
      );
      expect(
        report.photos.where((p) => p.status == QualityPhotoStatus.warn).length,
        4,
      );
      expect(
        report.photos.where((p) => p.status == QualityPhotoStatus.fail).length,
        2,
      );
    },
  );

  for (final (category, label, color) in [
    (QualityCategory.green, 'Good', const Color(0xFF177449)),
    (QualityCategory.amber, 'Warning', const Color(0xFF946000)),
    (QualityCategory.red, 'Poor', const Color(0xFFBA1A1A)),
  ]) {
    testWidgets('$category trusts supplied category regardless of score', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final report = QualityReport(
        overallScore: category == QualityCategory.red ? 99 : 42,
        category: category,
        suggestion: '  Supplied suggestion.\nKeep exact spacing!  ',
        photos: const [],
      );
      await tester.pumpWidget(app(report));
      await tester.pumpAndSettle();
      expect(find.text('${report.overallScore}/100'), findsOneWidget);
      expect(find.text(report.suggestion), findsNothing);
      expect(
        find.bySemanticsLabel('Score: ${report.overallScore} out of 100'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(label), findsOneWidget);
      final badge = find.byKey(const Key('quality-report-category'));
      final text = tester.widget<Text>(
        find.descendant(of: badge, matching: find.text(label)),
      );
      expect(text.style!.color, color);
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: badge, matching: find.byType(Icon)),
            )
            .color,
        color,
      );
      expect(find.textContaining('blur', findRichText: true), findsNothing);
      expect(find.textContaining('lighting', findRichText: true), findsNothing);
      expect(find.text('Eligible'), findsNothing);
      // Phase C renders the matching action disabled without an injected callback.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('quality-report-view-details')));
      await tester.pumpAndSettle();
      expect(find.text(report.suggestion), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in ['en', 'vi']) {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 640), 2.0),
      (const Size(320, 640), 3.0),
    ]) {
      testWidgets('$locale fits $size at text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(QualityReportFixtures.green, locale: locale, scale: scale),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'vi' ? 'Báo Cáo Chất Lượng' : 'Quality Report'),
          findsOneWidget,
        );
        expect(
          find.text(locale == 'vi' ? 'Đủ điều kiện' : 'Eligible'),
          findsOneWidget,
        );
        expect(
          find.text(
            locale == 'vi' ? '24 ảnh đã được kiểm tra' : '24 photos checked',
          ),
          findsOneWidget,
        );
        expect(find.text('82/100'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final detail = find.byKey(const Key('quality-report-view-details'));
        await tester.ensureVisible(detail);
        await tester.pumpAndSettle();
        await tester.tap(detail);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(QualityReportFixtures.green.suggestion),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(QualityReportFixtures.green.suggestion),
          findsOneWidget,
        );
        await tester.drag(
          find.byKey(const Key('quality-details-scroll')),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        final bottom = tester
            .getBottomLeft(find.text(QualityReportFixtures.green.suggestion))
            .dy;
        expect(bottom, lessThanOrEqualTo(size.height));
        expect(bottom, greaterThan(0));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('summary displays supplied counts instead of counting photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        QualityReport(
          overallScore: 82.125,
          category: QualityCategory.green,
          suggestion: 'Exact supplied body',
          photos: const [],
          summary: const QualityReportSummary(
            checked: 24,
            passed: 18,
            warned: 4,
            failed: 2,
          ),
        ),
      ),
    );
    expect(find.text('82.125/100'), findsOneWidget);
    expect(find.text('24 photos checked'), findsOneWidget);
    expect(find.text('18 Pass'), findsOneWidget);
    expect(find.text('4 Warning'), findsOneWidget);
    expect(find.text('2 Fail'), findsOneWidget);
  });

  testWidgets('back affordance returns to the caller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    QualityReportScreen(report: QualityReportFixtures.red),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(QualityReportScreen), findsNothing);
  });
}
