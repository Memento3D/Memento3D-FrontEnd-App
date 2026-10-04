import 'dart:async';
import 'dart:io';

import 'fake_video_playback.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_review_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/video_preview_screen.dart';
import 'package:memento3d_frontend_app/screens/video_capture_session.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';

class _Camera extends CameraController {
  _Camera(this.photo)
    : super(
        const CameraDescription(
          name: 'test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
  final XFile photo;
  bool released = false;
  Completer<void>? releaseGate, startGate;
  Completer<XFile>? stopGate;
  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1280, 720),
    );
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);
  @override
  Future<XFile> takePicture() async => photo;
  @override
  Future<void> startVideoRecording({
    void Function(CameraImage)? onAvailable,
    bool enablePersistentRecording = true,
  }) async {
    if (startGate != null) await startGate!.future;
    value = value.copyWith(
      isRecordingVideo: true,
      recordingOrientation: const Optional.of(DeviceOrientation.portraitUp),
    );
  }

  @override
  Future<XFile> stopVideoRecording() async {
    final file = stopGate == null ? photo : await stopGate!.future;
    value = value.copyWith(isRecordingVideo: false);
    return file;
  }

  // This hardware-free fake creates no plugin resources to release via super.
  @override
  // ignore: must_call_super
  Future<void> dispose() async {
    if (releaseGate != null) await releaseGate!.future;
    released = true;
    value = value.copyWith(isInitialized: false);
  }
}

