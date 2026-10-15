import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_report.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/fixtures/quality_report_fixtures.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/quality_report_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/quality_photo_section.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/quality_score_gauge.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

Widget app(
  QualityReport report, {
  String locale = 'en',
  double scale = 1,
  ValueChanged<QualityPhotoResult>? onSelected,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: QualityReportScreen(report: report, onPhotoSelected: onSelected),
);

QualityReport reportWith(List<QualityPhotoResult> photos) => QualityReport(
  overallScore: 42,
  category: QualityCategory.green,
  suggestion: 'Exact suggestion',
  photos: photos,
);

List<QualityPhotoTile> tiles(WidgetTester tester) =>
    tester.widgetList<QualityPhotoTile>(find.byType(QualityPhotoTile)).toList();

Future<void> toggle(WidgetTester tester) async {
  final button = find.byKey(const Key('quality-photo-expand'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> pumpDetails(WidgetTester tester, Widget widget) async {
  // Close any existing modal before replacing the supplied report.
  if (find.byKey(const Key('quality-details-close')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('quality-details-close')));
    await tester.pumpAndSettle();
  }
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  final details = find.byKey(const Key('quality-report-view-details'));
  await tester.ensureVisible(details);
  await tester.pumpAndSettle();
  await tester.tap(details);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Green defaults to original photos 19–24 and expands in source order without mutation',
    (tester) async {
      final report = QualityReportFixtures.green;
      final original = [...report.photos];
      await pumpDetails(tester, app(report, locale: 'vi'));
      await tester.pumpAndSettle();
      expect(tiles(tester).map((tile) => tile.number), [
        19,
        20,
        21,
        22,
        23,
        24,
      ]);
      expect(tiles(tester).map((tile) => tile.photo.status), [
        QualityPhotoStatus.warn,
        QualityPhotoStatus.warn,
        QualityPhotoStatus.warn,
        QualityPhotoStatus.warn,
        QualityPhotoStatus.fail,
        QualityPhotoStatus.fail,
      ]);
      expect(
        tiles(tester)
            .any((tile) => tile.photo.status == QualityPhotoStatus.pass),
        isFalse,
      );
      expect(find.text('Ảnh cần chú ý'), findsOneWidget);
      expect(find.text('6 ảnh'), findsOneWidget);
      expect(find.text('Xem tất cả 24 ảnh'), findsOneWidget);
      await toggle(tester);
      expect(
        tiles(tester).map((tile) => tile.number),
        List.generate(24, (i) => i + 1),
      );
      expect(tiles(tester).map((tile) => tile.photo), orderedEquals(original));
      expect(find.text('Thu gọn'), findsOneWidget);
      await toggle(tester);
      expect(tiles(tester).map((tile) => tile.number), [
        19,
        20,
        21,
        22,
        23,
        24,
      ]);
      for (var i = 0; i < original.length; i++) {
        expect(identical(report.photos[i], original[i]), isTrue);
      }
      expect(report.overallScore, 82);
      expect(report.category, QualityCategory.green);
      expect(find.text(report.suggestion), findsOneWidget);
      expect(find.text('18 Đạt', skipOffstage: false), findsOneWidget);
      expect(find.text('4 Cảnh báo', skipOffstage: false), findsOneWidget);
      expect(find.text('2 Lỗi', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final count in [2, 9]) {
    testWidgets('$count attention photos are all shown without a cap', (
      tester,
    ) async {
      final photos = List.generate(
        count,
        (i) => QualityPhotoResult(
          id: 'attention-$i',
          assetPath: 'assets/images/polaroid_3d_hero.jpg',
          status: i.isEven ? QualityPhotoStatus.warn : QualityPhotoStatus.fail,
        ),
      );
      await pumpDetails(tester, app(reportWith(photos)));
      await tester.pumpAndSettle();
      expect(tiles(tester).map((tile) => tile.photo), orderedEquals(photos));
      expect(find.text('$count photos'), findsOneWidget);
    });
  }

  testWidgets(
    'zero attention and empty reports can expand without invented results',
    (tester) async {
      final photos = [QualityReportFixtures.green.photos.first];
      await pumpDetails(tester, app(reportWith(photos)));
      await tester.pumpAndSettle();
      expect(tiles(tester), isEmpty);
      expect(find.text('0 photos'), findsOneWidget);
      expect(find.text('View all 1 photo'), findsOneWidget);
      await toggle(tester);
      expect(tiles(tester).single.photo, same(photos.first));
      await pumpDetails(tester, app(reportWith([])));
      await tester.pumpAndSettle();
      expect(find.text('View all 0 photos'), findsOneWidget);
      await toggle(tester);
      expect(tiles(tester), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filtered and expanded taps return the exact original result, including fallback',
    (tester) async {
      const path = 'assets/images/polaroid_3d_hero.jpg';
      const photos = [
        QualityPhotoResult(
          id: 'one',
          assetPath: path,
          status: QualityPhotoStatus.pass,
        ),
        QualityPhotoResult(
          id: 'two',
          assetPath: path,
          status: QualityPhotoStatus.warn,
        ),
        QualityPhotoResult(
          id: 'three',
          assetPath: path,
          status: QualityPhotoStatus.pass,
        ),
        QualityPhotoResult(
          id: 'four',
          assetPath: 'missing-photo.jpg',
          status: QualityPhotoStatus.fail,
        ),
      ];
      QualityPhotoResult? selected;
      await pumpDetails(
        tester,
        app(reportWith(photos), onSelected: (photo) => selected = photo),
      );
      await tester.pumpAndSettle();
      expect(tiles(tester).map((tile) => tile.number), [2, 4]);
      expect(find.text('Image unavailable'), findsOneWidget);
      final tile = find.byKey(const ValueKey('four'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      expect(selected, same(photos[3]));
      expect(
        find.descendant(of: tile, matching: find.text('Photo 4')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Fail')),
        findsOneWidget,
      );
      await toggle(tester);
      final first = find.byKey(const ValueKey('one'));
      await tester.ensureVisible(first);
      await tester.pumpAndSettle();
      await tester.tap(first);
      expect(selected, same(photos[0]));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'photo statuses have independent colors, text, icons and accessible identity',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpDetails(
        tester,
        app(QualityReportFixtures.amber, onSelected: (_) {}),
      );
      await tester.pumpAndSettle();
      await toggle(tester);
      for (final (id, number, label, color) in [
        ('amber-pass', 1, 'Pass', const Color(0xFF177449)),
        ('amber-warn', 2, 'Warning', const Color(0xFF946000)),
        ('amber-fail', 3, 'Fail', const Color(0xFFBA1A1A)),
      ]) {
        final tile = find.byKey(ValueKey(id));
        expect(
          tester
              .widget<Text>(
                find.descendant(of: tile, matching: find.text(label)),
              )
              .style!
              .color,
          color,
        );
        expect(
          tester
              .widget<Icon>(
                find.descendant(of: tile, matching: find.byType(Icon)),
              )
              .color,
          color,
        );
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Photo $number, $label'), findsOneWidget);
      }
      expect(find.textContaining('blur'), findsNothing);
      expect(find.textContaining('lighting'), findsNothing);
      semantics.dispose();
    },
  );

  for (final (score, category, progress, color) in [
    (82, QualityCategory.green, 0.82, const Color(0xFF177449)),
    (42, QualityCategory.green, 0.42, const Color(0xFF177449)),
    (99, QualityCategory.red, 0.99, const Color(0xFFBA1A1A)),
    (-1, QualityCategory.amber, 0.0, const Color(0xFF946000)),
    (101, QualityCategory.red, 0.0, const Color(0xFFBA1A1A)),
    (double.nan, QualityCategory.red, 0.0, const Color(0xFFBA1A1A)),
  ]) {
    testWidgets(
      'gauge score $score maps to progress only, category $category owns color',
      (tester) async {
        await tester.pumpWidget(
          app(
            QualityReport(
              overallScore: score,
              category: category,
              suggestion: 'Supplied',
              photos: const [],
            ),
          ),
        );
        final paint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.painter is QualityScoreGaugePainter,
          ),
        );
        final painter = paint.painter! as QualityScoreGaugePainter;
        expect(painter.progress, progress);
        expect(painter.color, color);
        expect(find.text('$score/100'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in ['en', 'vi']) {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 3.0),
    ]) {
      testWidgets(
        'photo grid $locale fits $size at scale $scale collapsed and expanded',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await pumpDetails(
            tester,
            app(QualityReportFixtures.green, locale: locale, scale: scale),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              locale == 'vi' ? 'Chi tiết chất lượng' : 'Quality details',
            ),
            findsOneWidget,
          );
          if (size.width == 390 && scale == 1) {
            final y = tester
                .getTopLeft(find.byKey(const ValueKey('green-warn-1')))
                .dy;
            expect(
              tester.getTopLeft(find.byKey(const ValueKey('green-warn-3'))).dy,
              y,
            );
            expect(
              tester.getTopLeft(find.byKey(const ValueKey('green-warn-4'))).dy,
              greaterThan(y),
            );
          }
          expect(tester.takeException(), isNull);
          await toggle(tester);
          expect(tiles(tester).length, 24);
          await tester.ensureVisible(
            find.text(QualityReportFixtures.green.suggestion),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await toggle(tester);
          expect(tiles(tester).length, 6);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
