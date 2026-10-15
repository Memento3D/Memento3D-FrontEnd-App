import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/reconstruction_repository_impl.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/entities/reconstruction_job.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/reconstruction_repository.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/controllers/processing_controller.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/processing_state.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/reconstruction_job_presentation_mapper.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/screens/reconstruction_progress_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';

import '../data/reconstruction_job_test.dart' show fixture, scanId;

Widget app(
  String locale, {
  ProcessingSnapshot? snapshot,
  ProcessingController? controller,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: ReconstructionProgressScreen(
    session: CaptureSession(),
    controller: controller,
    snapshot: snapshot ?? const ProcessingSnapshot.observing(),
  ),
);

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ReconstructionProgressScreen)))!;

ProcessingSnapshot job(
  ReconstructionStatus status,
  ReconstructionStage stage, {
  ReconstructionExecution execution = ReconstructionExecution.real,
}) => presentReconstructionJob(
  ReconstructionJob(
    jobId: scanId,
    scanId: scanId,
    inputImageId: scanId,
    status: status,
    stage: stage,
    progress: 10000,
    execution: execution,
    profile: 'opaque-profile',
    retryCount: 0,
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clearAuthData();
    ApiClient.onUnauthorized = null;
  });

  testWidgets('queued without a reported stage invents no stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        'en',
        snapshot: ProcessingSnapshot(
          status: ProcessingStatus.queued,
          isBackendObservation: true,
        ),
      ),
    );
    expect(find.text(strings(tester).processingQueued), findsOneWidget);
    expect(
      find.text(strings(tester).processingBackendDownloading),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('stage-dataUpload-pending')),
      findsNothing,
    );
  });

  testWidgets('backend loading and stages fit narrow large-text layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final locale in ['en', 'vi']) {
      await tester.pumpWidget(app(locale));
      expect(tester.takeException(), isNull);
      for (final stage in ReconstructionStage.values) {
        await tester.pumpWidget(
          app(locale, snapshot: job(ReconstructionStatus.running, stage)),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('delayed GET stays loading then renders actual queued job', (
    tester,
  ) async {
    final gate = Completer<http.Response>();
    final client = MockClient((_) => gate.future);
    final controller = ProcessingController(
      ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
      ),
    );
    await tester.pumpWidget(app('en', controller: controller));
    expect(controller.snapshot.status, ProcessingStatus.observationLoading);
    expect(controller.snapshot.jobStage, isNull);
    expect(
      find.text(strings(tester).processingObservationLoading),
      findsOneWidget,
    );
    expect(find.text(strings(tester).processingReadyTitle), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.snapshot.status, ProcessingStatus.observationLoading);
    gate.complete(
      http.Response(jsonEncode(fixture()..['status'] = 'queued'), 200),
    );
    await tester.pump();
    expect(controller.snapshot.status, ProcessingStatus.queued);
    expect(find.text(strings(tester).processingQueued), findsOneWidget);
    controller.dispose();
    client.close();
  });

  testWidgets('first permanent error and explicit retry have coherent UI', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<http.Response>();
    final client = MockClient(
      (_) async => ++calls == 1 ? http.Response('{}', 404) : gate.future,
    );
    final controller = ProcessingController(
      ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
      ),
    );
    await tester.pumpWidget(app('en', controller: controller));
    await tester.pump();
    expect(
      controller.snapshot.observationError,
      ReconstructionObservationError.unavailable,
    );
    expect(
      find.text(strings(tester).processingObservationUnavailable),
      findsOneWidget,
    );
    expect(find.text(strings(tester).processingReadyTitle), findsNothing);
    expect(
      find.text(strings(tester).processingObservationLoading),
      findsNothing,
    );
    final retry = controller.retry();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(
      find.text(strings(tester).processingObservationLoading),
      findsOneWidget,
    );
    expect(controller.snapshot.observationError, isNull);
    gate.complete(
      http.Response(jsonEncode(fixture()..['status'] = 'done'), 200),
    );
    await tester.pump();
    await retry;
    expect(controller.snapshot.status, ProcessingStatus.completed);
    controller.dispose();
    client.close();
  });

  for (final locale in ['en', 'vi']) {
    testWidgets('$locale loading queued cancelled and all backend stages', (
      tester,
    ) async {
      await tester.pumpWidget(app(locale));
      final l10n = strings(tester);
      expect(find.text(l10n.processingObservationLoading), findsOneWidget);
      expect(find.text(l10n.processingCloudUnavailable), findsNothing);
      for (final status in [
        ReconstructionStatus.queued,
        ReconstructionStatus.cancelled,
      ]) {
        await tester.pumpWidget(
          app(locale, snapshot: job(status, ReconstructionStage.validating)),
        );
        expect(
          find.text(
            status == ReconstructionStatus.queued
                ? l10n.processingQueued
                : l10n.processingCancelled,
          ),
          findsOneWidget,
        );
      }
      final labels = [
        l10n.processingBackendDownloading,
        l10n.processingBackendPreprocessing,
        l10n.processingBackendShapeGeneration,
        l10n.processingBackendTexturing,
        l10n.processingBackendValidating,
        l10n.processingBackendExporting,
        l10n.processingBackendUploading,
      ];
      for (var i = 0; i < ReconstructionStage.values.length; i++) {
        final snapshot = job(
          ReconstructionStatus.running,
          ReconstructionStage.values[i],
        );
        expect(snapshot.jobStage, ProcessingJobStage.values[i]);
        await tester.pumpWidget(app(locale, snapshot: snapshot));
        await tester.scrollUntilVisible(find.text(labels[i]), 150);
        expect(find.text(labels[i]), findsOneWidget);
        expect(find.text(l10n.processingStageUpload), findsNothing);
        expect(find.text(l10n.processingCloudUnavailable), findsNothing);
        expect(find.text(l10n.processingLocal), findsNothing);
        expect(find.text(l10n.processingSelectedDetail), findsNothing);
        await tester.scrollUntilVisible(
          find.text(l10n.processingBackendReal),
          -150,
        );
        expect(find.text(l10n.processingBackendReal), findsOneWidget);
        expect(find.textContaining('%'), findsNothing);
      }
    });

    testWidgets(
      '$locale terminal jobs retain stage without invented history; mock is explicit',
      (tester) async {
        for (final status in [
          ReconstructionStatus.done,
          ReconstructionStatus.failed,
          ReconstructionStatus.cancelled,
        ]) {
          final snapshot = job(
            status,
            ReconstructionStage.exporting,
            execution: ReconstructionExecution.mock,
          );
          await tester.pumpWidget(app(locale, snapshot: snapshot));
          final l10n = strings(tester);
          await tester.scrollUntilVisible(
            find.text(l10n.processingBackendExporting),
            150,
          );
          expect(find.text(l10n.processingBackendExporting), findsOneWidget);
          expect(
            find.byKey(const ValueKey('stage-completion-completed')),
            findsNothing,
          );
          expect(snapshot.stageStatuses, isEmpty);
          expect(snapshot.isTerminal, isTrue);
          await tester.scrollUntilVisible(
            find.text(l10n.processingSimulated),
            -150,
          );
          expect(find.text(l10n.processingSimulated), findsOneWidget);
        }
      },
    );
  }
}
