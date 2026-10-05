import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/video_capture_session.dart';
import 'package:memento3d_frontend_app/screens/video_duration_policy.dart';
import 'package:memento3d_frontend_app/screens/video_preview_screen.dart';

import 'fake_video_playback.dart';

void main() {
  for (final entry in [
    (const Duration(seconds: 9), false),
    (const Duration(milliseconds: 9999), false),
    (const Duration(seconds: 10), true),
    (const Duration(seconds: 11), true),
    (const Duration(days: 100), true),
  ]) {
    test(
      'duration policy ${entry.$1} is ${entry.$2} with no maximum',
      () => expect(VideoDurationPolicy.isSatisfied(entry.$1), entry.$2),
    );
  }
  test('duration formatting handles minutes hours and negative positions', () {
    expect(formatVideoDuration(const Duration(seconds: 12)), '00:12');
    expect(formatVideoDuration(const Duration(seconds: 65)), '01:05');
    expect(
      formatVideoDuration(const Duration(hours: 1, minutes: 2, seconds: 15)),
      '1:02:15',
    );
    expect(formatVideoDuration(const Duration(seconds: -1)), '00:00');
  });
  late Directory directory;
  late VideoCaptureSession session;
  late FakeVideoPlayback player;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playback_');
    final file = await File('${directory.path}/selected.mp4')
        .writeAsBytes([1, 2, 3]);
    session = VideoCaptureSession()
      ..select(LocalVideoSelection(XFile(file.path), finalizedByteLength: 3));
    player = FakeVideoPlayback();
  });
  tearDown(() async => directory.delete(recursive: true));

  Widget app(Widget home, {String locale = 'en', double scale = 1}) =>
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
  Future<void> settleFile(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump();
    }
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        VideoPreviewScreen(
          session: session,
          playbackFactory: (file) {
            expect(file.path, session.currentVideo!.file.path);
            return player;
          },
        ),
      ),
    );
    await settleFile(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets(
    'loading precedes initialization; paused surface metadata real duration and progress follow',
    (tester) async {
      player.initializeGate = Completer();
      await open(tester);
      expect(find.text('Loading video...'), findsOneWidget);
      expect(find.byKey(const Key('video-play-pause')), findsNothing);
      expect(find.text('selected.mp4'), findsOneWidget);
      expect(find.text('Recorded video'), findsOneWidget);
      player.initializeGate!.complete();
      await tester.pump();
      expect(find.byKey(const Key('real-video-surface-seam')), findsOneWidget);
      expect(find.text('Duration: 00:12'), findsOneWidget);
      expect(find.text('00:00 / 00:12'), findsOneWidget);
      expect(find.text('Minimum duration met.'), findsOneWidget);
      expect(player.plays, 0);
      expect(player.value.isPlaying, isFalse);
      expect(find.textContaining(directory.path), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.text('DEV'), findsNothing);
      await close(tester);
      expect(player.disposed, isTrue);
    },
  );
  testWidgets(
    'Play Pause resume and completion replay use the current position',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(player.plays, 1);
      expect(find.text('Pause'), findsOneWidget);
      player.update(
        player.value.copyWith(position: const Duration(seconds: 5)),
      );
      await tester.pump();
      expect(find.text('00:05 / 00:12'), findsOneWidget);
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(player.value.isPlaying, isFalse);
      expect(player.value.position, const Duration(seconds: 5));
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(player.seeks, isEmpty);
      expect(player.value.position, const Duration(seconds: 5));
      player.update(
        player.value.copyWith(
          position: player.duration,
          isPlaying: false,
          isCompleted: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(player.seeks, [Duration.zero]);
      expect(player.value.isPlaying, isTrue);
      expect(session.currentVideo!.finalizedByteLength, 3);
      await close(tester);
    },
  );
  testWidgets(
    'short video warns without removing selection or disabling local preview',
    (tester) async {
      player.duration = const Duration(milliseconds: 9999);
      final selected = session.currentVideo;
      await open(tester);
      expect(
        find.text('Video must be at least 10 seconds long.'),
        findsOneWidget,
      );
      expect(find.text('Minimum duration met.'), findsNothing);
      expect(find.text('Duration: 00:09'), findsOneWidget);
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(player.plays, 1);
      expect(session.currentVideo, same(selected));
      await close(tester);
    },
  );
  testWidgets('missing file never creates or initializes a player', (
    tester,
  ) async {
    await tester.runAsync(() => File(session.currentVideo!.file.path).delete());
    var creates = 0;
    await tester.pumpWidget(
      app(
        VideoPreviewScreen(
          session: session,
          playbackFactory: (_) {
            creates++;
            return player;
          },
        ),
      ),
    );
    await settleFile(tester);
    expect(find.text('Video unavailable'), findsOneWidget);
    expect(creates, 0);
    expect(player.initializes, 0);
    expect(find.byKey(const Key('video-play-pause')), findsNothing);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets(
    'initialization failure retains metadata and offers recoverable localized error',
    (tester) async {
      player.failInitialization = true;
      await open(tester);
      expect(
        find.text(
          'This video couldn’t be played. Try recording another video.',
        ),
        findsOneWidget,
      );
      expect(find.text('selected.mp4'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(player.disposed, isTrue);
      expect(session.currentVideo, isNotNull);
      final replacement = FakeVideoPlayback();
      player = replacement;
      await tester.tap(find.text('Retry'));
      await settleFile(tester);
      expect(find.byKey(const Key('real-video-surface-seam')), findsOneWidget);
      expect(replacement.plays, 0);
      await close(tester);
    },
  );
  testWidgets('Retry succeeds while failed player disposal stays pending', (
    tester,
  ) async {
    final failed = player
      ..failInitialization = true
      ..disposeGate = Completer<void>();
    await open(tester);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('couldn’t be played'), findsOneWidget);
    expect(failed.disposals, 1);
    expect(failed.disposed, isFalse);
    final replacement = FakeVideoPlayback();
    player = replacement;
    final retry = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Retry'),
    );
    await tester.runAsync(() async {
      retry.onPressed!();
      retry.onPressed!(); // Same callback before rebuild: must not start twice.
    });
    await settleFile(tester);
    expect(replacement.initializes, 1);
    expect(find.text('Loading video...'), findsNothing);
    expect(find.byKey(const Key('real-video-surface-seam')), findsOneWidget);
    expect(find.text('Duration: 00:12'), findsOneWidget);
    expect(find.text('00:00 / 00:12'), findsOneWidget);
    expect(find.text('selected.mp4'), findsOneWidget);
    expect(find.textContaining('couldn’t be played'), findsNothing);
    expect(replacement.plays, 0);
    expect(replacement.value.isPlaying, isFalse);
    // Even a callback already queued by the failed player is stale.
    failed.update(failed.value.copyWith(errorDescription: 'Late native error'));
    for (final listener in failed.registeredListeners) {
      listener();
    }
    await tester.pump();
    expect(find.textContaining('couldn’t be played'), findsNothing);
    await close(tester);
    expect(replacement.disposed, isTrue);
    expect(failed.disposeGate!.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('healthy-player disposal still precedes replacement creation', (
    tester,
  ) async {
    final healthy = player;
    await open(tester);
    healthy.disposeGate = Completer<void>();
    healthy.failPlay = true;
    await tester.tap(find.byKey(const Key('video-play-pause')));
    await tester.pump();
    player = FakeVideoPlayback();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(healthy.disposals, 1);
    expect(player.initializes, 0);
    expect(find.text('Loading video...'), findsOneWidget);
    healthy.disposeGate!.complete();
    await settleFile(tester);
    expect(healthy.disposed, isTrue);
    expect(player.initializes, 1);
    await close(tester);
    expect(player.disposed, isTrue);
  });

  testWidgets('repeated hanging failures bound outstanding broken players', (
    tester,
  ) async {
    player
      ..failInitialization = true
      ..disposeGate = Completer<void>();
    await open(tester);
    player = FakeVideoPlayback()
      ..failInitialization = true
      ..disposeGate = Completer<void>();
    await tester.tap(find.text('Retry'));
    await settleFile(tester);
    expect(player.initializes, 1);
    expect(find.text('Loading video...'), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Retry'))
          .onPressed,
      isNull,
    );
    await close(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed-player disposal exception permits a successful Retry', (
    tester,
  ) async {
    final failed = player
      ..failInitialization = true
      ..failDispose = true;
    await open(tester);
    expect(failed.disposals, 1);
    player = FakeVideoPlayback();
    await tester.tap(find.text('Retry'));
    await settleFile(tester);
    expect(find.byKey(const Key('real-video-surface-seam')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
    expect(player.disposed, isTrue);
  });

  for (final failOldInitialization in [false, true]) {
    testWidgets(
      'stale initialization ${failOldInitialization ? 'error' : 'success'} cannot overwrite a newer attempt',
      (tester) async {
        final old = player
          ..initializeGate = Completer<void>()
          ..disposeGate = Completer<void>()
          ..failInitialization = failOldInitialization;
        await open(tester);
        final newerSession = VideoCaptureSession()
          ..select(session.currentVideo!);
        // A changed selection while initialization is pending invalidates A.
        newerSession.select(
          LocalVideoSelection(
            session.currentVideo!.file,
            finalizedByteLength: 3,
          ),
        );
        player = FakeVideoPlayback();
        await tester.pumpWidget(
          app(
            VideoPreviewScreen(
              session: newerSession,
              playbackFactory: (_) => player,
            ),
          ),
        );
        await settleFile(tester);
        expect(
          find.byKey(const Key('real-video-surface-seam')),
          findsOneWidget,
        );
        old.initializeGate!.complete();
        await tester.pump();
        for (final listener in old.registeredListeners) {
          listener();
        }
        await tester.pump();
        expect(find.text('Loading video...'), findsNothing);
        expect(find.textContaining('couldn’t be played'), findsNothing);
        expect(player.value.isPlaying, isFalse);
        expect(player.initializes, 1);
        await close(tester);
        expect(player.disposed, isTrue);
        expect(old.disposeGate!.isCompleted, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'changed file keeps immutable metadata and previews actual current file',
    (tester) async {
      await tester.runAsync(
        () => File(session.currentVideo!.file.path).writeAsBytes([9]),
      );
      await open(tester);
      expect(
        find.text(
          'File has changed since recording. Size shown is from finalization.',
        ),
        findsOneWidget,
      );
      expect(player.initializes, 1);
      expect(session.currentVideo!.finalizedByteLength, 3);
      await close(tester);
    },
  );
  testWidgets(
    'inactive pauses; resume stays paused; leaving and reopening own distinct players',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(player.value.isPlaying, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(player.value.isPlaying, isFalse);
      final original = player;
      final selection = session.currentVideo;
      await close(tester);
      expect(original.disposed, isTrue);
      player = FakeVideoPlayback();
      await open(tester);
      expect(player.initializes, 1);
      expect(player.plays, 0);
      expect(session.currentVideo, same(selection));
      await close(tester);
    },
  );
  testWidgets(
    'late initialization after route disposal never renders or starts playback',
    (tester) async {
      player.initializeGate = Completer();
      await open(tester);
      await close(tester);
      expect(player.disposed, isTrue);
      player.initializeGate!.complete();
      await tester.pump();
      expect(player.plays, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'queued lifecycle pause wins a delayed Play without overlapping disposal',
    (tester) async {
      await open(tester);
      player.playGate = Completer();
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      player.playGate!.complete();
      await tester.pump();
      expect(player.value.isPlaying, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await close(tester);
      expect(player.disposed, isTrue);
    },
  );
  testWidgets(
    'playback command failure is localized and retains selected video',
    (tester) async {
      await open(tester);
      player.failPlay = true;
      await tester.tap(find.byKey(const Key('video-play-pause')));
      await tester.pump();
      expect(
        find.text(
          'This video couldn’t be played. Try recording another video.',
        ),
        findsOneWidget,
      );
      expect(session.currentVideo, isNotNull);
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );
  for (final size in [const Size(1920, 1080), const Size(1080, 1920)]) {
    testWidgets(
      'initialized $size preview fits Pixel 6a at scale 2 in Vietnamese',
      (tester) async {
        tester.view.physicalSize = const Size(412, 914);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        player.size = size;
        await tester.pumpWidget(
          app(
            VideoPreviewScreen(
              session: session,
              playbackFactory: (_) => player,
            ),
            locale: 'vi',
            scale: 2,
          ),
        );
        await settleFile(tester);
        await tester.scrollUntilVisible(
          find.byKey(const Key('video-play-pause')),
          100,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('real-video-surface-seam')),
          findsOneWidget,
        );
        await close(tester);
      },
    );
  }
}
