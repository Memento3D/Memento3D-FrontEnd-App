import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/models/model_viewer_data.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/screens/model_viewer_screen.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/widgets/three_d_model_viewer.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/widgets/model_viewer_webview.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

// Platform adapter records the real wrapper's bridge calls. No renderer or
// gesture/visual behavior is simulated or asserted by these widget tests.
class _Platform extends WebViewPlatform {
  final controllers = <_Controller>[];
  PlatformWebViewWidgetCreationParams? widgetParams;
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = _Controller(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _Navigation(params);
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    widgetParams = params;
    return _Viewport(params);
  }
}

class _Controller extends PlatformWebViewController {
  _Controller(super.params) : super.implementation();
  JavaScriptChannelParams? channel;
  int pageLoads = 0;
  final scripts = <String>[];
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> enableZoom(bool enabled) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    channel = params;
  }

  @override
  Future<void> removeJavaScriptChannel(String name) async {
    channel = null;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    pageLoads++;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    scripts.add(javaScript);
  }

  void event(Map<String, Object?> event) =>
      channel!.onMessageReceived(JavaScriptMessage(message: jsonEncode(event)));
  List<Map<String, dynamic>> get commands => scripts
      .where((script) => script.startsWith('window.receiveModelViewerCommand('))
      .map(
        (script) => jsonDecode(
          script.substring(
            'window.receiveModelViewerCommand('.length,
            script.length - 2,
          ),
        ) as Map<String, dynamic>,
      )
      .toList();
}

class _Navigation extends PlatformNavigationDelegate {
  _Navigation(super.params) : super.implementation();
  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback callback,
  ) async {}
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async {}
}

class _Viewport extends PlatformWebViewWidget {
  _Viewport(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: ValueKey('test-viewer-canvas'),
    color: Colors.black,
    child: SizedBox.expand(),
  );
}

const _url = 'https://example.test/host-model.glb';
const _data = ModelViewerData(
  modelName: 'Host supplied model with a deliberately very long descriptive name that must wrap safely',
  referenceCode: 'HOST-123',
  availability: ModelAvailability.processing,
  format: ModelFileFormat.glb,
  detail: ModelDetail.standard,
  completionPercentage: 63,
);

