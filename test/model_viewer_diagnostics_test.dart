import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/controllers/model_viewer_controller.dart';

void main() {
  late ModelViewerController controller;
  late List<Map<String, dynamic>> commands;
  setUp(() {
    controller = ModelViewerController(enableDiagnostics: true);
    commands = [];
    final subscription = controller.commands.listen(
      (message) => commands.add(jsonDecode(message) as Map<String, dynamic>),
    );
    addTearDown(() async {
      await subscription.cancel();
      controller.dispose();
    });
    controller.receiveMessage('{"type":"viewerReady","version":1}');
  });
  String load() =>
      (jsonDecode(controller.loadModel('https://example.test/model.glb')!)
              as Map)['requestId']
          as String;
  void event(
    String type,
    String id, [
    Map<String, Object?> fields = const {},
  ]) => controller.receiveMessage(
    jsonEncode({'type': type, 'version': 1, 'requestId': id, ...fields}),
  );
  const stats = {'meshCount': 1, 'triangleCount': 50000, 'vertexCount': 38009};
  const sample = {
    'fps': 50,
    'averageFps': 45,
    'minimumFps': 30,
    'frameCount': 90,
    'elapsedMs': 2000,
    'windowFrameCount': 50,
    'windowElapsedMs': 1000,
  };

  test('opt-in sends versioned enable after modelLoaded; typed events preserve loaded state', () {
    final id = load();
    expect(commands, isEmpty);
    event('modelLoaded', id);
    expect(commands.last, {
      'type': 'setDiagnostics',
      'requestId': id,
      'version': 1,
      'enabled': true,
    });
    event('modelStatistics', id, stats);
    event('performanceSample', id, sample);
    expect(controller.statistics!.triangleCount, 50000);
    expect(controller.statistics!.vertexCount, 38009);
    expect(controller.statistics!.meshCount, 1);
    expect(controller.performanceSample!.fps, 50);
    expect(controller.performanceSample!.elapsedMs, 2000);
    expect(controller.status, ModelViewerStatus.loaded);
    expect(controller.controlsEnabled, isTrue);
  });
  test('replacement clears diagnostics and ignores stale/loading events', () {
    final first = load();
    event('modelLoaded', first);
    event('modelStatistics', first, stats);
    event('performanceSample', first, sample);
    final second = load();
    expect(controller.statistics, isNull);
    expect(controller.performanceSample, isNull);
    event('modelStatistics', second, stats);
    expect(controller.statistics, isNull);
    event('modelLoaded', second);
    event('modelStatistics', first, stats);
    event('performanceSample', first, sample);
    expect(controller.statistics, isNull);
    expect(controller.performanceSample, isNull);
    expect(commands.last['requestId'], second);
  });
  test('malformed/versioned diagnostic payloads and regressive samples are ignored', () {
    final id = load();
    event('modelLoaded', id);
    for (final invalid in [
      {...stats, 'triangleCount': -1},
      {...stats, 'vertexCount': 1.5},
      {...stats, 'version': 2},
      {...stats, 'version': 1.0},
      {'meshCount': 1},
    ]) {
      event('modelStatistics', id, invalid);
    }
    expect(controller.statistics, isNull);
    for (final invalid in [
      {...sample, 'fps': '50'},
      {...sample, 'frameCount': -1},
      {...sample, 'elapsedMs': 0},
      {...sample, 'windowElapsedMs': 999},
      {...sample, 'windowFrameCount': 91},
      {...sample, 'version': 2},
    ]) {
      event('performanceSample', id, invalid);
    }
    expect(controller.performanceSample, isNull);
    event('performanceSample', id, sample);
    final accepted = controller.performanceSample;
    event('performanceSample', id, {...sample, 'frameCount': 80});
    expect(controller.performanceSample, same(accepted));
  });
  test('disable clears diagnostics, ignores events and stops re-enabling replacements', () {
    final id = load();
    event('modelLoaded', id);
    event('modelStatistics', id, stats);
    controller.setDiagnosticsEnabled(false);
    expect(commands.last['enabled'], isFalse);
    expect(controller.statistics, isNull);
    event('modelStatistics', id, stats);
    expect(controller.statistics, isNull);
    commands.clear();
    final next = load();
    event('modelLoaded', next);
    expect(
      commands.any((command) => command['type'] == 'setDiagnostics'),
      isFalse,
    );
    controller.setDiagnosticsEnabled(true);
    expect(commands.last['enabled'], isTrue);
  });
  test('production default never enables/accepts development diagnostics', () {
    final ordinary = ModelViewerController();
    addTearDown(ordinary.dispose);
    final emitted = <String>[];
    final subscription = ordinary.commands.listen(emitted.add);
    addTearDown(subscription.cancel);
    ordinary.receiveMessage('{"type":"viewerReady","version":1}');
    final id = (jsonDecode(
      ordinary.loadModel('https://example.test/a.glb')!,
    ) as Map)['requestId'];
    ordinary.receiveMessage(
      jsonEncode({'type': 'modelLoaded', 'requestId': id}),
    );
    ordinary.receiveMessage(
      jsonEncode({
        'type': 'modelStatistics',
        'version': 1,
        'requestId': id,
        ...stats,
      }),
    );
    expect(ordinary.diagnosticsEnabled, isFalse);
    expect(ordinary.statistics, isNull);
    expect(
      emitted.any((message) => message.contains('setDiagnostics')),
      isFalse,
    );
  });
}
