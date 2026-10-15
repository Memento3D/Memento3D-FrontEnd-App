import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/main_video_capture_preview.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_bottom_navigation.dart';
import 'package:memento3d_frontend_app/screens/capture_mode.dart';

void main() {
  testWidgets(
    'preview uses real shell, switches modes and keeps navigation visible',
    (tester) async {
      tester.view.physicalSize = const Size(412, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const VideoCapturePreviewApp());
      await tester.pumpAndSettle();
      final shell = tester.element(find.byType(CameraView));
      final strings = AppLocalizations.of(shell)!;
      expect(strings.localeName, 'vi');
      expect(find.text(strings.capturedPhotos(5)), findsOneWidget);
      expect(find.text(strings.preview), findsOneWidget);
      expect(find.text(strings.done), findsOneWidget);
      expect(find.text(strings.nextStep), findsNothing);
      List<Rect> controlColumns(Finder center) {
        final rowFinder = find
            .ancestor(of: center, matching: find.byType(Row))
            .first;
        final row = tester.widget<Row>(rowFinder);
        return [
          for (final child in row.children)
            tester.getRect(find.byWidget(child)),
        ];
      }

      final photoColumns = controlColumns(
        find.bySemanticsLabel(strings.capturePhoto),
      );
      expect(photoColumns, hasLength(3));
      expect(photoColumns.first.width, photoColumns.last.width);
      final donePill = tester.getRect(find.byKey(const Key('photo-done-pill')));
      final doneTarget = tester.getRect(
        find.byKey(const Key('photo-done-touch-target')),
      );
      expect(donePill.width, lessThan(photoColumns.last.width));
      expect(donePill.center.dx, photoColumns.last.center.dx);
      expect(doneTarget.width, greaterThanOrEqualTo(48));
      expect(doneTarget.height, greaterThanOrEqualTo(48));
      expect(photoColumns[1].center.dx, tester.view.physicalSize.width / 2);

      final modeSwitcher = tester.getRect(
        find.byKey(const Key('capture-mode-photo')),
      );
      final navigation = tester.getRect(find.byType(CaptureBottomNavigation));
      expect(tester.takeException(), isNull);
      expect(find.byType(CaptureBottomNavigation), findsOneWidget);
      expect(find.text('DEVELOPMENT PREVIEW'), findsNothing);
      final frame = tester.getRect(
        find.byKey(const Key('video-preview-frame')),
      );
      await tester.tap(find.byKey(const Key('capture-mode-video')));
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(CameraView)), same(shell));
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).mode,
        CaptureMode.video,
      );
      expect(
        tester.getRect(find.byKey(const Key('video-preview-frame'))),
        frame,
      );
      expect(find.text(strings.capturedPhotos(5)), findsNothing);
      expect(find.text(strings.captureLibrary), findsOneWidget);
      expect(find.text(strings.nextStep), findsOneWidget);
      expect(find.text(strings.done), findsNothing);
      expect(
        controlColumns(find.byKey(const Key('video-record'))),
        photoColumns,
      );
      expect(
        tester.getRect(find.byKey(const Key('capture-mode-photo'))),
        modeSwitcher,
      );
      expect(tester.getRect(find.byType(CaptureBottomNavigation)), navigation);
      expect(tester.takeException(), isNull);
      expect(find.byType(CaptureBottomNavigation), findsOneWidget);
      for (final key in ['video-library', 'video-record', 'video-next']) {
        final finder = find.byKey(Key(key));
        expect(tester.widget<Semantics>(finder).properties.enabled, isFalse);
        await tester.tap(finder);
      }
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).mode,
        CaptureMode.video,
      );
      expect(
        tester.getRect(find.byType(CaptureBottomNavigation)).top,
        greaterThan(
          tester.getRect(find.byKey(const Key('video-record'))).bottom,
        ),
      );
      await tester.tap(find.byKey(const Key('capture-mode-photo')));
      await tester.pumpAndSettle();
      expect(find.text(strings.capturedPhotos(5)), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('video-preview-frame'))),
        frame,
      );
      expect(find.text(strings.done), findsOneWidget);
      expect(find.text(strings.nextStep), findsNothing);
      expect(
        controlColumns(find.bySemanticsLabel(strings.capturePhoto)),
        photoColumns,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('video-preview-dev')));
      await tester.pumpAndSettle();
      expect(find.text('DEVELOPMENT PREVIEW'), findsOneWidget);
      await tester.tap(find.byKey(const Key('video-preview-language')));
      await tester.pumpAndSettle();
      expect(
        AppLocalizations.of(tester.element(find.byType(CameraView)))!
            .localeName,
        'en',
      );
      expect(find.text('DEVELOPMENT PREVIEW'), findsNothing);
      expect(tester.takeException(), isNull);

      // The optional frame does not enable capture or add developer controls.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CameraView(
            controller: null,
            capturedPhotos: const [],
            wizardState: tester
                .widget<CameraView>(find.byType(CameraView))
                .wizardState,
            capturing: false,
            cameraFailed: true,
            onCapture: () {},
            onRetry: () {},
            onDone: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('video-preview-dev')), findsNothing);
      expect(find.byKey(const Key('video-preview-frame')), findsNothing);
    },
  );
}