Widget _app(Widget home, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late VideoCaptureSession session;
  late XFile first, second;
  setUp(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'dev.fluttercommunity.plus/sensors/method',
      'dev.fluttercommunity.plus/sensors/accelerometer',
      'dev.fluttercommunity.plus/sensors/user_accel',
      'dev.fluttercommunity.plus/sensors/gyroscope',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    directory = await Directory.systemTemp.createTemp('video_review_');
    first = XFile(
      (await File('${directory.path}/first.mp4')
              .writeAsBytes(List.filled(1024, 1)))
          .path,
    );
    second = XFile(
      (await File('${directory.path}/second.mp4')
              .writeAsBytes(List.filled(2048, 2)))
          .path,
    );
    session = VideoCaptureSession()
      ..select(LocalVideoSelection(second, finalizedByteLength: 2048));
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<void> flushFiles(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets(
    'preview metadata uses exactly the current selection without Photo actions',
    (tester) async {
      await tester.pumpWidget(
        _app(
          VideoPreviewScreen(
            session: session,
            playbackFactory: (_) =>
                FakeVideoPlayback()..failInitialization = true,
          ),
        ),
      );
      await flushFiles(tester);
      expect(
        tester
            .widget<VideoPreviewScreen>(find.byType(VideoPreviewScreen))
            .session,
        same(session),
      );
      expect(find.byKey(const Key('selected-video-preview')), findsOneWidget);
      expect(find.text('second.mp4'), findsOneWidget);
      expect(find.text('first.mp4'), findsNothing);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.textContaining(directory.path), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(CaptureReviewScreen), findsNothing);
      for (final text in [
        'Add angle',
        'Retake',
        'Detail level',
        'Standard',
        'High detail',
        'View processing status',
        '3D preview unavailable',
        'DEV',
        'Video 1',
        'Video 2',
      ]) {
        expect(find.text(text), findsNothing);
      }
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byType(ProcessingScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing or empty video is unavailable without changing finalization metadata',
    (tester) async {
      await tester.runAsync(() async {
        await File(first.path).delete();
        await File(second.path).writeAsBytes([]);
      });
      await tester.pumpWidget(
        _app(
          VideoPreviewScreen(
            session: session,
            playbackFactory: (_) =>
                FakeVideoPlayback()..failInitialization = true,
          ),
        ),
      );
      await flushFiles(tester);
      expect(find.text('Video unavailable'), findsOneWidget);

      expect(find.text('2.0 KB'), findsOneWidget);
      expect(session.currentVideo!.finalizedByteLength, 2048);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing current video displays unavailable while retaining finalized metadata',
    (tester) async {
      await tester.runAsync(() => File(second.path).delete());
      await tester.pumpWidget(
        _app(
          VideoPreviewScreen(
            session: session,
            playbackFactory: (_) =>
                FakeVideoPlayback()..failInitialization = true,
          ),
        ),
      );
      await flushFiles(tester);
      expect(find.text('Video unavailable'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(session.currentVideo!.file, same(second));
      expect(session.currentVideo!.finalizedByteLength, 2048);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty preview is truthful and offers no processing or playback action',
    (tester) async {
      await tester.pumpWidget(
        _app(VideoPreviewScreen(session: VideoCaptureSession())),
      );
      expect(find.text('No video selected'), findsOneWidget);
      expect(find.byKey(const Key('selected-video-preview')), findsNothing);
      expect(find.byType(ProcessingScreen), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.text('DEV'), findsNothing);
    },
  );
  testWidgets(
    'changed file is flagged while stored finalization size stays immutable',
    (tester) async {
      await tester.runAsync(() => File(second.path).writeAsBytes([1]));
      await tester.pumpWidget(
        _app(
          VideoPreviewScreen(
            session: session,
            playbackFactory: (_) =>
                FakeVideoPlayback()..failInitialization = true,
          ),
        ),
      );
      await flushFiles(tester);
      expect(
        find.text(
          'File has changed since recording. Size shown is from finalization.',
        ),
        findsOneWidget,
      );
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(session.currentVideo!.finalizedByteLength, 2048);
    },
  );
  for (final locale in ['en', 'vi']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$locale Video preview fits Pixel 6a at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(412, 914);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            VideoPreviewScreen(
              session: session,
              playbackFactory: (_) =>
                  FakeVideoPlayback()..failInitialization = true,
            ),
            locale: locale,
            scale: scale,
          ),
        );
        await flushFiles(tester);
        await tester.scrollUntilVisible(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(VideoPreviewScreen)),
            )!.recordedVideo,
          ),
          100,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Photo entry remains Photo-only and retains the same session', (
    tester,
  ) async {
    final photo = CaptureSession()..addPhoto(XFile('missing.jpg'));
    await tester.pumpWidget(_app(CaptureReviewScreen(session: photo)));
    expect(
      tester
          .widget<CaptureReviewScreen>(find.byType(CaptureReviewScreen))
          .session,
      same(photo),
    );
    expect(find.byType(VideoPreviewScreen), findsNothing);
    expect(find.text('Add angle'), findsOneWidget);
  });

  Future<List<_Camera>> openCapture(
    WidgetTester tester, {
    Completer<void>? releaseGate,
  }) async {
    final cameras = <_Camera>[];
    var seeded = false;
    await tester.pumpWidget(
      _app(
        CameraScreen(
          previewPlaybackFactory: (_) =>
              FakeVideoPlayback()..failInitialization = true,
          cameraFactory: () async {
            final camera = _Camera(first);
            if (cameras.isEmpty) camera.releaseGate = releaseGate;
            cameras.add(camera);
            return camera;
          },
          developmentWrapper: (context, diagnostics, capture) {
            if (!seeded) {
              seeded = true;
              diagnostics.videoSession.select(session.currentVideo!);
            }
            return capture;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cameras;
  }

  testWidgets('empty Video capture retains Library and cannot open review', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(CameraScreen(cameraFactory: () async => _Camera(first))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    final capture = tester.widget<CameraView>(find.byType(CameraView));
    expect(capture.hasVideo, isFalse);
    expect(capture.onVideoReview, isNull);
    expect(find.byKey(const Key('video-preview')), findsNothing);
    await tester.tap(find.byKey(const Key('video-library')));
    await tester.pump();
    expect(find.byType(VideoPreviewScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets(
    'Video preview navigation preserves both sessions and restores camera on system back',
    (tester) async {
      final cameras = await openCapture(tester);
      final context = tester.element(find.byType(CameraView));
      final strings = AppLocalizations.of(context)!;
      await tester.tap(find.bySemanticsLabel(strings.capturePhoto));
      await flushFiles(tester);
      final photos = tester
          .widget<CameraView>(find.byType(CameraView))
          .capturedPhotos;
      expect(photos, hasLength(1));
      await tester.tap(find.byKey(const Key('capture-mode-video')));
      await tester.pump();
      final capture = tester.widget<CameraView>(find.byType(CameraView));
      expect(capture.hasVideo, isTrue);
      expect(capture.onVideoReview, isNotNull);
      await tester.tap(find.byKey(const Key('video-preview')));
      await tester.pump(const Duration(milliseconds: 350));
      await flushFiles(tester);
      await tester.pumpAndSettle();
      await flushFiles(tester);
      expect(find.byType(VideoPreviewScreen), findsOneWidget);
      expect(cameras.first.released, isTrue);
      final reviewSession = tester
          .widget<VideoPreviewScreen>(find.byType(VideoPreviewScreen))
          .session;
      expect(reviewSession.currentVideo, same(session.currentVideo));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(VideoPreviewScreen), findsNothing);
      final returned = tester.widget<CameraView>(find.byType(CameraView));
      expect(returned.hasVideo, isTrue);
      expect(returned.capturedPhotos, orderedEquals(photos));
      expect(returned.controller, same(cameras.last));
      expect(cameras, hasLength(2));
      expect(cameras.last.value.isInitialized, isTrue);
      await tester.tap(find.byKey(const Key('video-preview')));
      await tester.pump(const Duration(milliseconds: 350));
      await flushFiles(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VideoPreviewScreen>(find.byType(VideoPreviewScreen))
            .session,
        same(reviewSession),
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).hasVideo,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('double review tap waits for release and opens only one route', (
    tester,
  ) async {
    final gate = Completer<void>();
    final cameras = await openCapture(tester, releaseGate: gate);
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    final callback = tester
        .widget<CameraView>(find.byType(CameraView))
        .onVideoReview!;
    callback();
    callback();
    await tester.pump();
    expect(find.byType(VideoPreviewScreen), findsNothing);
    expect(cameras.first.released, isFalse);
    gate.complete();
    await tester.pump(const Duration(milliseconds: 350));
    await flushFiles(tester);
    await tester.pumpAndSettle();
    expect(find.byType(VideoPreviewScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(VideoPreviewScreen), findsNothing);
    expect(cameras, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets(
    'review is blocked during actual starting recording and stopping states',
    (tester) async {
      final cameras = await openCapture(tester);
      await tester.tap(find.byKey(const Key('capture-mode-video')));
      await tester.pump();
      final camera = cameras.first;
      camera.startGate = Completer();
      camera.stopGate = Completer();
      await tester.tap(find.byKey(const Key('video-record')));
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).onVideoReview,
        isNull,
      );
      camera.startGate!.complete();
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).onVideoReview,
        isNull,
      );
      await tester.tap(find.byKey(const Key('video-record')));
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).onVideoReview,
        isNull,
      );
      expect(find.byType(VideoPreviewScreen), findsNothing);
      await tester.runAsync(() async {
        camera.stopGate!.complete(first);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).hasVideo,
        isTrue,
      );
      expect(
        tester.widget<CameraView>(find.byType(CameraView)).onVideoReview,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
