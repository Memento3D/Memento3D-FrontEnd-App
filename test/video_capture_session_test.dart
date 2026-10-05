import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/video_recording.dart';
import 'package:memento3d_frontend_app/screens/video_capture_controls.dart';

import 'video_recording_test.dart' show Recorder;

void main() {
  test(
    'VideoCaptureSession starts empty and stores one current finalized video',
    () {
      final session = VideoCaptureSession();
      expect(session.currentVideo, isNull);
      expect(session.hasVideo, isFalse);
      final first = LocalVideoSelection(XFile('first'), finalizedByteLength: 1);
      final second = LocalVideoSelection(
        XFile('second'),
        finalizedByteLength: 2,
      );
      session.select(first);
      expect(session.currentVideo, same(first));
      session.select(second);
      expect(session.currentVideo, same(second));
      expect(session.hasVideo, isTrue);
      expect(first.finalizedByteLength, 1);
    },
  );
  test('replacement commits atomically only after stop finalizes; failures preserve prior video', () async {
    final directory = await Directory.systemTemp.createTemp('single_video_');
    final video = VideoRecordingCoordinator();
    try {
      final first = await File('${directory.path}/first.mp4').writeAsBytes([1]);
      final second = await File('${directory.path}/second.mp4')
          .writeAsBytes([2, 3]);
      final recorder = Recorder()..file = XFile(first.path);
      await video.start(recorder);
      expect(video.videoSession.currentVideo, isNull);
      await video.stop();
      final original = video.videoSession.currentVideo;
      recorder.file = XFile(second.path);
      recorder.stopGate = Completer<XFile>();
      await video.start(recorder);
      expect(video.videoSession.currentVideo, same(original));
      final pendingStop = video.stop();
      expect(video.videoSession.currentVideo, same(original));
      recorder.stopGate!.complete(recorder.file);
      await pendingStop;
      final replacement = video.videoSession.currentVideo;
      expect(replacement!.file.path, second.path);
      expect(replacement.finalizedByteLength, 2);
      expect(await original!.file.length(), 1);
      recorder.failStart = true;
      await video.start(recorder);
      expect(video.videoSession.currentVideo, same(replacement));
      recorder.failStart = false;
      recorder.failStop = true;
      await video.start(recorder);
      await video.stop();
      expect(video.videoSession.currentVideo, same(replacement));
    } finally {
      video.dispose();
      await directory.delete(recursive: true);
    }
  });
  test(
    'stale finalization after disposal preserves the prior selected video',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stale_replacement_',
      );
      final video = VideoRecordingCoordinator();
      try {
        final first = await File('${directory.path}/first.mp4')
            .writeAsBytes([1]);
        final second = await File('${directory.path}/second.mp4')
            .writeAsBytes([2]);
        final recorder = Recorder()..file = XFile(first.path);
        await video.start(recorder);
        await video.stop();
        final original = video.videoSession.currentVideo;
        recorder.file = XFile(second.path);
        recorder.stopGate = Completer<XFile>();
        await video.start(recorder);
        final pending = video.stop();
        video.dispose();
        recorder.stopGate!.complete(recorder.file);
        await pending;
        await video.quiesce();
        expect(video.videoSession.currentVideo, same(original));
        expect(video.videoSession.currentVideo!.file.path, first.path);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  for (final selected in [false, true]) {
    testWidgets(
      'Video controls with selected=$selected show correct left action without badge',
      (tester) async {
        tester.view.physicalSize = const Size(412, 914);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: VideoCaptureControls(hasVideo: selected),
              ),
            ),
          ),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(VideoCaptureControls)),
        )!;
        expect(
          find.text(selected ? strings.preview : strings.captureLibrary),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('video-library')),
          selected ? findsNothing : findsOneWidget,
        );
        expect(find.byKey(const Key('video-count-badge')), findsNothing);
        expect(find.byType(CircleAvatar), findsNothing);
        if (selected) {
          expect(
            tester
                .widget<Semantics>(find.byKey(const Key('video-preview')))
                .properties
                .enabled,
            isFalse,
          );
        }
        expect(
          tester
              .widget<Semantics>(find.byKey(const Key('video-next')))
              .properties
              .enabled,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'optional preview seam works while idle and is blocked during recording',
    (tester) async {
      var reviewed = 0;
      Future<void> show(VideoRecordingState state) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VideoCaptureControls(
              hasVideo: true,
              state: state,
              onReview: () => reviewed++,
            ),
          ),
        ),
      );
      await show(VideoRecordingState.idle);
      await tester.tap(find.byKey(const Key('video-preview')));
      expect(reviewed, 1);
      for (final state in [
        VideoRecordingState.starting,
        VideoRecordingState.recording,
        VideoRecordingState.stopping,
      ]) {
        await show(state);
        expect(
          tester
              .widget<Semantics>(find.byKey(const Key('video-preview')))
              .properties
              .enabled,
          isFalse,
        );
        await tester.tap(find.byKey(const Key('video-preview')));
      }
      expect(reviewed, 1);
    },
  );
}
