import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_review_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';

void main() {
  const scanId = '11111111-2222-4333-8444-555555555555';

  test('camera rejects a local-only session', () {
    expect(() => CameraScreen(session: CaptureSession()), throwsArgumentError);
  });

  testWidgets('camera passes the caller session and scan ID to review', (
    tester,
  ) async {
    const cameraChannel = MethodChannel('plugins.flutter.io/camera');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      cameraChannel,
      (call) async => call.method == 'availableCameras' ? <dynamic>[] : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        cameraChannel,
        null,
      ),
    );
    final session = CaptureSession(scanId: scanId)
      ..addPhoto(XFile('missing_identity_photo.jpg'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: CameraScreen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<CameraScreen>(find.byType(CameraScreen)).session,
      same(session),
    );

    tester.widget<CameraView>(find.byType(CameraView)).onDone!();
    await tester.pumpAndSettle();
    final review = tester.widget<CaptureReviewScreen>(
      find.byType(CaptureReviewScreen),
    );
    expect(review.session, same(session));
    expect(review.session.scanId, scanId);
    expect(review.session.photoCount, 1);
    expect(review.session.detailLevel, ReconstructionDetailLevel.highDetail);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
