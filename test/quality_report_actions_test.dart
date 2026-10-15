import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_report.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/fixtures/quality_report_fixtures.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/quality_report_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

const actionKeys = [
  'quality-report-start-reconstruction',
  'quality-report-recover-photos',
];
const english = ['Start reconstruction', 'Retake / Remove problem photos'];
const vietnamese = ['Bắt đầu tái tạo', 'Chụp bù / Xoá ảnh lỗi'];

Widget app(
  QualityReport report, {
  String locale = 'en',
  double scale = 1,
  VoidCallback? green,

  VoidCallback? red,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: QualityReportScreen(
    report: report,
    onStartReconstruction: green,
    onRecoverPhotos: red,
  ),
);

QualityReport supplied(QualityCategory category) => QualityReport(
  overallScore: category == QualityCategory.green ? 42 : 99,
  category: category,
  suggestion: 'Supplied suggestion only.',
  // Contradictory support/counts cannot change the category-selected action.
  support: QualityReportSupport.eligible,
  summary: const QualityReportSummary(
    checked: 1,
    passed: 0,
    warned: 0,
    failed: 1,
  ),
  photos: const [
    QualityPhotoResult(
      id: 'supplied-fail',
      assetPath: 'assets/images/polaroid_3d_hero.jpg',
      status: QualityPhotoStatus.fail,
    ),
  ],
);

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['en', 'vi']) {
    for (final category in QualityCategory.values) {
      testWidgets(
        '$locale $category compact summary and updated workflow actions',
        (tester) async {
          var starts = 0;
          var recoveries = 0;
          final report = supplied(category);
          await tester.pumpWidget(
            app(
              report,
              locale: locale,
              green: () => starts++,
              red: () => recoveries++,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Image), findsNothing);
          expect(find.byKey(const Key('quality-photo-grid')), findsNothing);
          expect(find.text(report.suggestion), findsNothing);
          expect(
            find.text(locale == 'vi' ? '1 Lỗi' : '1 Fail'),
            findsOneWidget,
          );
          final detailLabel = switch (category) {
            QualityCategory.green =>
              locale == 'vi' ? 'Xem chi tiết' : 'View details',
            QualityCategory.amber =>
              locale == 'vi' ? 'Xem chi tiết cảnh báo' : 'View warning details',
            QualityCategory.red =>
              locale == 'vi' ? 'Xem chi tiết lỗi' : 'View error details',
          };
          expect(find.text(detailLabel), findsOneWidget);
          final button = tester.widget<FilledButton>(
            find.byKey(const ValueKey('quality-report-start-reconstruction')),
          );
          expect(button.onPressed != null, category == QualityCategory.green);
          await tapKey(tester, 'quality-report-start-reconstruction');
          expect(starts, category == QualityCategory.green ? 1 : 0);
          if (category == QualityCategory.green) {
            expect(
              find.byKey(const ValueKey('quality-report-recover-photos')),
              findsNothing,
            );
          } else {
            expect(
              tester
                  .getTopLeft(
                    find.byKey(const ValueKey('quality-report-recover-photos')),
                  )
                  .dy,
              greaterThan(
                tester
                    .getTopLeft(
                      find.byKey(
                        const ValueKey('quality-report-start-reconstruction'),
                      ),
                    )
                    .dy,
              ),
            );
            await tapKey(tester, 'quality-report-recover-photos');
            expect(recoveries, 1);
            expect(starts, 0);
          }
          await tapKey(tester, 'quality-report-view-details');
          expect(
            find.text(
              locale == 'vi' ? 'Chi tiết chất lượng' : 'Quality details',
            ),
            findsOneWidget,
          );
          expect(find.text(report.suggestion), findsOneWidget);
          expect(
            find.text(
              locale == 'vi' ? 'Ảnh cần chú ý' : 'Photos needing attention',
            ),
            findsOneWidget,
          );
          expect(starts, category == QualityCategory.green ? 1 : 0);
          expect(find.text('Vẫn còn ảnh cần cải thiện'), findsNothing);
          expect(find.text('Vẫn còn ảnh lỗi'), findsNothing);
          await tester.tap(find.byKey(const Key('quality-details-close')));
          await tester.pumpAndSettle();
          expect(find.text(report.suggestion), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final category in QualityCategory.values) {
    testWidgets(
      '$category missing callbacks leaves workflow buttons disabled',
      (tester) async {
        await tester.pumpWidget(app(supplied(category)));
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        if (category != QualityCategory.green) {
          expect(
            tester
                .widget<OutlinedButton>(find.byType(OutlinedButton))
                .onPressed,
            isNull,
          );
        }
      },
    );
  }
  testWidgets(
    'Red reconstruction semantics disabled and reopening resets sheet expansion',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var starts = 0;
      await tester.pumpWidget(
        app(QualityReportFixtures.red, green: () => starts++),
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(
        find.byKey(const ValueKey('quality-report-start-reconstruction')),
      );
      expect(
        node,
        matchesSemantics(
          label: 'Start reconstruction',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      await tapKey(tester, 'quality-report-start-reconstruction');
      expect(starts, 0);
      await tapKey(tester, 'quality-report-view-details');
      await tapKey(tester, 'quality-photo-expand');
      expect(find.text('Collapse'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quality-details-close')));
      await tester.pumpAndSettle();
      await tapKey(tester, 'quality-report-view-details');
      expect(find.text('View all 2 photos'), findsOneWidget);
      semantics.dispose();
    },
  );
  for (final locale in ['en', 'vi']) {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 3.0),
    ]) {
      for (final report in [
        QualityReportFixtures.green,
        QualityReportFixtures.amber,
        QualityReportFixtures.red,
      ]) {
        testWidgets(
          '$locale ${report.category} main and sheet fit $size at scale $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              app(
                report,
                locale: locale,
                scale: scale,
                green: () {},
                red: () {},
              ),
            );
            await tester.pumpAndSettle();
            if (size.width == 390) {
              expect(
                find
                    .byKey(
                      const ValueKey('quality-report-start-reconstruction'),
                    )
                    .hitTestable(),
                findsOneWidget,
              );
              if (report.category != QualityCategory.green) {
                expect(
                  find
                      .byKey(const ValueKey('quality-report-recover-photos'))
                      .hitTestable(),
                  findsOneWidget,
                );
                expect(
                  tester
                      .getBottomLeft(
                        find.byKey(
                          const ValueKey('quality-report-recover-photos'),
                        ),
                      )
                      .dy,
                  lessThanOrEqualTo(size.height),
                );
              }
            }
            await tapKey(tester, 'quality-report-start-reconstruction');
            await tapKey(tester, 'quality-report-view-details');
            expect(tester.takeException(), isNull);
            await tapKey(tester, 'quality-photo-expand');
            await tester.ensureVisible(find.text(report.suggestion));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const Key('quality-details-close')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
