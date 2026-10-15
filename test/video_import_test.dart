import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/screens/video_capture_session.dart';
import 'package:memento3d_frontend_app/screens/video_file_probe.dart';
import 'package:memento3d_frontend_app/screens/video_import_coordinator.dart';
import 'package:memento3d_frontend_app/screens/video_import_policy.dart';
import 'package:memento3d_frontend_app/screens/video_import_storage.dart';
import 'package:memento3d_frontend_app/screens/video_picker.dart';

import 'fake_video_import.dart';

void main() {
  late VideoCaptureSession session;
  late LocalVideoSelection original;
  late FakeVideoPicker picker;
  late FakeVideoFileProbe probe;
  late FakeVideoImportStorage storage;
  late VideoImportCoordinator coordinator;
  var current = true;
  const candidate = VideoImportCandidate(
    path: '/local/B.mp4',
    displayName: 'B.mp4',
  );
  Future<VideoImportResult> import() =>
      coordinator.importVideo(isCurrent: () => current);
  setUp(() {
    current = true;
    original = LocalVideoSelection(
      XFile('/local/A.mp4'),
      finalizedByteLength: 3,
    );
    session = VideoCaptureSession()..select(original);
    picker = FakeVideoPicker()..candidate = candidate;
    probe = FakeVideoFileProbe();
    storage = FakeVideoImportStorage();
    coordinator = VideoImportCoordinator(
      session: session,
      picker: picker,
      probe: probe,
      storage: storage,
    );
  });
  tearDown(() => coordinator.dispose());

  for (final name in [
    'video.mp4',
    'video.mov',
    'video.avi',
    'VIDEO.MP4',
    'clip.Mov',
    'scan.AVI',
  ]) {
    test('$name accepted with imported metadata', () async {
      picker.candidate = VideoImportCandidate(
        path: candidate.path,
        displayName: name,
      );
      final revision = session.revision;
      expect((await import()).replaced, isTrue);
      expect(session.revision, revision + 1);
      expect(session.currentVideo!.source, LocalVideoSource.imported);
      expect(session.currentVideo!.displayName, name);
      expect(session.currentVideo!.finalizedByteLength, 3);
    });
  }
  for (final name in ['video.mkv', 'video', '.mp4', 'video.mp4.exe']) {
    test('$name rejected before filesystem access', () async {
      picker.candidate = VideoImportCandidate(
        path: candidate.path,
        displayName: name,
      );
      expect((await import()).error, VideoImportError.format);
      expect(session.currentVideo, same(original));
      expect(probe.calls, isEmpty);
    });
  }
  for (final size in [2147483647, 2147483648, 2147483649]) {
    test('actual $size byte boundary', () async {
      probe.facts = VideoFileFacts(byteLength: size, readable: true);
      final result = await import();
      expect(result.replaced, size <= VideoImportPolicy.maximumBytes);
      if (size > VideoImportPolicy.maximumBytes) {
        expect(result.error, VideoImportError.size);
        expect(session.currentVideo, same(original));
        expect(storage.calls, 0);
      }
    });
  }
  for (final size in <int?>[null, 0, -1]) {
    test('unknown/invalid $size length rejected', () async {
      probe.facts = VideoFileFacts(byteLength: size, readable: true);
      expect((await import()).error, VideoImportError.invalidSize);
      expect(session.currentVideo, same(original));
    });
  }
  test('inaccessible file preserves A', () async {
    probe.facts = const VideoFileFacts(byteLength: 3);
    expect((await import()).error, VideoImportError.unavailable);
    expect(session.currentVideo, same(original));
  });
  test('cancellation preserves A and clears busy', () async {
    picker.candidate = null;
    expect((await import()).error, isNull);
    expect(session.currentVideo, same(original));
    expect(coordinator.busy, isFalse);
  });
  test('picker exception preserves A and allows retry', () async {
    picker.fail = true;
    expect((await import()).error, VideoImportError.picker);
    expect(session.currentVideo, same(original));
    picker.fail = false;
    expect((await import()).replaced, isTrue);
  });
  test('duplicate taps invoke picker once', () async {
    picker.gate = Completer();
    final pending = import();
    expect(coordinator.busy, isTrue);
    expect((await import()).replaced, isFalse);
    expect(picker.calls, 1);
    picker.gate!.complete(null);
    await pending;
  });
  test('disposed owner late result does not commit', () async {
    picker.gate = Completer();
    final pending = import();
    current = false;
    picker.gate!.complete(candidate);
    expect((await pending).replaced, isFalse);
    expect(session.currentVideo, same(original));
  });
  test(
    'coordinator disposal ignores late exception and notifications',
    () async {
      final other = VideoImportCoordinator(
        session: session,
        picker: picker,
        probe: probe,
        storage: storage,
      );
      picker.gate = Completer();
      final pending = other.importVideo(isCurrent: () => true);
      other.dispose();
      picker.gate!.completeError(StateError('late'));
      expect((await pending).error, isNull);
      expect(session.currentVideo, same(original));
    },
  );
  test('invalidated picker result is stale', () async {
    picker.gate = Completer();
    final pending = import();
    coordinator.invalidate();
    picker.gate!.complete(candidate);
    expect((await pending).replaced, isFalse);
    expect(probe.calls, isEmpty);
  });
  test('newer recorded selection defeats pending import', () async {
    picker.gate = Completer();
    final pending = import();
    final newer = LocalVideoSelection(XFile('new.mp4'), finalizedByteLength: 9);
    session.replace(newer);
    picker.gate!.complete(candidate);
    await pending;
    expect(session.currentVideo, same(newer));
  });
  test('stale probe never promotes', () async {
    probe.gate = Completer();
    final pending = import();
    await Future<void>.delayed(Duration.zero);
    coordinator.invalidate();
    probe.gate!.complete(const VideoFileFacts(byteLength: 3, readable: true));
    await pending;
    expect(storage.calls, 0);
  });
  test('stale promotion cannot replace A', () async {
    storage.gate = Completer();
    final pending = import();
    await Future<void>.delayed(Duration.zero);
    coordinator.invalidate();
    storage.gate!.complete('/promoted/B.mp4');
    await pending;
    expect(session.currentVideo, same(original));
    expect(probe.calls.length, 1);
  });
  test('storage failure preserves A', () async {
    storage.fail = true;
    expect((await import()).error, VideoImportError.storage);
    expect(session.currentVideo, same(original));
  });
  test('changed/unavailable final path fails before commit', () async {
    storage.gate = Completer();
    final pending = import();
    await Future<void>.delayed(Duration.zero);
    probe.paths['/promoted/B.mp4'] = const VideoFileFacts(
      byteLength: 4,
      readable: true,
    );
    storage.gate!.complete('/promoted/B.mp4');
    expect((await pending).error, VideoImportError.storage);
    expect(session.currentVideo, same(original));
  });
  test('owner unavailable refuses picker', () async {
    current = false;
    await import();
    expect(picker.calls, 0);
  });

  group('real local filesystem and iOS relocation', () {
    late Directory root;
    setUp(
      () async =>
          root = await Directory.systemTemp.createTemp('c3_storage_test_'),
    );
    tearDown(() async => root.delete(recursive: true));
    test('probe rejects missing file, directory and zero-byte file', () async {
      final localProbe = LocalVideoFileProbe();
      expect(
        (await localProbe.inspect('${root.path}/missing')).readable,
        isFalse,
      );
      expect((await localProbe.inspect(root.path)).readable, isFalse);
      final empty = await File('${root.path}/empty').create();
      expect(
        VideoImportPolicy.validate(await localProbe.inspect(empty.path)),
        isNotNull,
      );
    });
    test('probe gets 2GiB length without full byte loading', () async {
      final file = File('${root.path}/large.mp4');
      final handle = await file.open(mode: FileMode.write);
      await handle.truncate(VideoImportPolicy.maximumBytes);
      await handle.close();
      final facts = await LocalVideoFileProbe().inspect(file.path);
      expect(facts.byteLength, VideoImportPolicy.maximumBytes);
      expect(facts.readable, isTrue);
    });
    test('Android storage retains original local path', () async {
      expect(
        await LocalVideoImportStorage(relocate: false).promote(candidate),
        candidate.path,
      );
    });
    test(
      'iOS accepted A is moved; same-name invalid B cannot alter A',
      () async {
        final raw = File('${root.path}/clip.mp4');
        await raw.writeAsBytes([1, 2, 3]);
        picker.candidate = VideoImportCandidate(
          path: raw.path,
          displayName: 'clip.mp4',
        );
        final local = VideoImportCoordinator(
          session: session,
          picker: picker,
          probe: LocalVideoFileProbe(),
          storage: LocalVideoImportStorage(relocate: true, temporaryRoot: root),
        );
        addTearDown(local.dispose);
        expect(
          (await local.importVideo(isCurrent: () => true)).replaced,
          isTrue,
        );
        final a = session.currentVideo!;
        expect(a.file.path, isNot(raw.path));
        expect(a.displayName, 'clip.mp4');
        expect(await raw.exists(), isFalse);
        await raw.writeAsBytes(
          [],
        ); // Picker overwrites its own same-name namespace.
        expect(
          (await local.importVideo(isCurrent: () => true)).replaced,
          isFalse,
        );
        expect(session.currentVideo, same(a));
        expect(await File(a.file.path).readAsBytes(), [1, 2, 3]);
        await raw.writeAsBytes([4, 5, 6]);
        expect(
          (await local.importVideo(isCurrent: () => true)).replaced,
          isTrue,
        );
        final b = session.currentVideo!;
        expect(b.file.path, isNot(a.file.path));
        expect(b.displayName, a.displayName);
        expect(await File(a.file.path).readAsBytes(), [1, 2, 3]);
        expect(await File(b.file.path).readAsBytes(), [4, 5, 6]);
      },
    );
    test('iOS rename failure rejects without modifying A', () async {
      final local = VideoImportCoordinator(
        session: session,
        picker: picker,
        probe: probe,
        storage: LocalVideoImportStorage(relocate: true, temporaryRoot: root),
      );
      addTearDown(local.dispose);
      expect(
        (await local.importVideo(isCurrent: () => true)).error,
        VideoImportError.storage,
      );
      expect(session.currentVideo, same(original));
    });
  });
}
