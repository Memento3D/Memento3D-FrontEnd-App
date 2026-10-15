import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/app/photo_capture_flow.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_model.dart';
import 'package:memento3d_frontend_app/features/uploads/presentation/screens/upload_progress_screen.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/photo_upload_manifest.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/photo_upload_failure.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/services/sequential_photo_upload_source.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_review_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';

import 'sequential_photo_upload_test.dart' as fixtures;

Widget app(Widget home, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async =>
              call.method == 'availableCameras' ? <dynamic>[] : null,
        );
  });
  testWidgets(
    'local review cannot submit; persisted review guards duplicate tap',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final pending = Completer<void>();
      Future<void> upload(BuildContext context, CaptureSession session) {
        calls++;
        return pending.future;
      }

      await tester.pumpWidget(
        app(
          CaptureReviewScreen(
            session: CaptureSession()..addPhoto(XFile('missing.jpg')),
            onUpload: upload,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload photos'));
      expect(calls, 0);
      await tester.pumpWidget(
        app(
          CaptureReviewScreen(
            key: UniqueKey(),
            session: CaptureSession(scanId: 'persisted-scan')
              ..addPhoto(XFile('missing.jpg')),
            onUpload: upload,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload photos'));
      await tester.tap(find.text('Upload photos'));
      expect(calls, 1);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'wizard exact result reaches camera/review and frozen real upload completion',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final nav = GlobalKey<NavigatorState>();
      final repo = fixtures.Repository();
      final results = <PhotoUploadResult>[];
      await tester.pumpWidget(app(const Scaffold(), navigatorKey: nav));
      unawaited(
        openCreatedScanFlow(
          nav.currentState!,
          const ScanModel(id: 'persisted-scan', name: 'Photo scan'),
          repository: repo,
          onUploaded: results.add,
        ),
      );
      // Return the wizard result without involving its unrelated instructional UI.
      nav.currentState!.pop('persisted-scan');
      await tester.pumpAndSettle();
      final session = tester
          .widget<CameraScreen>(find.byType(CameraScreen))
          .session;
      expect(session.scanId, 'persisted-scan');
      session.addPhoto(XFile('missing.jpg'));
      await tester.pumpWidget(
        app(
          PhotoCaptureFlow(
            session: session,
            repository: repo,
            onUploaded: results.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final localId = session.photoEntries.single.localCaptureId;
      tester.widget<CameraView>(find.byType(CameraView)).onDone!();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CaptureReviewScreen>(find.byType(CaptureReviewScreen))
            .session,
        same(session),
      );
      await tester.tap(find.text('Upload photos'));
      await tester.pumpAndSettle();
      expect(repo.calls.length, 1);
      session.addPhoto(XFile('later.jpg'));
      session.removePhoto(session.capturedPhotos.first);
      final screen = tester.widget<UploadProgressScreen>(
        find.byType(UploadProgressScreen),
      );
      expect(screen.session.photoCount, 1);
      expect(screen.controller.state.confirmedUnits, 0);
      repo.pending.single.complete(fixtures.image('backend-image'));
      await tester.pumpAndSettle();
      expect(results.length, 1);
      expect(repo.calls.length, 1);
      final source = screen.controller.source as SequentialPhotoUploadSource;
      expect(source.result!.photos.single.item.localCaptureId, localId);
      expect(screen.controller.state.confirmedUnits, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('ambiguous result has no retry and reopening never resends', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = fixtures.Repository();
    final session = CaptureSession(scanId: 'persisted-scan')
      ..addPhoto(XFile('missing.jpg'))
      ..addPhoto(XFile('later.jpg'));
    await tester.pumpWidget(
      app(PhotoCaptureFlow(session: session, repository: repo)),
    );
    await tester.pumpAndSettle();
    tester.widget<CameraView>(find.byType(CameraView)).onDone!();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Upload photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload photos'));
    await tester.pumpAndSettle();
    repo.pending.single.completeError(
      const PhotoUploadFailure(PhotoUploadFailureKind.ambiguous, 'Unknown'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be confirmed'), findsOneWidget);
    expect(find.byKey(const Key('upload-retry')), findsNothing);
    expect(find.text('Moving to quality check...'), findsNothing);
    final context = tester.element(find.byType(UploadProgressScreen));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Upload photos'));
    await tester.tap(find.text('Upload photos'));
    await tester.pumpAndSettle();
    expect(repo.calls.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  for (final returned in <String?>[null, 'different-scan']) {
    testWidgets(
      'wizard cancellation or mismatched result does not open capture ($returned)',
      (tester) async {
        final nav = GlobalKey<NavigatorState>();
        await tester.pumpWidget(app(const Scaffold(), navigatorKey: nav));
        final flow = openCreatedScanFlow(
          nav.currentState!,
          const ScanModel(id: 'persisted-scan', name: 'Scan'),
          repository: fixtures.Repository(),
        );
        nav.currentState!.pop(returned);
        await tester.pumpAndSettle();
        await flow;
        expect(find.byType(CameraScreen), findsNothing);
      },
    );
  }
}
