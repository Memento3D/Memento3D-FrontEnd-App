import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_wizard.dart';

void main() {
  testWidgets('camera layout fits a Pixel 6a viewport', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: CameraView(
          controller: null,
          capturedPhotos: const [],
          wizardState: CaptureWizardState.ready,
          capturing: false,
          cameraFailed: true,
          onCapture: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Ch\u1ee5p'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thumbnail badge follows the captured photo collection', (
    tester,
  ) async {
    Future<void> showPhotos(int count) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: CameraView(
            controller: null,
            capturedPhotos: List.generate(
              count,
              (index) => XFile('missing_photo_$index.jpg'),
            ),
            wizardState: CaptureWizardState.ready,
            capturing: false,
            cameraFailed: true,
            onCapture: () {},
            onRetry: () {},
          ),
        ),
      );
    }

    await showPhotos(0);
    expect(find.text('0'), findsNothing);
    await showPhotos(1);
    expect(find.text('1'), findsOneWidget);
    await showPhotos(5);
    expect(find.text('5'), findsOneWidget);
    final thumbnail = tester.widget<Image>(find.byType(Image));
    expect((thumbnail.image as FileImage).file.path, 'missing_photo_4.jpg');
    expect(tester.takeException(), isNull);
  });
}
