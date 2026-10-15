import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/screens/video_recording.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_mode.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/capture_wizard.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

class Recorder implements VideoRecorder {
  @override
  bool available = true;
  int starts = 0, stops = 0;
  Completer<void>? startGate;
  Completer<XFile>? stopGate;
  bool failStart = false, failStop = false;
  late XFile file;
  @override
  Future<void> start() async {
    starts++;
    if (startGate != null) await startGate!.future;
    if (failStart) throw StateError('start');
  }

  @override
  Future<XFile> stop() async {
    stops++;
    if (failStop) throw StateError('stop');
    return stopGate == null ? file : await stopGate!.future;
  }
}

void main() {
  late Directory directory;
  late Recorder recorder;
  late VideoRecordingCoordinator video;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phase_b_');
    final file = await File('${directory.path}/record.mp4')
        .writeAsBytes([1, 2, 3]);
    recorder = Recorder()..file = XFile(file.path);
    video = VideoRecordingCoordinator();
  });
  tearDown(() async {
    video.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'delayed start guards double taps and starts timer only on success',
    () async {
      recorder.startGate = Completer();
      final start = video.start(recorder);
      await video.start(recorder);
      expect(recorder.starts, 1);
      expect(video.state, VideoRecordingState.starting);
      expect(video.elapsed, Duration.zero);
      recorder.startGate!.complete();
      await start;
      expect(video.state, VideoRecordingState.recording);
      expect(video.elapsed, Duration.zero);
      await video.stop();
    },
  );
  test('unavailable camera and failed start are recoverable', () async {
    recorder.available = false;
    await video.start(recorder);
    expect(video.error, VideoRecordingError.unavailable);
    expect(recorder.starts, 0);
    recorder.available = true;
    recorder.failStart = true;
    await video.start(recorder);
    expect(video.state, VideoRecordingState.error);
    expect(video.videoSession.currentVideo, isNull);
    recorder.failStart = false;
    await video.start(recorder);
    expect(video.state, VideoRecordingState.recording);
    await video.stop();
  });
  test(
    'double stop finalizes exactly once and retains original XFile',
    () async {
      await video.start(recorder);
      recorder.stopGate = Completer();
      final stop = video.stop();
      final duplicate = video.stop();
      expect(video.state, VideoRecordingState.stopping);
      expect(recorder.stops, 1);
      recorder.stopGate!.complete(recorder.file);
      await Future.wait([stop, duplicate]);
      expect(video.videoSession.currentVideo!.file, same(recorder.file));
      expect(
        video.videoSession.currentVideo!.source,
        LocalVideoSource.recorded,
      );
      expect(video.state, VideoRecordingState.idle);
    },
  );
  test('failed stop never fabricates selection', () async {
    await video.start(recorder);
    recorder.failStop = true;
    await video.stop();
    expect(video.videoSession.currentVideo, isNull);
    expect(video.error, VideoRecordingError.finalize);
    expect(video.busy, isFalse);
  });
  test(
    'failed replacement preserves previous video on start and stop failure',
    () async {
      await video.start(recorder);
      await video.stop();
      final previous = video.videoSession.currentVideo;
      recorder.failStart = true;
      await video.start(recorder);
      expect(video.videoSession.currentVideo, same(previous));
      recorder.failStart = false;
      await video.start(recorder);
      expect(video.videoSession.currentVideo, same(previous));
      recorder.failStop = true;
      await video.stop();
      expect(video.videoSession.currentVideo, same(previous));
    },
  );
  test('successful replacement keeps only the new reference and preserves the old physical file', () async {
    await video.start(recorder);
    await video.stop();
    final old = video.videoSession.currentVideo!.file;
    final next = await File('${directory.path}/next.mp4').writeAsBytes([4]);
    recorder.file = XFile(next.path);
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.currentVideo!.file, same(recorder.file));
    expect(video.videoSession.currentVideo!.file, isNot(same(old)));
    expect(await File(old.path).exists(), isTrue);
  });
  test('empty and missing references fail minimal file boundary', () async {
    recorder.file = XFile('${directory.path}/missing.mp4');
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.currentVideo, isNull);
    final empty = await File('${directory.path}/empty.mp4').create();
    recorder.file = XFile(empty.path);
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.currentVideo, isNull);
  });
  for (final reason in ['header back', 'system back', 'lifecycle pause']) {
    test(
      '$reason serializes delayed start, stop, then camera disposal',
      () async {
        recorder.startGate = Completer();
        recorder.stopGate = Completer();
        final start = video.start(recorder);
        bool disposed = false;
        final release = video.quiesce().then((_) => disposed = true);
        await video.start(recorder);
        expect(recorder.starts, 1);
        expect(disposed, isFalse);
        recorder.startGate!.complete();
        await start;
        await Future<void>.delayed(Duration.zero);
        expect(recorder.stops, 1);
        expect(disposed, isFalse);
        final duplicate = video.quiesce();
        recorder.stopGate!.complete(recorder.file);
        await Future.wait([release, duplicate]);
        expect(disposed, isTrue);
        expect(recorder.stops, 1);
        expect(video.state, VideoRecordingState.idle);
        expect(video.videoSession.currentVideo, isNotNull);
        await video.start(recorder);
        expect(video.state, VideoRecordingState.recording);
        await video.stop();
      },
    );
  }
  test(
    'disposal suppresses stale selection and rejects subsequent start',
    () async {
      recorder.startGate = Completer();
      final start = video.start(recorder);
      video.dispose();
      recorder.startGate!.complete();
      await start;
      await video.quiesce();
      expect(recorder.stops, 1);
      expect(video.videoSession.currentVideo, isNull);
      await video.start(recorder);
      expect(recorder.starts, 1);
      // Avoid disposing twice in tearDown.
      video = VideoRecordingCoordinator();
    },
  );
  testWidgets('timer updates after success and freezes on stop and failure', (
    tester,
  ) async {
    await video.start(recorder);
    await tester.pump(const Duration(seconds: 3));
    expect(video.elapsed, const Duration(seconds: 3));
    expect(video.state, VideoRecordingState.recording);
    await tester.runAsync(() => video.stop());
    final elapsed = video.elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(video.elapsed, elapsed);
    recorder.failStart = true;
    await video.start(recorder);
    await tester.pump(const Duration(seconds: 3));
    expect(video.elapsed, Duration.zero);
  });
  testWidgets(
    'delayed start leaves elapsed zero; each new start resets timer',
    (tester) async {
      recorder.startGate = Completer();
      final pending = video.start(recorder);
      await tester.pump(const Duration(seconds: 5));
      expect(video.elapsed, Duration.zero);
      recorder.startGate!.complete();
      await pending;
      await tester.pump(const Duration(seconds: 2));
      expect(video.elapsed, const Duration(seconds: 2));
      await tester.runAsync(() => video.stop());
      recorder.startGate = null;
      await video.start(recorder);
      expect(video.elapsed, Duration.zero);
      await tester.runAsync(() => video.stop());
    },
  );
  testWidgets('failed stop cancels timer', (tester) async {
    await video.start(recorder);
    await tester.pump(const Duration(seconds: 2));
    recorder.failStop = true;
    await video.stop();
    await tester.pump(const Duration(seconds: 8));
    expect(video.elapsed, const Duration(seconds: 2));
    expect(video.busy, isFalse);
  });
  testWidgets('disposal cancels timer without notifying stale listeners', (
    tester,
  ) async {
    await video.start(recorder);
    var updates = 0;
    video.addListener(() => updates++);
    await tester.runAsync(() async {
      video.dispose();
      await video.quiesce();
    });
    await tester.pump(const Duration(seconds: 5));
    expect(updates, 0);
    video = VideoRecordingCoordinator();
  });
  testWidgets('Pixel 6a recording controls, mode retention and Photo session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final firstPhoto = recorder.file;
    final session = CaptureSession()..addPhoto(firstPhoto);
    CaptureMode mode = CaptureMode.video;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListenableBuilder(
          listenable: video,
          builder: (context, _) => StatefulBuilder(
            builder: (context, setState) => CameraView(
              controller: null,
              previewFrame: const ColoredBox(color: Colors.black),
              capturedPhotos: session.capturedPhotos,
              wizardState: CaptureWizardState.ready,
              capturing: false,
              cameraFailed: false,
              onCapture: () {},
              onRetry: () {},
              onDone: null,
              mode: mode,
              onModeChanged: video.busy
                  ? null
                  : (next) => setState(() => mode = next),
              videoState: video.state,
              videoElapsed: const Duration(seconds: 24),
              hasVideo: video.videoSession.hasVideo,
              onVideoRecord: video.state == VideoRecordingState.recording
                  ? () => video.stop()
                  : video.busy
                  ? null
                  : () => video.start(recorder),
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('video-record')))
          .properties
          .enabled,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('video-record')));
    await tester.pump();
    expect(recorder.starts, 1);
    expect(find.text('● REC 00:24'), findsOneWidget);
    for (final key in ['capture-mode-photo', 'video-library', 'video-next']) {
      expect(
        tester.widget<Semantics>(find.byKey(Key(key))).properties.enabled,
        isFalse,
      );
    }
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => video.stop());
    await tester.pump();
    await tester.runAsync(() async {
      final second = await File('${directory.path}/mode_second.mp4')
          .writeAsBytes([4]);
      recorder.file = XFile(second.path);
      await video.start(recorder);
      await video.stop();
    });
    await tester.pump();
    final selected = video.videoSession.currentVideo;
    await tester.tap(find.byKey(const Key('capture-mode-photo')));
    await tester.pump();
    expect(mode, CaptureMode.photo);
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    expect(mode, CaptureMode.video);
    expect(video.videoSession.currentVideo, same(selected));
    expect(session.capturedPhotos, [firstPhoto]);
    expect(video.videoSession.hasVideo, isTrue);
    expect(tester.takeException(), isNull);
  });
}
