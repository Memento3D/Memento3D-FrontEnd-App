import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/dto/reconstruction_job_dto.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/reconstruction_job_mapper.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/reconstruction_repository_impl.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/processing_state.dart';

import 'package:memento3d_frontend_app/features/reconstruction/domain/reconstruction_repository.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/models/reconstruction_job_presentation_mapper.dart';
import 'package:memento3d_frontend_app/features/reconstruction/presentation/adapters/repository_processing_progress_source.dart';

ProcessingSnapshot snapshot(ReconstructionJobDto dto) =>
    presentReconstructionJob(mapReconstructionJob(dto));

const scanId = '12345678-1234-1234-1234-123456789abc';
Map<String, dynamic> fixture() => {
  'status': 'running',
  'stage': 'shape_generation',
  'execution_mode': 'real',
  'progress': 10000,
  'profile': 'arbitrary-profile',
  'retry_count': 7,
  'job_id': scanId,
  'scan_id': scanId,
  'input_image_id': scanId,
  'error_code': null,
  'error_message': null,
  'queued_at': null,
  'started_at': 'opaque timestamp',
  'completed_at': null,
  'created_at': 'opaque timestamp',
  'updated_at': 'opaque timestamp',
};

void main() {
  test('queued jobs accept an explicitly null stage from the backend', () {
    final dto = ReconstructionJobDto.fromJson(
      fixture()
        ..['status'] = 'queued'
        ..['stage'] = null,
    );
    expect(dto.stage, isNull);
    expect(snapshot(dto).jobStage, isNull);
  });

  testWidgets('backoff is capped and resets after success', (tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return calls <= 3
          ? http.Response('{}', 503)
          : http.Response(jsonEncode(fixture()), 200);
    });
    addTearDown(client.close);
    final source = ReconstructionRepositoryImpl(
      scanId: scanId,
      apiClient: ApiClient(client: client),
      pollingInterval: const Duration(seconds: 1),
      maxBackoff: const Duration(seconds: 3),
    );
    addTearDown(source.dispose);
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 2);
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 3);
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 4);
    expect(source.lastObservationError, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 5);
    source.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 5);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clearAuthData();
    ApiClient.onUnauthorized = null;
  });
  tearDown(() => ApiClient.onUnauthorized = null);

  test('all statuses map explicitly; only status controls completion', () {
    final expected = [
      ProcessingStatus.queued,
      ProcessingStatus.processing,
      ProcessingStatus.completed,
      ProcessingStatus.failed,
      ProcessingStatus.cancelled,
    ];
    for (var i = 0; i < ReconstructionJobStatus.values.length; i++) {
      final json = fixture()
        ..['status'] = ReconstructionJobStatus.values[i].name;
      final state = snapshot(ReconstructionJobDto.fromJson(json));
      expect(state.status, expected[i]);
      expect(state.isTerminal, i >= 2);
      expect(state.backendProgress, 10000);
      expect(state.progressPercent, isNull);
      expect(state.uploadedBytes, isNull);
      expect(state.totalUploadBytes, isNull);
      expect(state.canRetry, isFalse);
      expect(state.stageStatuses, isEmpty);
    }
    final done = fixture()
      ..['status'] = 'done'
      ..['progress'] = -10;
    expect(snapshot(ReconstructionJobDto.fromJson(done)).isTerminal, isTrue);
  });

  test('all seven stages are distinct from legacy local stages', () {
    final wire = [
      'downloading',
      'preprocessing',
      'shape_generation',
      'texturing',
      'validating',
      'exporting',
      'uploading',
    ];
    for (var i = 0; i < wire.length; i++) {
      final dto = ReconstructionJobDto.fromJson(fixture()..['stage'] = wire[i]);
      expect(dto.stage, ReconstructionStageDto.values[i]);
      final state = snapshot(dto);
      expect(state.jobStage, ProcessingJobStage.values[i]);
      expect(state.status, ProcessingStatus.processing);
      expect(state.stageStatuses, isEmpty);
    }
  });

  test('provenance, nullable errors, metadata and extra fields', () {
    for (final mode in ReconstructionExecutionMode.values) {
      final dto = ReconstructionJobDto.fromJson(
        fixture()
          ..['execution_mode'] = mode.name
          ..['extra'] = true,
      );
      expect(dto.executionMode, mode);
      expect(dto.errorCode, isNull);
      expect(dto.errorMessage, isNull);
      expect(dto.profile, 'arbitrary-profile');
      expect(dto.retryCount, 7);
      expect(dto.timestamps['started_at'], 'opaque timestamp');
      expect(
        snapshot(dto).provenance,
        mode == ReconstructionExecutionMode.real
            ? ProgressProvenance.measured
            : ProgressProvenance.simulated,
      );
    }
    final dto = ReconstructionJobDto.fromJson(
      fixture()
        ..['status'] = 'failed'
        ..['error_code'] = 'private-code'
        ..['error_message'] = 'stack trace',
    );
    expect(dto.errorCode, 'private-code');
    expect(dto.errorMessage, 'stack trace');
    expect(snapshot(dto).errorMessage, isNull);
  });

  test(
    'invalid shapes, required fields, types, UUIDs and unknown enums fail',
    () {
      for (final value in [null, [], 'invalid', 3]) {
        expect(
          () => ReconstructionJobDto.fromJson(value),
          throwsFormatException,
        );
      }
      for (final key in fixture().keys) {
        expect(
          () => ReconstructionJobDto.fromJson(fixture()..remove(key)),
          throwsFormatException,
          reason: key,
        );
      }
      for (final key in [
        'status',
        'stage',
        'execution_mode',
        'progress',
        'profile',
        'retry_count',
        'job_id',
        'scan_id',
        'input_image_id',
        'error_code',
        'error_message',
      ]) {
        expect(
          () => ReconstructionJobDto.fromJson(fixture()..[key] = []),
          throwsFormatException,
          reason: key,
        );
      }
      for (final key in ['status', 'stage', 'execution_mode', 'job_id']) {
        expect(
          () => ReconstructionJobDto.fromJson(fixture()..[key] = 'unknown'),
          throwsFormatException,
        );
      }
      expect(
        () => ReconstructionJobDto.fromJson(fixture()..['progress'] = 1.5),
        throwsFormatException,
      );
    },
  );

  test(
    'existing ApiClient injects JWT and exact GET; terminal stops',
    () async {
      await AuthStorage.saveToken('test-jwt');
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/scans/$scanId/job');
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        return http.Response(jsonEncode(fixture()..['status'] = 'done'), 200);
      });
      addTearDown(client.close);
      final source = ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
        pollingInterval: const Duration(milliseconds: 1),
      );
      addTearDown(source.dispose);
      final update = await source.jobs.first;
      expect(
        presentReconstructionJob(update).status,
        ProcessingStatus.completed,
      );
      expect(update.scanId, scanId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);
      final adapter = RepositoryProcessingProgressSource(source);
      await adapter.retry(1);
      expect(calls, 1); // A terminal backend job cannot be restarted by retry.
      adapter.dispose();
    },
  );

  for (final status in ['done', 'failed', 'cancelled']) {
    test('$status stops polling', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(fixture()..['status'] = status), 200);
      });
      addTearDown(client.close);
      final source = ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
        pollingInterval: const Duration(milliseconds: 1),
      );
      addTearDown(source.dispose);
      expect((await source.jobs.first).isTerminal, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);
    });
  }

  for (final code in [401, 404, 400, 200]) {
    test('HTTP $code observation failure stops without job failure', () async {
      var unauthorized = 0;
      var calls = 0;
      ApiClient.onUnauthorized = () => unauthorized++;
      final client = MockClient((_) async {
        calls++;
        return http.Response('not JSON', code);
      });
      addTearDown(client.close);
      final source = ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
        pollingInterval: const Duration(milliseconds: 1),
      );
      addTearDown(source.dispose);
      final error = await source.observationErrors.first;
      expect(error, switch (code) {
        401 => ReconstructionObservationError.authentication,
        404 => ReconstructionObservationError.unavailable,
        200 => ReconstructionObservationError.contract,
        _ => ReconstructionObservationError.request,
      });
      expect(source.current, isNull);
      expect(unauthorized, code == 401 ? 1 : 0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);
    });
  }

  for (final failure in ['network', 'timeout', 'server']) {
    test('$failure preserves last job and recovers via GET', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        if (calls == 2) {
          if (failure == 'network') throw const SocketException('private');
          if (failure == 'timeout') throw TimeoutException('private');
          return http.Response('{}', 503);
        }
        return http.Response(
          jsonEncode(fixture()..['status'] = calls >= 3 ? 'done' : 'running'),
          200,
        );
      });
      addTearDown(client.close);
      final source = ReconstructionRepositoryImpl(
        scanId: scanId,
        apiClient: ApiClient(client: client),
        pollingInterval: const Duration(milliseconds: 1),
        maxBackoff: const Duration(milliseconds: 4),
      );
      addTearDown(source.dispose);
      final errorFuture = source.observationErrors.first;
      final doneFuture = source.jobs.firstWhere((u) => u.isTerminal);
      expect(await errorFuture, ReconstructionObservationError.transient);
      expect(
        presentReconstructionJob(source.current!).status,
        ProcessingStatus.processing,
      );
      expect(
        presentReconstructionJob(await doneFuture).status,
        ProcessingStatus.completed,
      );
      expect(calls, 3);
    });
  }

  test('one request in flight; cancellation ignores late response', () async {
    final gate = Completer<http.Response>();
    final entered = Completer<void>();
    var calls = 0;
    final client = MockClient((_) {
      calls++;
      entered.complete();
      return gate.future;
    });
    addTearDown(client.close);
    final source = ReconstructionRepositoryImpl(
      scanId: scanId,
      apiClient: ApiClient(client: client),
      pollingInterval: const Duration(milliseconds: 1),
    );
    addTearDown(source.dispose);
    var updates = 0;
    final subscription = source.jobs.listen((_) => updates++);
    addTearDown(subscription.cancel);
    await entered.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, 1);
    source.cancel();
    gate.complete(http.Response(jsonEncode(fixture()), 200));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(updates, 0);
    expect(calls, 1);
  });
}
