import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_bottom_navigation.dart';
import 'package:memento3d_frontend_app/screens/capture_mode.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/capture_wizard.dart';

Widget app(Widget home, {String locale = 'vi', double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

void main() {
  testWidgets('shared live viewport hides photo-only feedback in Video', (
    tester,
  ) async {
    final controller = CameraController(
      const CameraDescription(
        name: 'test-camera',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      ResolutionPreset.high,
      enableAudio: false,
    );
    controller.value = controller.value.copyWith(
      isInitialized: true,
      previewSize: const Size(1280, 720),
    );
    var mode = CaptureMode.photo;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => CameraView(
            controller: controller,
            capturedPhotos: [XFile('missing.jpg')],
            wizardState: CaptureWizardState.capturedSuccessfully,
            capturing: false,
            cameraFailed: false,
            mode: mode,
            onModeChanged: (value) => setState(() => mode = value),
            onCapture: () {},
            onRetry: () {},
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final strings = AppLocalizations.of(
      tester.element(find.byType(CameraView)),
    )!;
    expect(find.text(strings.capturedPhotos(1)), findsOneWidget);
    expect(find.text(strings.wizardCapturedTitle), findsOneWidget);
    expect(find.byType(CameraPreview), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(
      tester.widget<CameraView>(find.byType(CameraView)).controller,
      same(controller),
    );
    expect(find.text(strings.capturedPhotos(1)), findsNothing);
    expect(find.text(strings.wizardCapturedTitle), findsNothing);
    expect(find.text(strings.wizardReadyTitle), findsOneWidget);
    expect(find.text(strings.distanceGood), findsNothing);
    expect(find.text(strings.naturalLight), findsNothing);
    await tester.tap(find.byKey(const Key('capture-mode-photo')));
    await tester.pump();
    expect(find.text(strings.capturedPhotos(1)), findsOneWidget);
    expect(find.text(strings.wizardCapturedTitle), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });

  testWidgets('bottom navigation delegates only caller-supplied actions', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          bottomNavigationBar: CaptureBottomNavigation(
            callbacks: {CaptureDestination.collection: () => calls++},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-nav-collection')));
    expect(calls, 1);
    await tester.tap(find.byKey(const Key('capture-nav-settings')));
    expect(calls, 1);
  });

  testWidgets(
    'CameraScreen owns Photo default and switches in the same screen',
    (tester) async {
      await tester.pumpWidget(app(CameraScreen(session: CaptureSession(scanId: 'test-scan'))));
      await tester.pump(const Duration(milliseconds: 100));
      final original = tester.state(find.byType(CameraScreen));
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).mode,
        CaptureMode.photo,
      );
      await tester.tap(find.byKey(const Key('capture-mode-video')));
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).mode,
        CaptureMode.video,
      );
      expect(tester.state(find.byType(CameraScreen)), same(original));
      expect(find.byType(CameraScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('capture-mode-photo')));
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).mode,
        CaptureMode.photo,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('mode switching retains session photos and photo controls', (
    tester,
  ) async {
    final session = CaptureSession();
    for (var i = 0; i < 5; i++) {
      session.addPhoto(XFile('missing_$i.jpg'));
    }
    final photos = session.capturedPhotos.toList();
    var mode = CaptureMode.photo;
    var done = 0;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => CameraView(
            controller: null,
            capturedPhotos: session.capturedPhotos,
            wizardState: CaptureWizardState.capturedSuccessfully,
            capturing: false,
            cameraFailed: true,
            mode: mode,
            onModeChanged: (value) => setState(() => mode = value),
            onCapture: () {},
            onRetry: () {},
            onDone: () => done++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bản xem'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    final shutterPosition = tester.getCenter(find.bySemanticsLabel('Chụp ảnh'));
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    expect(find.text('Bản xem'), findsNothing);
    expect(find.text('Xong'), findsNothing);
    expect(find.text('5'), findsNothing);
    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Bước tiếp'), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('video-record'))),
      shutterPosition,
    );
    for (final key in ['video-library', 'video-record', 'video-next']) {
      final finder = find.byKey(Key(key));
      expect(tester.widget<Semantics>(finder).properties.enabled, isFalse);
      await tester.tap(finder);
    }
    await tester.pump();
    expect(done, 0);
    expect(find.byType(CameraView), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture-mode-photo')));
    await tester.pump();
    expect(session.capturedPhotos, orderedEquals(photos));
    expect(session.photoCount, 5);
    expect(find.text('5'), findsOneWidget);
    final thumbnail = tester.widget<Image>(find.byType(Image));
    expect((thumbnail.image as FileImage).file.path, photos.last.path);
    await tester.tap(find.text('Xong'));
    expect(done, 1);
  });

  testWidgets('mode selection and disabled video controls expose semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var mode = CaptureMode.photo;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => CameraView(
            controller: null,
            capturedPhotos: const [],
            wizardState: CaptureWizardState.ready,
            capturing: false,
            cameraFailed: true,
            mode: mode,
            onModeChanged: (value) => setState(() => mode = value),
            onCapture: () {},
            onRetry: () {},
            onDone: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final strings = AppLocalizations.of(
      tester.element(find.byType(CameraView)),
    )!;
    final doneControl = find
        .ancestor(
          of: find.text(strings.done),
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(tester.widget<GestureDetector>(doneControl).onTap, isNull);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text(strings.done),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      .55,
    );
    await tester.tap(find.text(strings.done));
    await tester.pump();
    expect(find.byType(CameraView), findsOneWidget);
    expect(find.text(strings.nextStep), findsNothing);
    expect(
      tester.getSemantics(find.byKey(const Key('capture-mode-photo'))),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Ảnh',
      ),
    );
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('capture-mode-video')))
          .properties
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('capture-mode-photo')))
          .properties
          .selected,
      isFalse,
    );
    for (final key in ['video-library', 'video-record', 'video-next']) {
      expect(
        tester.getSemantics(find.byKey(Key(key))),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          label: tester
              .widget<Semantics>(find.byKey(Key(key)))
              .properties
              .label,
        ),
      );
    }
    handle.dispose();
  });

  testWidgets(
    'capture bottom navigation presents five destinations without routing',
    (tester) async {
      await tester.pumpWidget(
        app(const Scaffold(bottomNavigationBar: CaptureBottomNavigation())),
      );
      await tester.pumpAndSettle();
      for (final destination in CaptureDestination.values) {
        final finder = find.byKey(ValueKey('capture-nav-${destination.name}'));
        expect(
          tester.widget<Semantics>(finder).properties.selected,
          destination == CaptureDestination.camera,
        );
        expect(tester.widget<Semantics>(finder).properties.enabled, isFalse);
        await tester.tap(finder);
      }
      await tester.pump();
      for (final label in [
        'Bộ sưu tập',
        'Bản in',
        'Camera',
        'Xưởng tạo',
        'Cài đặt',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(Scaffold), findsOneWidget);
    },
  );

  for (final locale in ['en', 'vi']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in CaptureMode.values) {
        testWidgets('$locale $mode fits Pixel 6a at scale $scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(412, 914);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            app(
              CameraView(
                controller: null,
                capturedPhotos: const [],
                wizardState: CaptureWizardState.ready,
                capturing: false,
                cameraFailed: true,
                mode: mode,
                onCapture: () {},
                onRetry: () {},
                onDone: null,
              ),
              locale: locale,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('Wabi-Sabi'), findsNothing);
          expect(find.byIcon(Icons.auto_fix_high), findsNothing);
          expect(find.text('Automatic'), findsNothing);
          expect(find.text('Tự động'), findsNothing);
        });
      }
    }
  }
}
