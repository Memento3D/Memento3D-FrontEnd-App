import 'dart:io';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/main_video_recording_device.dart';
import 'package:memento3d_frontend_app/screens/camera_view.dart';
import 'package:memento3d_frontend_app/screens/capture_mode.dart';
import 'package:memento3d_frontend_app/screens/video_recording.dart';
import 'package:memento3d_frontend_app/screens/capture_wizard.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

import 'video_recording_test.dart' show Recorder;

void main() {
  late Directory directory;
  late Recorder recorder;
  late VideoRecordingCoordinator video;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recording_diagnostics_');
    final file = await File('${directory.path}/first.mp4')
        .writeAsBytes([1, 2, 3]);
    recorder = Recorder()..file = XFile(file.path);
    video = VideoRecordingCoordinator();
  });
  tearDown(() async {
    await video.quiesce();
    video.dispose();
    await directory.delete(recursive: true);
  });

  test('only successful finalization replaces the selected video; errors preserve it', () async {
    expect(video.videoSession.hasVideo, isFalse);
    expect(video.videoSession.currentVideo, isNull);
    recorder.failStart = true;
    await video.start(recorder);
    expect(video.videoSession.hasVideo, isFalse);
    recorder.failStart = false;
    await video.start(recorder);
    expect(video.videoSession.hasVideo, isFalse);
    await video.stop();
    expect(video.videoSession.hasVideo, isTrue);
    expect(video.videoSession.currentVideo!.file, same(recorder.file));
    expect(video.videoSession.currentVideo!.finalizedByteLength, 3);
    final previous = video.videoSession.currentVideo;
    recorder.failStop = true;
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.hasVideo, isTrue);
    expect(video.videoSession.currentVideo, same(previous));
    recorder.failStop = false;
    final second = await File('${directory.path}/second.mp4')
        .writeAsBytes([4, 5]);
    recorder.file = XFile(second.path);
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.hasVideo, isTrue);
    expect(video.videoSession.currentVideo!.file, same(recorder.file));
    expect(video.videoSession.currentVideo!.finalizedByteLength, 2);
    expect(video.videoSession.currentVideo, isNot(same(previous)));
  });

  test(
    'replacement uses the actual returned XFile even when its path is reused',
    () async {
      await video.start(recorder);
      await video.stop();
      final first = video.videoSession.currentVideo!.file;
      recorder.file = XFile(first.path);
      await video.start(recorder);
      await video.stop();
      expect(video.videoSession.hasVideo, isTrue);
      expect(video.videoSession.currentVideo!.file, isNot(same(first)));
      expect(video.videoSession.hasVideo, isTrue);
      expect(video.videoSession.currentVideo!.file, same(recorder.file));
      expect(identical(first, video.videoSession.currentVideo!.file), isFalse);
    },
  );

  test('invalid finalization and disposal do not select video', () async {
    recorder.file = XFile('${directory.path}/missing.mp4');
    await video.start(recorder);
    await video.stop();
    expect(video.videoSession.hasVideo, isFalse);
    video.dispose();
    await video.start(recorder);
    expect(video.videoSession.hasVideo, isFalse);
    video = VideoRecordingCoordinator();
  });

  testWidgets(
    'DEV sheet shows only the current finalized selection after replacement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VideoRecordingDevOverlay(
            diagnostics: video,
            child: const Scaffold(body: Text('capture shell')),
          ),
        ),
      );
      expect(find.text('DEV: Phase B recording diagnostics'), findsNothing);
      await tester.tap(find.byKey(const Key('recording-dev-button')));
      await tester.pumpAndSettle();
      expect(find.text('Selected video: false'), findsOneWidget);
      expect(find.text('Video 1'), findsNothing);
      await video.start(recorder);
      await tester.pump();
      expect(find.text('Recording state: recording'), findsOneWidget);
      await tester.runAsync(() async {
        await video.stop();
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
      expect(find.text('Selected video: true'), findsOneWidget);
      expect(find.text('Local path: ${recorder.file.path}'), findsOneWidget);
      expect(find.text('Source: recorded'), findsOneWidget);
      expect(find.text('Finalized byte length: 3'), findsOneWidget);
      final oldPath = recorder.file.path;
      await tester.runAsync(() async {
        final second = await File('${directory.path}/second.mp4')
            .writeAsBytes([4]);
        recorder.file = XFile(second.path);
        await video.start(recorder);
        await video.stop();
      });
      await tester.pump();
      expect(find.text('Selected video: true'), findsOneWidget);
      expect(find.text('Local path: $oldPath'), findsNothing);
      expect(
        find.text('Local path: ${video.videoSession.currentVideo!.file.path}'),
        findsOneWidget,
      );
      expect(find.text('Finalized byte length: 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Photo/Video switching retains the current video', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await video.start(recorder);
      await video.stop();
    });
    await tester.runAsync(() async {
      final second = await File('${directory.path}/mode_second.mp4')
          .writeAsBytes([4]);
      recorder.file = XFile(second.path);
      await video.start(recorder);
      await video.stop();
    });
    final retained = video.videoSession.currentVideo;
    var mode = CaptureMode.video;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: StatefulBuilder(
          builder: (context, update) => VideoRecordingDevOverlay(
            diagnostics: video,
            child: CameraView(
              controller: null,
              capturedPhotos: const [],
              wizardState: CaptureWizardState.ready,
              capturing: false,
              cameraFailed: true,
              onCapture: () {},
              onRetry: () {},
              onDone: null,
              mode: mode,
              onModeChanged: (next) => update(() => mode = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('capture-mode-photo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('capture-mode-video')));
    await tester.pump();
    expect(video.videoSession.hasVideo, isTrue);
    expect(video.videoSession.currentVideo, same(retained));
    expect(mode, CaptureMode.video);
  });
  testWidgets('production CameraView has no DEV button or diagnostic panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: CameraView(
          controller: null,
          capturedPhotos: const [],
          wizardState: CaptureWizardState.ready,
          capturing: false,
          cameraFailed: true,
          onCapture: () {},
          onRetry: () {},
          onDone: null,
        ),
      ),
    );
    expect(find.byType(VideoRecordingDevOverlay), findsNothing);
    expect(find.byType(VideoRecordingDiagnosticsPanel), findsNothing);
    expect(find.text('DEV'), findsNothing);
    expect(find.textContaining('Selection revision'), findsNothing);
  });
}
