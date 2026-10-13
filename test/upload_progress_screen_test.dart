import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/upload_progress_snapshot.dart';
import 'package:memento3d_frontend_app/features/uploads/presentation/controllers/upload_progress_controller.dart';
import 'package:memento3d_frontend_app/features/uploads/presentation/screens/upload_progress_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/main_upload_progress_preview.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';

import 'support/controlled_upload_progress_source.dart';

void main() {
  late ControlledUploadProgressSource source;
  late UploadProgressController controller;
  late CaptureSession session;
  var completions = 0;

  setUp(() {
    source = ControlledUploadProgressSource(uploadSnapshot());
    controller = UploadProgressController(source: source);
    session = CaptureSession();
    completions = 0;
  });
  tearDown(() async {
    controller.dispose();
    await source.dispose();
  });

  Future<void> mount(
    WidgetTester tester, {
    String locale = 'en',
    double scale = 1,
    String? name,
    VoidCallback? completion,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: UploadProgressScreen(
          controller: controller,
          session: session,
          objectName: name,
          onUploadCompleted: completion ?? () => completions++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> show(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 180);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> startWith(UploadProgressSnapshot snapshot) async {
    controller.dispose();
    await source.dispose();
    source = ControlledUploadProgressSource(snapshot);
    controller = UploadProgressController(source: source);
  }

  testWidgets(
    'uploading shows exact confirmed percentage, units, speed and ETA',
    (tester) async {
      await mount(tester);
      expect(find.text('68%'), findsWidgets);
      expect(find.text('34 / 50 parts uploaded'), findsOneWidget);
      expect(find.text('2.4 MB/s'), findsOneWidget);
      expect(find.text('~1m 20s'), findsOneWidget);
      expect(find.text('34 / 50'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('upload-progress-bar')),
            )
            .value,
        0.68,
      );
      expect(completions, 0);
    },
  );

  for (final confirmed in [0, 1, 198, 199, 200]) {
    testWidgets('non-completed $confirmed / 200 never overstates progress', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await startWith(uploadSnapshot(confirmed: confirmed, total: 200));
      await mount(tester);
      final expected = confirmed < 198 ? '0%' : '99%';
      expect(
        tester.widget<Text>(find.byKey(const Key('upload-percentage'))).data,
        expected,
      );
      expect(find.text('100%'), findsNothing);
      expect(
        find
            .ancestor(
              of: find.byKey(const Key('upload-progress-bar')),
              matching: find.byType(Semantics),
            )
            .first,
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find
                  .ancestor(
                    of: find.byKey(const Key('upload-progress-bar')),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .value,
        expected,
      );
      expect(controller.state.confirmedProgress, confirmed / 200);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('upload-progress-bar')),
            )
            .value,
        lessThanOrEqualTo(controller.state.confirmedProgress),
      );
      semantics.dispose();
    });
  }

  testWidgets('explicit completed 200 / 200 renders and announces 100%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await startWith(
      uploadSnapshot(
        status: UploadProgressStatus.completed,
        confirmed: 200,
        total: 200,
      ),
    );
    await mount(tester);
    expect(find.text('100%'), findsWidgets);
    expect(
      tester
          .getSemantics(
            find
                .ancestor(
                  of: find.byKey(const Key('upload-progress-bar')),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .value,
      '100%',
    );
    semantics.dispose();
  });

  for (final stale in [false, true]) {
    for (final photoCount in [2, 4]) {
      testWidgets(
        'completed normalizes $photoCount real photos with ${stale ? "stale" : "omitted"} statuses',
        (tester) async {
          for (var i = 0; i < photoCount; i++) {
            session.addPhoto(XFile(''));
          }
          final statuses = stale
              ? const [
                  UploadPhotoStatus.current,
                  UploadPhotoStatus.pending,
                  UploadPhotoStatus.completed,
                  UploadPhotoStatus.completed,
                ]
              : const <UploadPhotoStatus>[];
          await startWith(
            UploadProgressSnapshot(
              status: UploadProgressStatus.completed,
              confirmedUnits: 50,
              totalUnits: 50,
              photoStatuses: statuses,
            ),
          );
          await mount(tester);
          await show(tester, find.byKey(const Key('upload-photo-3')));
          final strings = AppLocalizations.of(
            tester.element(find.byType(UploadProgressScreen)),
          )!;

          for (var i = 0; i < 4; i++) {
            expect(
              find.descendant(
                of: find.byKey(ValueKey('upload-photo-$i')),
                matching: find.byIcon(Icons.check),
              ),
              i < photoCount ? findsOneWidget : findsNothing,
            );
            final label = strings.uploadPhotoDescription(
              strings.photoNumber(i + 1),
              i < photoCount
                  ? strings.uploadPhotoCompleted
                  : strings.uploadPhotoPending,
            );
            final tileSemantics = find
                .ancestor(
                  of: find.byKey(ValueKey('upload-photo-$i')),
                  matching: find.byType(Semantics),
                )
                .first;
            expect(
              tester.widget<Semantics>(tileSemantics).properties.label,
              label,
            );
            expect(
              find.descendant(
                of: tileSemantics,
                matching: find.text(strings.uploadPhotoCompleted),
              ),
              i < photoCount ? findsOneWidget : findsNothing,
            );
          }
          expect(controller.state.photoStatuses, statuses);
          expect(find.byIcon(Icons.pause), findsNothing);
        },
      );
    }
  }

  testWidgets(
    'network loss freezes progress, suppresses metrics and pauses current photo',
    (tester) async {
      await mount(tester);
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.waitingForNetwork),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting to reconnect'), findsOneWidget);
      expect(find.text('Waiting for connection'), findsOneWidget);
      expect(find.text('34 / 50 parts uploaded'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('upload-progress-bar')),
            )
            .value,
        0.68,
      );
      expect(find.text('2.4 MB/s'), findsNothing);
      expect(find.text('~1m 20s'), findsNothing);
      expect(find.text('Waiting'), findsOneWidget);
      await show(tester, find.text('Paused'));
      expect(find.text('Paused'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsNothing);
      expect(find.byKey(const Key('upload-retry')), findsNothing);
    },
  );

  testWidgets(
    'reconciliation keeps confirmed position without endpoint jargon',
    (tester) async {
      source.emit(uploadSnapshot(status: UploadProgressStatus.reconciling));
      await mount(tester);
      expect(find.text('Restoring your upload session'), findsOneWidget);
      expect(find.text('34 / 50 parts uploaded'), findsOneWidget);
      expect(find.text('2.4 MB/s'), findsNothing);
      expect(find.textContaining('GET'), findsNothing);
      expect(find.textContaining('missing_indexes'), findsNothing);
      expect(controller.state.progressPercent, 68);
      await show(tester, find.byIcon(Icons.sync));
      expect(find.text('Restoring upload'), findsWidgets);
      expect(find.text('Paused'), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.scrollUntilVisible(
        find.byKey(const Key('upload-progress-bar')),
        -180,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('upload-progress-bar')),
            )
            .value,
        0.68,
      );
      expect(controller.state.confirmedUnits, 34);
      expect(find.byKey(const Key('upload-retry')), findsNothing);
    },
  );

  testWidgets('recoverable retry uses source once and retains progress', (
    tester,
  ) async {
    source.emit(
      uploadSnapshot(status: UploadProgressStatus.recoverableFailure),
    );
    await mount(tester);
    await show(tester, find.byKey(const Key('upload-retry')));
    await tester.tap(find.byKey(const Key('upload-retry')));
    await controller.retry();
    await tester.pumpAndSettle();
    expect(source.retries.length, 1);
    expect(find.byKey(const Key('upload-retry')), findsNothing);
    expect(controller.state.progressPercent, 68);
    source.retries.single.complete(uploadSnapshot());
    await tester.pumpAndSettle();
    expect(controller.state.status, UploadProgressStatus.uploading);
    expect(controller.state.confirmedUnits, 34);
  });

  testWidgets(
    'completed emits once across rebuild/remount and never navigates to reconstruction',
    (tester) async {
      await mount(tester);
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
      );
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsWidgets);
      expect(find.text('50 / 50 parts uploaded'), findsOneWidget);
      expect(find.text('Photo upload complete'), findsWidgets);
      expect(find.text('Moving to quality check...'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(completions, 1);
      source.emit(
        uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
      );
      await mount(tester);
      await tester.pumpWidget(const SizedBox());
      await mount(tester);
      expect(completions, 1);
      expect(find.byType(ProcessingScreen), findsNothing);
      expect(find.byType(UploadProgressScreen), findsOneWidget);
    },
  );

  testWidgets(
    'all confirmed counts do not emit completion without explicit state',
    (tester) async {
      source.emit(uploadSnapshot(confirmed: 50));
      await mount(tester);
      expect(completions, 0);
      expect(find.text('Photo upload complete'), findsNothing);
    },
  );

  testWidgets('completion scheduled before screen disposal is not delivered', (
    tester,
  ) async {
    await mount(tester);
    source.emit(
      uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
    );
    await tester.pumpWidget(const SizedBox());
    expect(completions, 0);
    await mount(tester);
    expect(completions, 1);
  });

  testWidgets('replacing controller cannot deliver old queued completion', (
    tester,
  ) async {
    await mount(tester);
    source.emit(
      uploadSnapshot(status: UploadProgressStatus.completed, confirmed: 50),
    );
    final previous = controller;
    controller = UploadProgressController(
      source: ControlledUploadProgressSource(uploadSnapshot()),
    );
    final replacementSource =
        controller.source as ControlledUploadProgressSource;
    await mount(tester);
    expect(completions, 0);
    previous.dispose();
    addTearDown(replacementSource.dispose);
  });

  testWidgets(
    'CaptureSession provides local paths, count, detail and readable preview',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'upload_preview_test_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/photo.png');
      file.writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      session.addPhoto(XFile(file.path));
      session.detailLevel = ReconstructionDetailLevel.standard;
      await mount(tester, name: 'My ceramic cup');
      expect(find.text('My ceramic cup'), findsOneWidget);
      expect(find.text('1 photo'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as FileImage).file.path, file.path);
      await show(tester, find.text('Standard'));
      expect(find.text('Standard'), findsOneWidget);
      expect(
        find.byType(RadioListTile<ReconstructionDetailLevel>),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing local files and fewer photos render four graceful positions',
    (tester) async {
      session.addPhoto(XFile('unavailable_upload_photo.png'));
      await mount(tester);
      await show(tester, find.byKey(const Key('upload-photo-3')));
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(ValueKey('upload-photo-$i')), findsOneWidget);
      }
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(image.errorBuilder, isNotNull);
      expect(find.byIcon(Icons.image_outlined), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save reassurance requires a persistent-resume capability', (
    tester,
  ) async {
    await mount(tester);
    await show(tester, find.text('Keep this session open'));
    expect(find.text('Progress is saved automatically'), findsNothing);
    source.emit(uploadSnapshot(persistent: true));
    await tester.pumpAndSettle();
    expect(find.text('Progress is saved automatically'), findsWidgets);
    expect(find.text('Keep this session open'), findsNothing);
  });

  testWidgets('unknown byte total falls back to measured local file size', (
    tester,
  ) async {
    source.emit(
      UploadProgressSnapshot(
        status: UploadProgressStatus.uploading,
        confirmedUnits: 34,
        totalUnits: 50,
        uploadIdentity: 'test-attempt',
      ),
    );
    await mount(tester);
    expect(find.text('0.0 KB'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets(
    'visual animation never advances the controller beyond confirmed progress',
    (tester) async {
      await mount(tester);
      source.emit(uploadSnapshot(confirmed: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('upload-progress-bar')),
      );
      expect(bar.value, inInclusiveRange(0.68, 0.8));
      expect(controller.state.confirmedUnits, 40);
      source.emit(
        uploadSnapshot(
          status: UploadProgressStatus.waitingForNetwork,
          confirmed: 40,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('upload-progress-bar')),
            )
            .value,
        0.8,
      );
      expect(controller.state.status, UploadProgressStatus.waitingForNetwork);
    },
  );

  for (final locale in ['en', 'vi']) {
    for (final spec in [
      (const Size(320, 640), 1.0),
      (const Size(412, 914), 1.0),
      (const Size(480, 900), 1.0),
      (const Size(320, 640), 2.0),
    ]) {
      testWidgets('$locale fits ${spec.$1} at text scale ${spec.$2}', (
        tester,
      ) async {
        tester.view.physicalSize = spec.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        source.emit(
          uploadSnapshot(status: UploadProgressStatus.waitingForNetwork),
        );
        await mount(
          tester,
          locale: locale,
          scale: spec.$2,
          name: 'Cốc Gốm Thủ Công #01 · A ceramic keepsake with a longer name',
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(UploadProgressScreen)),
        )!;
        await show(tester, find.text(strings.uploadNetworkBanner));
        expect(find.text(strings.uploadNetworkBanner), findsOneWidget);
        await show(tester, find.text(strings.uploadQualityStep));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'closed development panel leaves the full Pixel 6a preview viewport available',
    (tester) async {
      tester.view.physicalSize = const Size(412, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const UploadProgressPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text('DEVELOPMENT PREVIEW'), findsNothing);
      expect(find.text('A · Uploading'), findsNothing);
      expect(tester.getSize(find.byType(UploadProgressScreen)).height, 914);
      await show(tester, find.text('Giữ phiên tải này mở'));
      await show(tester, find.text('Mức độ chi tiết'));
      await show(tester, find.text('Các bước tiếp theo'));
      await show(tester, find.text('Bước tiếp theo sau khi tải xong'));
      await tester.tap(find.byKey(const Key('upload-preview-dev')));
      await tester.pumpAndSettle();
      expect(find.text('DEVELOPMENT PREVIEW'), findsOneWidget);
      await tester.tap(find.byTooltip('Close development controls'));
      await tester.pumpAndSettle();
      expect(find.text('DEVELOPMENT PREVIEW'), findsNothing);
      expect(find.text('Bước tiếp theo sau khi tải xong'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'manual preview switches A–E, retries and reports completion without real routing',
    (tester) async {
      Future<void> select(String label) async {
        await tester.tap(find.byKey(const Key('upload-preview-dev')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text('DEVELOPMENT PREVIEW'), findsNothing);
      }

      await tester.pumpWidget(const UploadProgressPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text('68%'), findsWidgets);
      await select('B · Network lost');
      expect(find.text('Đang chờ kết nối lại'), findsOneWidget);
      await select('C · Reconnecting');
      expect(find.text('Đang khôi phục phiên tải'), findsOneWidget);
      await show(tester, find.byIcon(Icons.sync));
      expect(find.text('Đang khôi phục'), findsWidgets);
      expect(find.text('Tạm dừng'), findsNothing);
      await select('E · Error');
      await show(tester, find.byKey(const Key('upload-retry')));
      await tester.tap(find.byKey(const Key('upload-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('upload-retry')), findsNothing);
      await select('D · Completed');
      await tester.pump(const Duration(seconds: 2));
      final completedScreen = tester.widget<UploadProgressScreen>(
        find.byType(UploadProgressScreen),
      );
      expect(
        completedScreen.controller.state.status,
        UploadProgressStatus.completed,
      );
      expect(completedScreen.controller.state.confirmedUnits, 50);
      await show(tester, find.byKey(const Key('upload-photo-3')));
      final completedStrings = AppLocalizations.of(
        tester.element(find.byType(UploadProgressScreen)),
      )!;
      for (var i = 0; i < 4; i++) {
        final tile = find.byKey(ValueKey('upload-photo-$i'));
        expect(
          find.descendant(of: tile, matching: find.byIcon(Icons.check)),
          findsOneWidget,
        );
        final semantics = find
            .ancestor(of: tile, matching: find.byType(Semantics))
            .first;
        expect(
          tester.widget<Semantics>(semantics).properties.label,
          completedStrings.uploadPhotoDescription(
            completedStrings.photoNumber(i + 1),
            completedStrings.uploadPhotoCompleted,
          ),
        );
      }
      await tester.scrollUntilVisible(
        find.text('Đang chuyển sang kiểm tra chất lượng...'),
        -180,
      );
      expect(find.text('100%'), findsWidgets);
      expect(
        find.text('Đang chuyển sang kiểm tra chất lượng...'),
        findsOneWidget,
      );
      expect(find.text('Tiếp tục'), findsNothing);
      await tester.tap(find.byKey(const Key('upload-preview-dev')));
      await tester.pumpAndSettle();
      expect(find.textContaining('completions: 1'), findsOneWidget);
      expect(find.byType(ProcessingScreen), findsNothing);
      await tester.tap(find.text('A · Uploading'));
      await tester.pumpAndSettle();
      final screen = tester.widget<UploadProgressScreen>(
        find.byType(UploadProgressScreen),
      );
      expect(screen.controller.state.progressPercent, 68);
      expect(screen.controller.state.status, UploadProgressStatus.uploading);
      await select('EN / VI');
      expect(
        AppLocalizations.of(tester.element(find.byType(UploadProgressScreen)))!
            .localeName,
        'en',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
