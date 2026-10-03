import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/controllers/model_viewer_controller.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/widgets/model_viewer_toolbar.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

String begin(ModelViewerController controller) {
  controller.receiveMessage('{"type":"viewerReady","version":1}');
  return (jsonDecode(controller.loadModel('asset:///assets/example.glb')!)
          as Map)['requestId']
      as String;
}

void complete(ModelViewerController controller, String id) => controller
    .receiveMessage(jsonEncode({'type': 'modelLoaded', 'requestId': id}));

void main() {
  test('toolbar serializes typed commands with request identity; replay on replacement', () async {
    final controller = ModelViewerController();
    final messages = <Map<String, dynamic>>[];
    final subscription = controller.commands.listen(
      (message) => messages.add(jsonDecode(message) as Map<String, dynamic>),
    );
    addTearDown(() async {
      await subscription.cancel();
      controller.dispose();
    });
    expect(controller.displayMode, DisplayMode.shaded);
    expect(controller.gridVisible, isFalse);
    controller.resetView();
    controller.setDisplayMode(DisplayMode.wireframe);
    controller.setGridVisible(true);
    expect(messages, isEmpty);
    final id = begin(controller);
    controller.resetView();
    expect(messages, isEmpty);
    complete(controller, id);
    messages.clear();
    controller.setDisplayMode(DisplayMode.wireframe);
    controller.setGridVisible(true);
    controller.resetView();
    expect(messages, [
      {'type': 'setDisplayMode', 'requestId': id, 'mode': 'wireframe'},
      {'type': 'setGridVisible', 'requestId': id, 'visible': true},
      {'type': 'resetView', 'requestId': id},
    ]);
    final next = begin(controller);
    messages.clear();
    expect(controller.controlsEnabled, isFalse);
    controller.setDisplayMode(DisplayMode.shaded);
    controller.setGridVisible(false);
    controller.resetView();
    expect(messages, isEmpty);
    complete(controller, id);
    expect(messages, isEmpty);
    complete(controller, next);
    expect(messages, [
      {'type': 'setDisplayMode', 'requestId': next, 'mode': 'wireframe'},
      {'type': 'setGridVisible', 'requestId': next, 'visible': true},
    ]);
    controller.failCommand(id);
    expect(controller.controlsEnabled, isTrue);
    controller.failCommand(next);
    expect(controller.controlsEnabled, isFalse);
    messages.clear();
    controller.resetView();
    expect(messages, isEmpty);
  });

  test('error and disposal keep control commands unavailable', () {
    final controller = ModelViewerController();
    final id = begin(controller);
    controller.failLoad(id, 'parseFailed');
    controller.setGridVisible(true);
    controller.setDisplayMode(DisplayMode.wireframe);
    controller.resetView();
    expect(controller.gridVisible, isFalse);
    expect(controller.displayMode, DisplayMode.shaded);
    controller.dispose();
    controller.resetView();
    controller.setGridVisible(true);
    expect(controller.controlsEnabled, isFalse);
  });

  for (final locale in ['en', 'vi']) {
    testWidgets(
      '$locale toolbar labels, selection, loading guard and narrow layout',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ModelViewerController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: ModelViewerToolbar(controller: controller)),
          ),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(ModelViewerToolbar)),
        )!;
        expect(find.text(strings.modelViewerShaded), findsOneWidget);
        expect(find.text(strings.modelViewerWireframe), findsOneWidget);
        expect(find.text(strings.modelViewerGrid), findsOneWidget);
        expect(find.text(strings.modelViewerInteractionHint), findsOneWidget);
        final reset = find.byKey(const ValueKey('viewer-reset'));
        expect(tester.widget<IconButton>(reset).onPressed, isNull);
        final id = begin(controller);
        complete(controller, id);
        await tester.pump();
        expect(tester.widget<IconButton>(reset).onPressed, isNotNull);
        expect(
          tester.widget<IconButton>(reset).tooltip,
          strings.modelViewerReset,
        );
        await tester.tap(find.byKey(const ValueKey('viewer-wireframe')));
        await tester.pump();
        expect(controller.displayMode, DisplayMode.wireframe);
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('viewer-wireframe')),
              )
              .selected,
          isTrue,
        );
        await tester.tap(find.byKey(const ValueKey('viewer-grid')));
        await tester.pump();
        expect(controller.gridVisible, isTrue);
        final grid = tester.widget<FilterChip>(
          find.byKey(const ValueKey('viewer-grid')),
        );
        expect(grid.selected, isTrue);
        expect(grid.avatar, isA<Icon>());
        expect(
          grid.selectedColor,
          Theme.of(tester.element(find.byType(ModelViewerToolbar)))
              .colorScheme
              .primary,
        );
        await tester.tap(find.byKey(const ValueKey('viewer-shaded')));
        await tester.tap(find.byKey(const ValueKey('viewer-grid')));
        await tester.pump();
        expect(controller.displayMode, DisplayMode.shaded);
        expect(
          tester
              .widget<ChoiceChip>(find.byKey(const ValueKey('viewer-shaded')))
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<FilterChip>(find.byKey(const ValueKey('viewer-grid')))
              .selected,
          isFalse,
        );
        begin(controller);
        await tester.pump();
        expect(tester.widget<IconButton>(reset).onPressed, isNull);
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('viewer-wireframe')),
              )
              .onSelected,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
