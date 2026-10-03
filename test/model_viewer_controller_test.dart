import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/controllers/model_viewer_controller.dart';

void main() {
  test('valid version 1 ready message transitions once', () {
    final controller = ModelViewerController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    expect(controller.status, ModelViewerStatus.initializing);
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    expect(controller.status, ModelViewerStatus.ready);
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    expect(notifications, 1);
    controller.failInitialization();
    expect(controller.status, ModelViewerStatus.ready);
  });

  for (final message in [
    'not json',
    '{',
    'null',
    '[]',
    '1',
    '"viewerReady"',
    '{"type":"unknown","version":1}',
    '{"type":"viewerReady"}',
    '{"type":"viewerReady","version":2}',
    '{"type":"viewerReady","version":"1"}',
    '{"type":"viewerReady","version":1.0}',
  ]) {
    test('ignores invalid or unsupported message: $message', () {
      final controller = ModelViewerController();
      addTearDown(controller.dispose);
      controller.receiveMessage(message);
      expect(controller.status, ModelViewerStatus.initializing);
    });
  }

  testWidgets('missing handshake times out; late ready cannot hide error', (
    tester,
  ) async {
    final controller = ModelViewerController(
      timeout: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.status, ModelViewerStatus.initializationError);
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    expect(controller.status, ModelViewerStatus.initializationError);
  });

  testWidgets('ready cancels timeout', (tester) async {
    final controller = ModelViewerController(
      timeout: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    await tester.pump(const Duration(seconds: 2));
    expect(controller.status, ModelViewerStatus.ready);
  });

  testWidgets('dispose cancels timeout and ignores late messages', (
    tester,
  ) async {
    final controller = ModelViewerController(
      timeout: const Duration(seconds: 1),
    );
    controller.dispose();
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    await tester.pump(const Duration(seconds: 2));
    expect(controller.status, ModelViewerStatus.initializing);
  });

  test('platform initialization failure is terminal', () {
    final controller = ModelViewerController();
    addTearDown(controller.dispose);
    controller.failInitialization();
    expect(controller.status, ModelViewerStatus.initializationError);
    controller.receiveMessage('{"type":"viewerReady","version":1}');
    expect(controller.status, ModelViewerStatus.initializationError);
  });
}
