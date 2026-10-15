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
import 'package:memento3d_frontend_app/features/reconstruction/domain/reconstruction_repository.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/controllers/processing_controller.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/processing_state.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/services/processing_progress_source.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/screens/reconstruction_progress_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

import 'data/reconstruction_job_test.dart' show fixture, scanId;

ReconstructionRepositoryImpl repository(MockClient client, {int budget = 2}) =>
    ReconstructionRepositoryImpl(
      scanId: scanId,
      apiClient: ApiClient(client: client),
      pollingInterval: const Duration(seconds: 1),
      maxBackoff: const Duration(seconds: 3),
      maxConsecutiveTransientFailures: budget,
    );

http.Response running([String status = 'running']) =>
    http.Response(jsonEncode(fixture()..['status'] = status), 200);

class ErrorSource
    implements ProcessingProgressSource, ObservationProcessingProgressSource {
  final updatesController = StreamController<ProcessingUpdate>.broadcast(
    sync: true,
  );
  final errors = StreamController<ProcessingObservationUpdate>.broadcast(
    sync: true,
  );
  @override
  ProcessingUpdate current = ProcessingUpdate(
    0,
    ProcessingSnapshot(status: ProcessingStatus.processing),
  );
  @override
  ProcessingObservationUpdate? currentObservationError;
  @override
  Stream<ProcessingUpdate> get updates => updatesController.stream;
  @override
  Stream<ProcessingObservationUpdate> get observationErrors => errors.stream;
  @override
  Future<void> retry(int attempt) async {
    current = ProcessingUpdate(
      attempt,
      ProcessingSnapshot(status: ProcessingStatus.processing),
    );
  }

  @override
  void dispose() {
    unawaited(updatesController.close());
    unawaited(errors.close());
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clearAuthData();
    ApiClient.onUnauthorized = null;
  });

  testWidgets(
    'finite budget exhausts, preserves job, and explicit retry is GET only',
    (tester) async {
      var calls = 0;
      var recover = false;
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        calls++;
        return calls == 1 || recover ? running() : http.Response('{}', 503);
      });
      addTearDown(client.close);
      final repo = repository(client);
      final controller = ProcessingController(repo);
      addTearDown(controller.dispose);
      await tester.pump();
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/v1/scans/$scanId/job');
      expect(
        controller.snapshot.status,
        ProcessingStatus.processing,
        reason:
            'calls=$calls error=${controller.snapshot.observationError} job=${repo.current}',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        controller.snapshot.observationError,
        ReconstructionObservationError.transient,
      );
      expect(controller.snapshot.status, ProcessingStatus.processing);
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 3);
      expect(
        controller.snapshot.observationError,
        ReconstructionObservationError.exhausted,
      );
      expect(controller.snapshot.canRetryObservation, isTrue);
      expect(controller.snapshot.backendProgress, 10000);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 3);
      recover = true;
      final retry = controller.retry();
      final duplicate = controller.retry();
      // Stream cancellation can complete in the binding's outer async zone.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(calls, 4);
      await retry;
      await duplicate;
      expect(calls, 4);
      expect(controller.attempt, 1);
      expect(controller.snapshot.observationError, isNull);
      expect(requests.every((request) => request.method == 'GET'), isTrue);
      recover = false;
      await tester.pump(const Duration(seconds: 1));
      expect(
        controller.snapshot.observationError,
        ReconstructionObservationError.transient,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        controller.snapshot.observationError,
        ReconstructionObservationError.exhausted,
      );
    },
  );

  testWidgets(
    'success resets failures; queued and running polls have no total budget',
    (tester) async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 2 || calls == 4
            ? http.Response('{}', 429)
            : running(calls == 1 ? 'queued' : 'running');
      });
      addTearDown(client.close);
      final repo = repository(client);
      final controller = ProcessingController(repo);
      addTearDown(controller.dispose);
      await tester.pump();
      expect(controller.snapshot.status, ProcessingStatus.queued);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(controller.snapshot.observationError, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(
        controller.snapshot.observationError,
        ReconstructionObservationError.transient,
      );
      await tester.pump(const Duration(seconds: 2));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(calls, 13);
      expect(controller.snapshot.observationError, isNull);
      controller.dispose();
    },
  );

  for (final code in [401, 404, 200]) {
    testWidgets('$code stops and reaches typed controller observation state', (
      tester,
    ) async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('private invalid response', code);
      });
      addTearDown(client.close);
      final repo = repository(client);
      final controller = ProcessingController(repo);
      addTearDown(controller.dispose);
      await tester.pump();
      expect(controller.snapshot.observationError, switch (code) {
        401 => ReconstructionObservationError.authentication,
        404 => ReconstructionObservationError.unavailable,
        _ => ReconstructionObservationError.contract,
      });
      expect(controller.snapshot.status, ProcessingStatus.observationLoading);
      expect(controller.snapshot.errorMessage, isNull);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
    });
  }

  testWidgets('default budget stops on fifth consecutive failure', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('{}', 503);
    });
    addTearDown(client.close);
    final repo = ReconstructionRepositoryImpl(
      scanId: scanId,
      apiClient: ApiClient(client: client),
      pollingInterval: const Duration(seconds: 1),
      maxBackoff: const Duration(seconds: 3),
    );
    await tester.pump();
    for (final seconds in [2, 3, 3, 3]) {
      await tester.pump(Duration(seconds: seconds));
    }
    expect(calls, 5);
    expect(repo.lastObservationError, ReconstructionObservationError.exhausted);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 5);
    repo.dispose();
  });

  testWidgets('disposed controller ignores late observation error', (
    tester,
  ) async {
    final gate = Completer<http.Response>();
    final client = MockClient((_) => gate.future);
    addTearDown(client.close);
    final repo = repository(client);
    final controller = ProcessingController(repo);
    var notifications = 0;
    controller.addListener(() => notifications++);
    await tester.pump();
    controller.dispose();
    gate.complete(http.Response('{}', 401));
    await tester.pump();
    expect(notifications, 0);
    expect(repo.lastObservationError, isNull);
    expect(controller.snapshot.observationError, isNull);
  });

  testWidgets(
    'backend failed remains terminal; observation retry cannot restart it',
    (tester) async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return running('failed');
      });
      addTearDown(client.close);
      final repo = repository(client);
      final controller = ProcessingController(repo);
      addTearDown(controller.dispose);
      await tester.pump();
      expect(controller.snapshot.status, ProcessingStatus.failed);
      expect(controller.snapshot.observationError, isNull);
      await controller.retry();
      await repo.retryObservation();
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
    },
  );

  testWidgets(
    'restart waits for old request; stale errors and disposed responses are ignored',
    (tester) async {
      var calls = 0;
      final gate = Completer<http.Response>();
      final client = MockClient((_) {
        calls++;
        return calls == 1 ? gate.future : Future.value(running());
      });
      addTearDown(client.close);
      final repo = repository(client);
      final controller = ProcessingController(repo);
      await tester.pump();
      final retry = repo.retryObservation();
      final duplicate = repo.retryObservation();
      await tester.pump(const Duration(seconds: 10));
      expect(calls, 1);
      gate.complete(http.Response('{}', 401));
      await tester.pump();
      await retry;
      await duplicate;
      expect(calls, 2);
      expect(controller.snapshot.observationError, isNull);
      controller.dispose();
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 2);
    },
  );

  test(
    'stale attempt errors and errors after terminal/disposal cannot alter job',
    () async {
      final source = ErrorSource();
      final controller = ProcessingController.fromProgressSource(source);
      source.errors.add(
        const ProcessingObservationUpdate(
          0,
          ReconstructionObservationError.exhausted,
        ),
      );
      await controller.retry();
      source.errors.add(
        const ProcessingObservationUpdate(
          0,
          ReconstructionObservationError.authentication,
        ),
      );
      expect(controller.snapshot.observationError, isNull);
      source.updatesController.add(
        ProcessingUpdate(
          1,
          ProcessingSnapshot(status: ProcessingStatus.completed),
        ),
      );
      source.errors.add(
        const ProcessingObservationUpdate(
          1,
          ReconstructionObservationError.exhausted,
        ),
      );
      expect(controller.snapshot.status, ProcessingStatus.completed);
      expect(controller.snapshot.observationError, isNull);
      controller.dispose();
    },
  );

  for (final locale in ['en', 'vi']) {
    testWidgets(
      '$locale displays safe observation message and GET retry action',
      (tester) async {
        final client = MockClient((_) async => http.Response('{}', 503));
        addTearDown(client.close);
        final repo = repository(client, budget: 1);
        final controller = ProcessingController(repo);
        addTearDown(controller.dispose);
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ReconstructionProgressScreen(
              session: CaptureSession(),
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(ReconstructionProgressScreen));
        final strings = AppLocalizations.of(context)!;
        expect(
          find.text(strings.processingObservationExhausted),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(strings.retry));
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, strings.retry),
              )
              .onPressed,
          isNotNull,
        );
        expect(controller.snapshot.status, isNot(ProcessingStatus.failed));
      },
    );
  }
}
