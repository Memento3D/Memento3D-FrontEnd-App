import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/controllers/model_viewer_controller.dart';

void main() {
  late ModelViewerController controller;
  setUp(() {
    controller = ModelViewerController();
    controller.receiveMessage('{"type":"viewerReady","version":1}');
  });
  tearDown(() => controller.dispose());
  String load([String? url = 'https://example.test/model.glb']) =>
      (jsonDecode(controller.loadModel(url)!) as Map)['requestId'] as String;
  void event(String type, String id, [Map<String, Object?> data = const {}]) =>
      controller.receiveMessage(
        jsonEncode({'type': type, 'requestId': id, ...data}),
      );

  test('load command round trips quotes and script-like URL data', () {
    const url = 'https://example.test/";alert(1)//model.glb';
    final command = jsonDecode(controller.loadModel(url)!);
    expect(command, {'type': 'loadModel', 'requestId': '1', 'modelUrl': url});
    expect(controller.status, ModelViewerStatus.loading);
  });
  test(
    'known and unknown progress; download completion is not model completion',
    () {
      final id = load();
      event('loadingProgress', id, {'loadedBytes': 50, 'totalBytes': 100});
      expect(controller.state.progress, .5);
      event('loadingProgress', id, {'loadedBytes': 100, 'totalBytes': null});
      expect(controller.state.progress, isNull);
      event('loadingProgress', id, {'loadedBytes': 100, 'totalBytes': 100});
      expect(controller.state.progress, 1);
      expect(controller.status, ModelViewerStatus.loading);
      event('modelLoaded', id);
      expect(controller.status, ModelViewerStatus.loaded);
      event('loadError', id, {'code': 'parseFailed'});
      expect(controller.status, ModelViewerStatus.loaded);
    },
  );
  test('replacement rejects old progress, completion and error', () {
    final first = load();
    event('modelLoaded', first);
    final second = load('asset:///assets/another.glb');
    expect(second, isNot(first));
    expect(controller.status, ModelViewerStatus.loading);
    for (final type in ['loadingProgress', 'modelLoaded', 'loadError']) {
      event(type, first, {
        'loadedBytes': 10,
        'totalBytes': 10,
        'code': 'parseFailed',
      });
      expect(controller.status, ModelViewerStatus.loading);
      expect(controller.state.progress, isNull);
    }
    event('loadError', second, {'code': 'parseFailed'});
    expect(controller.state.errorCode, 'parseFailed');
    expect(controller.status, ModelViewerStatus.loadFailure);
    expect(load(), isNot(second));
    expect(controller.status, ModelViewerStatus.loading);
  });
  test('malformed events and invalid byte counts are ignored', () {
    final id = load();
    for (final message in ['{', '[]', 'null', '{"type":"modelLoaded"}']) {
      controller.receiveMessage(message);
    }
    event('unknown', id);
    for (final bytes in [
      {'loadedBytes': -1, 'totalBytes': 10},
      {'loadedBytes': 1, 'totalBytes': 0},
      {'loadedBytes': 11, 'totalBytes': 10},
      {'loadedBytes': '1', 'totalBytes': 10},
    ]) {
      event('loadingProgress', id, bytes);
    }
    expect(controller.status, ModelViewerStatus.loading);
    expect(controller.state.loadedBytes, 0);
    event('loadError', id, {'code': 'private stack trace'});
    expect(controller.state.errorCode, 'resourceLoadFailed');
  });
  test('null URL clears and invalidates a pending request', () {
    final previous = load();
    load(null);
    event('modelLoaded', previous);
    expect(controller.status, ModelViewerStatus.ready);
  });
  test('load before ready and after disposal sends no command', () {
    final other = ModelViewerController();
    expect(other.loadModel('https://example.test/a.glb'), isNull);
    other.receiveMessage('{"type":"viewerReady","version":1}');
    final id = (jsonDecode(
      other.loadModel('https://example.test/a.glb')!,
    ) as Map)['requestId'];
    other.dispose();
    other.receiveMessage(jsonEncode({'type': 'modelLoaded', 'requestId': id}));
    expect(other.status, ModelViewerStatus.loading);
    expect(other.loadModel(null), isNull);
  });
}