Widget _app({
  String modelUrl = _url,
  String locale = 'en',
  ModelViewerData data = _data,
  VoidCallback? onContinue,
  double scale = 1,
  bool enableDiagnostics = false,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ModelViewerScreen(
    modelUrl: modelUrl,
    data: data,
    onContinue: onContinue,
    enableDiagnostics: enableDiagnostics,
  ),
);

Future<_Controller> _start(WidgetTester tester, _Platform platform) async {
  // HttpServer.bind needs real asynchronous IO, while the UI clock stays fake.
  await tester.runAsync(() async {
    for (var i = 0; i < 100; i++) {
      if (platform.controllers.isNotEmpty &&
          platform.controllers.single.pageLoads == 1) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Viewer platform did not initialize');
  });
  await tester.pump();
  final controller = platform.controllers.single;
  controller.event({'type': 'viewerReady', 'version': 1});
  await tester.pump();
  return controller;
}

void main() {
  late _Platform platform;
  setUp(() {
    platform = _Platform();
    WebViewPlatform.instance = platform;
  });

  testWidgets(
    'optional diagnostics overlay accepts bridge data without recreating WebView',
    (tester) async {
      await tester.pumpWidget(_app(enableDiagnostics: true));
      final controller = await _start(tester, platform);
      final id = controller.commands.single['requestId'];
      controller.event({'type': 'modelLoaded', 'requestId': id});
      await tester.pump();
      expect(controller.commands.last, {
        'type': 'setDiagnostics',
        'requestId': id,
        'version': 1,
        'enabled': true,
      });
      controller.event({
        'type': 'modelStatistics',
        'version': 1,
        'requestId': id,
        'meshCount': 1,
        'triangleCount': 50000,
        'vertexCount': 38009,
      });
      controller.event({
        'type': 'performanceSample',
        'version': 1,
        'requestId': id,
        'fps': 50,
        'averageFps': 45,
        'minimumFps': 30,
        'frameCount': 90,
        'elapsedMs': 2000,
        'windowFrameCount': 50,
        'windowElapsedMs': 1000,
      });
      await tester.pump();
      expect(find.textContaining('Triangles 50000'), findsOneWidget);
      expect(
        find.textContaining('FPS 50.0 · Avg 45.0 · Min 30.0'),
        findsOneWidget,
      );
      final viewport = tester.getRect(find.byType(ModelViewerWebView));
      final overlay = tester.getRect(
        find.byKey(const ValueKey('viewer-diagnostics')),
      );
      final hit = tester.hitTestOnBinding(overlay.center);
      final canvas = tester.renderObject(
        find.byKey(const ValueKey('test-viewer-canvas')),
      );
      expect(viewport.contains(overlay.center), isTrue);
      expect(hit.path.any((entry) => identical(entry.target, canvas)), isTrue);
      await tester.pumpWidget(_app(enableDiagnostics: false));
      await tester.pump();
      expect(find.byKey(const ValueKey('viewer-diagnostics')), findsNothing);
      expect(platform.controllers, hasLength(1));
      expect(controller.pageLoads, 1);
      expect(controller.commands.last['enabled'], isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {});
    },
  );

  for (final locale in ['en', 'vi']) {
    for (final width in [320.0, 393.0, 480.0]) {
      testWidgets(
        '$locale screen at $width: identity, host facts, scrolling and Continue',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var continued = 0;
          await tester.pumpWidget(
            _app(
              locale: locale,
              scale: width == 320 ? 2 : 1,
              onContinue: () => continued++,
            ),
          );
          final controller = await _start(tester, platform);
          final strings = AppLocalizations.of(
            tester.element(find.byType(ModelViewerScreen)),
          )!;
          expect(find.text(_data.modelName), findsOneWidget);
          expect(
            find.text(strings.modelViewerReference('HOST-123')),
            findsOneWidget,
          );
          expect(
            tester
                .widget<ThreeDModelViewer>(find.byType(ThreeDModelViewer))
                .modelUrl,
            _url,
          );
          expect(controller.commands.single['modelUrl'], _url);
          expect(find.text(strings.modelViewerLoading), findsOneWidget);
          expect(find.text(strings.modelViewerModelReady), findsNothing);
          expect(find.text('63%'), findsOneWidget);
          expect(find.text(strings.detailStandard), findsOneWidget);
          expect(find.text(strings.modelViewerFormatGlb), findsOneWidget);
          expect(find.text(strings.modelViewerScreenTitle), findsOneWidget);
          expect(
            find.text(strings.modelViewerFormat.toUpperCase()),
            findsOneWidget,
          );
          expect(
            find.text(strings.modelViewerDetail.toUpperCase()),
            findsOneWidget,
          );
          expect(
            find.text(strings.modelViewerStatus.toUpperCase()),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('model-viewer-ready-badge')),
            findsOneWidget,
          );
          final viewer = tester.getRect(find.byType(ThreeDModelViewer));
          final resetRect = tester.getRect(
            find.byKey(const ValueKey('viewer-reset')),
          );
          expect(viewer.contains(resetRect.center), isTrue);
          expect(viewer.height, width == 320 ? 440 : 350);
          expect(
            tester
                .widget<IconButton>(find.byKey(const ValueKey('viewer-reset')))
                .onPressed,
            isNull,
          );
          final button = find.byKey(const ValueKey('model-viewer-continue'));
          await tester.ensureVisible(button);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(button);
          expect(continued, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async {});
        },
      );
    }
  }

  testWidgets(
    'controls use live bridge; rebuild/scroll preserves instance; loading/error stay separate from host facts',
    (tester) async {
      await tester.pumpWidget(_app());
      final controller = await _start(tester, platform);
      final id = controller.commands.single['requestId'];
      controller.event({'type': 'modelLoaded', 'requestId': id});
      await tester.pump();
      expect(find.text('3D model loaded'), findsNothing);
      expect(find.byKey(const ValueKey('viewer-diagnostics')), findsNothing);
      expect(find.text('Loading 3D model…'), findsNothing);
      final grid = find.byKey(const ValueKey('viewer-grid'));
      expect(tester.widget<FilterChip>(grid).selected, isFalse);
      final wire = find.byKey(const ValueKey('viewer-wireframe'));
      await tester.ensureVisible(wire);
      await tester.tap(wire);
      await tester.pump();
      expect(tester.widget<ChoiceChip>(wire).selected, isTrue);
      await tester.tap(find.byKey(const ValueKey('viewer-grid')));
      await tester.tap(find.byKey(const ValueKey('viewer-reset')));
      await tester.pump();
      expect(tester.widget<FilterChip>(grid).selected, isTrue);
      expect(
        controller.commands.any(
          (command) =>
              command['type'] == 'setDisplayMode' &&
              command['mode'] == 'wireframe',
        ),
        isTrue,
      );
      expect(
        controller.commands.any(
          (command) =>
              command['type'] == 'setGridVisible' && command['visible'] == true,
        ),
        isTrue,
      );
      expect(controller.commands.last['type'], 'resetView');
      expect(
        platform.widgetParams!.gestureRecognizers.single.type,
        EagerGestureRecognizer,
      );
      await tester.pumpWidget(
        _app(
          data: const ModelViewerData(
            modelName: 'Updated identity',
            availability: ModelAvailability.unavailable,
          ),
        ),
      );
      await tester.pump();
      expect(platform.controllers, hasLength(1));
      expect(controller.pageLoads, 1);
      expect(
        controller.commands.where((command) => command['type'] == 'loadModel'),
        hasLength(1),
      );
      expect(tester.widget<ChoiceChip>(wire).selected, isTrue);
      expect(find.text('100%'), findsNothing);
      expect(find.text('Unavailable'), findsNWidgets(3));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('model-viewer-continue')),
            )
            .onPressed,
        isNull,
      );
      // A bridge failure affects viewer feedback, never rewrites supplied metadata.
      final toolbar = find.byType(ThreeDModelViewer);
      expect(toolbar, findsOneWidget);
      controller.event({
        'type': 'loadError',
        'requestId': id,
        'code': 'parseFailed',
      });
      // A completed request correctly rejects late load errors. Start a replacement.
      await tester.pumpWidget(
        _app(modelUrl: 'https://example.test/replacement.glb'),
      );
      await tester.pump();
      final nextId = controller.commands.lastWhere(
        (command) => command['type'] == 'loadModel',
      )['requestId'];
      controller.event({
        'type': 'loadError',
        'requestId': nextId,
        'code': 'parseFailed',
      });
      await tester.pump();
      expect(find.text('The 3D model could not be loaded.'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('viewer-reset')))
            .onPressed,
        isNull,
      );
      expect(find.text('63%'), findsOneWidget);
      expect(platform.controllers, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {});
      expect(controller.scripts, contains('window.disposeModelViewer?.();'));
    },
  );

  for (final locale in ['en', 'vi']) {
    testWidgets(
      '$locale ready summary uses host facts; canvas remains reachable',
      (tester) async {
        await tester.pumpWidget(
          _app(
            locale: locale,
            data: const ModelViewerData(
              modelName: 'Development model',
              referenceCode: 'DEV-051',
              availability: ModelAvailability.ready,
              format: ModelFileFormat.glb,
              detail: ModelDetail.high,
              completionPercentage: 100,
            ),
          ),
        );
        final controller = await _start(tester, platform);
        final strings = AppLocalizations.of(
          tester.element(find.byType(ModelViewerScreen)),
        )!;
        expect(find.text(strings.modelViewerModelReady), findsNWidgets(2));
        expect(find.text(strings.modelViewerReadyExplanation), findsOneWidget);
        expect(find.text(strings.modelViewerDetailHigh), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        // Host ready facts do not hide a pending renderer load.
        expect(find.text(strings.modelViewerLoading), findsOneWidget);
        controller.event({
          'type': 'modelLoaded',
          'requestId': controller.commands.single['requestId'],
        });
        await tester.pump();
        expect(find.text(strings.modelViewerLoaded), findsNothing);
        expect(find.text(strings.modelViewerLoading), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('model-viewer-continue')),
              )
              .onPressed,
          isNull,
        );
        final viewport = tester.getRect(find.byType(ModelViewerWebView));
        // Decorative hint/status overlays must pass input through to the canvas.
        final hit = tester.hitTestOnBinding(
          viewport.bottomCenter - const Offset(0, 25),
        );
        final canvas = tester.renderObject(
          find.byKey(const ValueKey('test-viewer-canvas')),
        );
        expect(
          hit.path.any((entry) => identical(entry.target, canvas)),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {});
      },
    );
  }
}
