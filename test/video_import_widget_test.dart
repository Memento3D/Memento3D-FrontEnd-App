import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_mode.dart';
import 'package:memento3d_frontend_app/screens/file_picker_video_picker.dart';
import 'package:memento3d_frontend_app/screens/video_file_probe.dart';
import 'package:memento3d_frontend_app/screens/video_import_coordinator.dart';
import 'package:memento3d_frontend_app/screens/video_import_policy.dart';
import 'package:memento3d_frontend_app/screens/video_picker.dart';
import 'package:memento3d_frontend_app/screens/video_preview_screen.dart';
import 'package:memento3d_frontend_app/screens/video_recording.dart';

import 'fake_video_import.dart';
import 'fake_video_playback.dart';

class ImportCamera extends CameraController {
  ImportCamera(this.file)
    : super(
        const CameraDescription(
          name: 'fake',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
  final XFile file;
  int starts = 0;
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
  Future<void> startVideoRecording({
    void Function(CameraImage)? onAvailable,
    bool enablePersistentRecording = true,
  }) async {
    ++starts;
    value = value.copyWith(
      isRecordingVideo: true,
      recordingOrientation: const Optional.of(DeviceOrientation.portraitUp),
    );
  }

  @override
  Future<XFile> stopVideoRecording() async {
    value = value.copyWith(isRecordingVideo: false);
    return file;
  }

  @override
  // No plugin resources in this hardware-free fake.
  // ignore: must_call_super
  Future<void> dispose() async {}
}

class ImportRecorder implements VideoRecorder {
  ImportRecorder(this.file);
  final XFile file;
  bool fail = false;
  @override
  bool get available => true;
  @override
  Future<void> start() async {}
  @override
  Future<XFile> stop() async {
    if (fail) throw StateError('finalize');
    return file;
  }
}

Widget app(Widget home, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 8; ++i) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late XFile first, second;
  late VideoCaptureSession session;
  late FakeVideoPicker picker;
  late FakeVideoFileProbe probe;
  late FakeVideoImportStorage storage;
  late VideoImportCoordinator coordinator;
  late FakeVideoPlayback a, b;
  late List<String> loaded;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('c3_widgets_');
    first = XFile(
      (await File('${root.path}/A.mp4').writeAsBytes([1, 2, 3])).path,
    );
    second = XFile(
      (await File('${root.path}/B.mp4').writeAsBytes([4, 5, 6])).path,
    );
    session = VideoCaptureSession()
      ..select(LocalVideoSelection(first, finalizedByteLength: 3));
    picker = FakeVideoPicker()
      ..candidate = VideoImportCandidate(
        path: second.path,
        displayName: 'B.mp4',
      );
    probe = FakeVideoFileProbe();
    storage = FakeVideoImportStorage();
    coordinator = VideoImportCoordinator(
      session: session,
      picker: picker,
      probe: probe,
      storage: storage,
    );
    a = FakeVideoPlayback();
    b = FakeVideoPlayback();
    loaded = [];
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
  });
  tearDown(() async {
    coordinator.dispose();
    await root.delete(recursive: true);
  });
  Future<void> preview(WidgetTester tester, {String locale = 'en'}) async {
    await tester.pumpWidget(
      app(
        VideoPreviewScreen(
          session: session,
          importCoordinator: coordinator,
          playbackFactory: (file) {
            loaded.add(file.path);
            return file.path == first.path ? a : b;
          },
        ),
        locale: locale,
      ),
    );
    await flush(tester);
  }

  Future<void> replace(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('video-replace-library')));
    await tester.tap(find.byKey(const Key('video-replace-library')));
    await flush(tester);
  }

  testWidgets('Vietnamese replacement and imported labels retain accents', (
    tester,
  ) async {
    await preview(tester, locale: 'vi');
    expect(find.text('Thay từ thư viện'), findsOneWidget);
    await replace(tester);
    expect(find.text('Video từ thư viện'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'valid import explicitly reloads existing preview, releases A and pauses B',
    (tester) async {
      await preview(tester);
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(a.value.isPlaying, isTrue);
      await replace(tester);
      expect(find.text('B.mp4'), findsOneWidget);
      expect(find.text('A.mp4'), findsNothing);
      expect(loaded, [first.path, second.path]);
      expect(a.disposed, isTrue);
      expect(a.value.isPlaying, isFalse);
      expect(b.value.isInitialized, isTrue);
      expect(b.value.isPlaying, isFalse);
      expect(b.plays, 0);
      expect(session.currentVideo!.source, LocalVideoSource.imported);
      expect(find.text('Imported video'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('cancel replacement retains paused A and original selection', (
    tester,
  ) async {
    picker.candidate = null;
    await preview(tester);
    final original = session.currentVideo;
    await tester.tap(find.byKey(const Key('video-play-pause')));
    await tester.pump();
    await replace(tester);
    expect(session.currentVideo, same(original));
    expect(find.text('A.mp4'), findsOneWidget);
    expect(a.disposed, isFalse);
    expect(a.value.isPlaying, isFalse);
    expect(loaded, [first.path]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed pre-picker pause permits subsequent replacement', (
    tester,
  ) async {
    await preview(tester);
    final original = session.currentVideo;
    final revision = session.revision;
    a.failNextPause = true;
    await replace(tester);
    final strings = AppLocalizations.of(
      tester.element(find.byType(VideoPreviewScreen)),
    )!;
    expect(find.text(strings.videoPlaybackError), findsOneWidget);
    expect(find.text(strings.retry), findsOneWidget);
    expect(session.currentVideo, same(original));
    expect(session.revision, revision);
    expect(picker.calls, 0);
    expect(a.disposals, 0);
    expect(tester.takeException(), isNull);

    await replace(tester);
    expect(picker.calls, 1);
    expect(session.currentVideo!.file.path, second.path);
    expect(session.revision, revision + 1);
    expect(loaded, [first.path, second.path]);
    expect(a.disposed, isTrue);
    expect(b.value.isInitialized, isTrue);
    expect(b.value.isPlaying, isFalse);
    expect(b.value.position, Duration.zero);
    expect(find.text(strings.videoPlaybackError), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
    expect(b.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Retry after failed pre-picker pause disposes A and initializes fresh player',
    (tester) async {
      var creates = 0;
      await tester.pumpWidget(
        app(
          VideoPreviewScreen(
            session: session,
            importCoordinator: coordinator,
            playbackFactory: (_) => creates++ == 0 ? a : b,
          ),
        ),
      );
      await flush(tester);
      final original = session.currentVideo;
      a.failNextPause = true;
      await replace(tester);
      expect(picker.calls, 0);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await flush(tester);
      expect(a.disposals, 1);
      expect(a.disposed, isTrue);
      expect(creates, 2);
      expect(b.initializes, 1);
      expect(b.value.isPlaying, isFalse);
      expect(find.text('Loading video...'), findsNothing);
      expect(find.byKey(const Key('real-video-surface-seam')), findsOneWidget);
      expect(session.currentVideo, same(original));
      await tester.pumpWidget(const SizedBox());
      await flush(tester);
      expect(b.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failDispose in [false, true]) {
    testWidgets(
      'route release after failed pause attempts disposal (failure=$failDispose)',
      (tester) async {
        await preview(tester);
        final original = session.currentVideo;
        a.failNextPause = true;
        a.failDispose = failDispose;
        await replace(tester);
        expect(picker.calls, 0);
        await tester.pumpWidget(const SizedBox());
        await flush(tester);
        expect(a.disposals, 1);
        expect(a.disposed, !failDispose);
        expect(session.currentVideo, same(original));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final error in [
    VideoImportError.format,
    VideoImportError.size,
    VideoImportError.picker,
    VideoImportError.storage,
    VideoImportError.invalidSize,
    VideoImportError.unavailable,
  ]) {
    for (final locale in ['en', 'vi']) {
      testWidgets('$locale localized $error replacement keeps A visible', (
        tester,
      ) async {
        switch (error) {
          case VideoImportError.format:
            picker.candidate = VideoImportCandidate(
              path: second.path,
              displayName: 'B.mkv',
            );
          case VideoImportError.size:
            probe.facts = const VideoFileFacts(
              byteLength: VideoImportPolicy.maximumBytes + 1,
              readable: true,
            );
          case VideoImportError.picker:
            picker.fail = true;
          case VideoImportError.storage:
            storage.fail = true;
          case VideoImportError.invalidSize:
            probe.facts = const VideoFileFacts(readable: true);
          case VideoImportError.unavailable:
            probe.facts = const VideoFileFacts();
        }
        await preview(tester, locale: locale);
        final original = session.currentVideo;
        await replace(tester);
        expect(find.text('A.mp4'), findsOneWidget);
        expect(session.currentVideo, same(original));
        expect(find.byType(SnackBar), findsOneWidget);
        expect(a.disposed, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('short imported B remains selected and warns', (tester) async {
    b.duration = const Duration(seconds: 9);
    await preview(tester);
    await replace(tester);
    final strings = AppLocalizations.of(
      tester.element(find.byType(VideoPreviewScreen)),
    )!;
    expect(find.text(strings.videoTooShort(10)), findsOneWidget);
    expect(session.currentVideo!.file.path, second.path);
    expect(b.value.isPlaying, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'accepted AVI decode failure uses existing playback error and retry',
    (tester) async {
      picker.candidate = VideoImportCandidate(
        path: second.path,
        displayName: 'B.avi',
      );
      b.failInitialization = true;
      await preview(tester);
      await replace(tester);
      final strings = AppLocalizations.of(
        tester.element(find.byType(VideoPreviewScreen)),
      )!;
      expect(find.text(strings.videoPlaybackError), findsOneWidget);
      expect(find.text(strings.retry), findsOneWidget);
      expect(session.currentVideo!.displayName, 'B.avi');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('healthy A release completes before B playback creation', (
    tester,
  ) async {
    await preview(tester);
    a.disposeGate = Completer();
    await replace(tester);
    expect(loaded, [first.path]);
    expect(session.currentVideo!.file.path, second.path);
    a.disposeGate!.complete();
    await flush(tester);
    expect(loaded, [first.path, second.path]);
    expect(a.disposed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'disposed Preview rejects late picker and double tap calls only once',
    (tester) async {
      picker.gate = Completer();
      await preview(tester);
      await tester.ensureVisible(
        find.byKey(const Key('video-replace-library')),
      );
      await tester.tap(find.byKey(const Key('video-replace-library')));
      await tester.tap(find.byKey(const Key('video-replace-library')));
      await tester.pump();
      expect(picker.calls, 1);
      final original = session.currentVideo;
      await tester.pumpWidget(const SizedBox());
      picker.gate!.complete(picker.candidate);
      await flush(tester);
      expect(session.currentVideo, same(original));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Camera Library imports without navigation; pending import guards recording and mode switch',
    (tester) async {
      picker.gate = Completer();
      final camera = ImportCamera(first);
      await tester.pumpWidget(
        app(
          CameraScreen(
            session: CaptureSession(scanId: 'test-scan'),
            cameraFactory: () async => camera,
            videoPicker: picker,
            videoFileProbe: probe,
            videoImportStorage: storage,
            previewPlaybackFactory: (_) => b,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture-mode-video')));
      await tester.pump();
      expect(find.byKey(const Key('video-library')), findsOneWidget);
      expect(find.byKey(const Key('video-count-badge')), findsNothing);
      final initialView = tester.widget<CameraView>(find.byType(CameraView));
      initialView.onVideoLibrary!();
      initialView.onVideoLibrary!();
      initialView.onVideoRecord!();
      initialView.onModeChanged!(CaptureMode.photo);
      await tester.pump();
      expect(picker.calls, 1);
      expect(camera.starts, 0);
      final pendingView = tester.widget<CameraView>(find.byType(CameraView));
      expect(pendingView.mode, CaptureMode.video);
      expect(pendingView.onModeChanged, isNull);
      expect(pendingView.onVideoRecord, isNull);
      picker.gate!.complete(picker.candidate);
      await flush(tester);
      expect(find.byType(VideoPreviewScreen), findsNothing);
      expect(find.byKey(const Key('video-preview')), findsOneWidget);
      await tester.tap(find.byKey(const Key('video-preview')));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(VideoPreviewScreen), findsOneWidget);
      expect(find.text('B.mp4'), findsOneWidget);
      expect(b.value.isInitialized, isTrue);
      expect(b.plays, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Camera disposal before import completion never commits', (
    tester,
  ) async {
    picker.gate = Completer();
    VideoCaptureSession? captured;
    await tester.pumpWidget(
      app(
        CameraScreen(
          session: CaptureSession(scanId: 'test-scan'),
          cameraFactory: () async => ImportCamera(first),
          videoPicker: picker,
          videoFileProbe: probe,
          videoImportStorage: storage,
          developmentWrapper: (_, diagnostics, child) {
            captured = diagnostics.videoSession;
            return child;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('video-library')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    picker.gate!.complete(picker.candidate);
    await flush(tester);
    expect(captured!.currentVideo, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('recording makes Library unavailable', (tester) async {
    final camera = ImportCamera(first);
    await tester.pumpWidget(
      app(
        CameraScreen(
          session: CaptureSession(scanId: 'test-scan'),
          cameraFactory: () async => camera,
          videoPicker: picker,
          videoFileProbe: probe,
          videoImportStorage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    final view = tester.widget<CameraView>(find.byType(CameraView));
    view.onVideoRecord!();
    view.onVideoLibrary!(); // Even a pre-rebuild callback is refused.
    await tester.pump();
    expect(picker.calls, 0);
    expect(
      tester.widget<CameraView>(find.byType(CameraView)).onVideoLibrary,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
  });

  test('recorded replacement succeeds and failed finalization preserves imported video', () async {
    final recorder = ImportRecorder(first);
    final recording = VideoRecordingCoordinator();
    addTearDown(recording.dispose);
    final imports = VideoImportCoordinator(
      session: recording.videoSession,
      picker: picker,
      probe: probe,
      storage: storage,
    );
    addTearDown(imports.dispose);
    await imports.importVideo(isCurrent: () => !recording.busy);
    final imported = recording.videoSession.currentVideo!;
    recorder.fail = true;
    await recording.start(recorder);
    await recording.stop();
    expect(recording.videoSession.currentVideo, same(imported));
    recorder.fail = false;
    await recording.start(recorder);
    await recording.stop();
    expect(
      recording.videoSession.currentVideo!.source,
      LocalVideoSource.recorded,
    );
    await imports.importVideo(isCurrent: () => !recording.busy);
    expect(
      recording.videoSession.currentVideo!.source,
      LocalVideoSource.imported,
    );
  });

  test('picker adapter sends exact custom single-selection request without bytes/stream', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final channel = MethodChannel(
      'miguelruivo.flutter.plugins.filepicker',
      Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? const JSONMethodCodec()
          : const StandardMethodCodec(),
    );
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return [
        {'path': second.path, 'name': 'B.mp4', 'size': 999, 'bytes': null},
      ];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    FilePickerIO.registerWith();
    final candidate = await FilePickerVideoPicker().pickVideo();
    expect(request!.method, 'custom');
    expect(request!.arguments['allowMultipleSelection'], isFalse);
    expect(request!.arguments['allowedExtensions'], ['mp4', 'mov', 'avi']);
    expect(request!.arguments['withData'], isFalse);
    expect(candidate!.path, second.path);
    expect(candidate.displayName, 'B.mp4');
    expect(request!.arguments['compressionQuality'], 0);
  });
}
