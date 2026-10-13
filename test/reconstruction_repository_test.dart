import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/api/reconstruction_api.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/dto/reconstruction_job_dto.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/repositories/reconstruction_repository_impl.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/models/reconstruction_failure.dart';
import 'package:memento3d_frontend_app/features/reconstruction/domain/repositories/reconstruction_repository.dart';

// Test fixtures only; production receives all identities from the backend.
const scanId = '11111111-2222-4333-8444-555555555555';
const imageId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
const jobId = '99999999-8888-4777-8666-555555555555';
Map<String, dynamic> jobJson() => {
  'job_id': jobId,
  'scan_id': scanId,
  'input_image_id': imageId,
  'status': 'queued',
  'stage': 'queued',
  'progress': 0,
  'profile': 'default',
  'execution_mode': 'future_mode',
  'retry_count': 0,
  'error_code': null,
  'error_message': null,
  'queued_at': null,
  'started_at': null,
  'completed_at': null,
  'created_at': '2026-10-13T00:00:00Z',
  'updated_at': '2026-10-13T01:00:00+01:00',
};

class JobClient extends http.BaseClient {
  int calls = 0, status = 202;
  Object? error;
  Object? body;
  String? rawBody;
  http.Request? request;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    calls++;
    request = value as http.Request;
    if (error != null) throw error!;
    return http.StreamedResponse(
      Stream.value(utf8.encode(rawBody ?? jsonEncode(body ?? jobJson()))),
      status,
    );
  }
}

Matcher startFailure(ReconstructionStartFailureKind kind, {int? status}) =>
    isA<ReconstructionStartFailure>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.statusCode, 'status', status);

void main() {
  late JobClient client;
  late ReconstructionRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.saveToken('stored-job-token');
    client = JobClient();
    repository = ReconstructionRepositoryImpl(
      ReconstructionApi(ApiClient(client: client)),
    );
  });
  tearDown(() async {
    client.close();
    ApiClient.onUnauthorized = null;
    await AuthStorage.clearAuthData();
  });

  test('DTO maps all identities, values and null metadata to domain', () {
    final job = ReconstructionJobDto.fromJson(jobJson()).toDomain();
    expect(job.jobId, jobId);
    expect(job.scanId, scanId);
    expect(job.inputImageId, imageId);
    expect(job.status, 'queued');
    expect(job.stage, 'queued');
    expect(job.progress, 0);
    expect(job.profile, 'default');
    expect(job.executionMode, 'future_mode');
    expect(job.retryCount, 0);
    expect(job.errorCode, isNull);
    expect(job.errorMessage, isNull);
    expect(job.queuedAt, isNull);
    expect(job.startedAt, isNull);
    expect(job.completedAt, isNull);
    expect(job.createdAt, DateTime.utc(2026, 10, 13));
    expect(job.updatedAt, job.createdAt);
  });
  test('DTO preserves unknown enum values and populated nullable metadata', () {
    final json = jobJson()
      ..addAll({
        'status': 'future_status',
        'stage': 'future_stage',
        'execution_mode': 'future_execution',
        'progress': 100,
        'retry_count': 2,
        'error_code': 'BACKEND_CODE',
        'error_message': 'Backend detail',
        'queued_at': '2026-10-13T01:00:00Z',
        'started_at': '2026-10-13T02:00:00Z',
        'completed_at': '2026-10-13T03:00:00Z',
      });
    final job = ReconstructionJobDto.fromJson(json).toDomain();
    expect(job.status, 'future_status');
    expect(job.stage, 'future_stage');
    expect(job.executionMode, 'future_execution');
    expect(job.progress, 100);
    expect(job.retryCount, 2);
    expect(job.errorCode, 'BACKEND_CODE');
    expect(job.errorMessage, 'Backend detail');
    expect(job.queuedAt, DateTime.utc(2026, 10, 13, 1));
    expect(job.startedAt, DateTime.utc(2026, 10, 13, 2));
    expect(job.completedAt, DateTime.utc(2026, 10, 13, 3));
  });
  test('missing nullable properties safely map to null', () {
    final json = jobJson();
    for (final key in [
      'error_code',
      'error_message',
      'queued_at',
      'started_at',
      'completed_at',
    ]) {
      json.remove(key);
    }
    expect(ReconstructionJobDto.fromJson(json).toDomain().queuedAt, isNull);
  });
  test(
    '202 POST uses exact URL, JSON, centralized auth and a single send',
    () async {
      final job = await repository.startJob(
        scanId: scanId,
        inputImageId: imageId,
      );
      expect(job.jobId, jobId);
      expect(client.request!.method, 'POST');
      expect(client.request!.url.path, '/api/v1/scans/$scanId/job');
      expect(jsonDecode(client.request!.body), {
        'input_image_id': imageId,
        'profile': 'default',
      });
      expect(
        client.request!.headers['Authorization'],
        'Bearer stored-job-token',
      );
      expect(client.request!.headers['Content-Type'], 'application/json');
      expect(client.calls, 1);
    },
  );
  test(
    '200 GET returns latest job without submitting or a JSON body',
    () async {
      client.status = 200;
      final job = await repository.getLatestJob(scanId: scanId);
      expect(job.jobId, jobId);
      expect(client.request!.method, 'GET');
      expect(client.request!.url.path, '/api/v1/scans/$scanId/job');
      expect(client.request!.body, isEmpty);
      expect(
        client.request!.headers['Authorization'],
        'Bearer stored-job-token',
      );
      expect(client.calls, 1);
    },
  );
  for (final invalid in [
    (scan: '', image: imageId, profile: 'default'),
    (scan: '../bad', image: imageId, profile: 'default'),
    (scan: scanId, image: '', profile: 'default'),
    (scan: scanId, image: imageId, profile: 'unsupported'),
  ]) {
    test('invalid local start $invalid never sends', () async {
      await expectLater(
        repository.startJob(
          scanId: invalid.scan,
          inputImageId: invalid.image,
          profile: invalid.profile,
        ),
        throwsA(startFailure(ReconstructionStartFailureKind.notSubmitted)),
      );
      expect(client.calls, 0);
    });
  }
  for (final status in [
    400,
    401,
    403,
    404,
    409,
    422,
    429,
    408,
    500,
    502,
    503,
    302,
  ]) {
    test(
      'HTTP $status preserves start safety without retry or reconciliation',
      () async {
        client.status = status;
        client.body = {'message': 'Request rejected', 'error_code': 'JOB_CODE'};
        var unauthorized = 0;
        ApiClient.onUnauthorized = () => unauthorized++;
        await expectLater(
          repository.startJob(scanId: scanId, inputImageId: imageId),
          throwsA(
            startFailure(
              status >= 400 && status < 500 && status != 408
                  ? ReconstructionStartFailureKind.rejected
                  : ReconstructionStartFailureKind.ambiguous,
              status: status,
            ),
          ),
        );
        expect(client.calls, 1);
        expect(unauthorized, status == 401 ? 1 : 0);
      },
    );
  }
  for (final error in [
    TimeoutException('timeout'),
    const SocketException('lost'),
    http.ClientException('lost'),
  ]) {
    test('$error becomes ambiguous without replay', () async {
      client.error = error;
      await expectLater(
        repository.startJob(scanId: scanId, inputImageId: imageId),
        throwsA(
          isA<ReconstructionStartFailure>().having(
            (e) => e.kind,
            'kind',
            ReconstructionStartFailureKind.ambiguous,
          ),
        ),
      );
      expect(client.calls, 1);
    });
  }
  for (final status in [200, 201, 204]) {
    test('unexpected successful POST $status remains ambiguous', () async {
      client.status = status;
      await expectLater(
        repository.startJob(scanId: scanId, inputImageId: imageId),
        throwsA(
          startFailure(
            ReconstructionStartFailureKind.ambiguous,
            status: status,
          ),
        ),
      );
      expect(client.calls, 1);
    });
  }
  for (final body in <Object>[
    {},
    [],
    'not-json-object',
    {'job_id': jobId},
  ]) {
    test('malformed accepted body $body remains ambiguous', () async {
      client.body = body;
      await expectLater(
        repository.startJob(scanId: scanId, inputImageId: imageId),
        throwsA(startFailure(ReconstructionStartFailureKind.ambiguous)),
      );
      expect(client.calls, 1);
    });
  }
  for (final change in [
    {'scan_id': imageId},
    {'input_image_id': scanId},
    {'profile': 'different'},
    {'job_id': 'invalid'},
    {'progress': 101},
    {'progress': 1.5},
    {'retry_count': -1},
    {'created_at': 'invalid'},
    {'queued_at': 'invalid'},
    {'error_code': 42},
  ]) {
    test('invalid accepted fields $change remain ambiguous', () async {
      client.body = jobJson()..addAll(change);
      await expectLater(
        repository.startJob(scanId: scanId, inputImageId: imageId),
        throwsA(startFailure(ReconstructionStartFailureKind.ambiguous)),
      );
      expect(client.calls, 1);
    });
  }
  for (final field in [
    'job_id',
    'scan_id',
    'input_image_id',
    'status',
    'stage',
    'progress',
    'profile',
    'execution_mode',
    'retry_count',
    'created_at',
    'updated_at',
  ]) {
    test('DTO rejects missing required $field', () {
      expect(
        () => ReconstructionJobDto.fromJson(jobJson()..remove(field)),
        throwsFormatException,
      );
    });
  }
  test(
    'GET maps absence and transport errors to typed fetch failures',
    () async {
      client.status = 404;
      await expectLater(
        repository.getLatestJob(scanId: scanId),
        throwsA(
          isA<ReconstructionFetchFailure>().having(
            (e) => e.kind,
            'kind',
            ReconstructionFetchFailureKind.notFound,
          ),
        ),
      );
      client.error = const SocketException('lost');
      await expectLater(
        repository.getLatestJob(scanId: scanId),
        throwsA(
          isA<ReconstructionFetchFailure>().having(
            (e) => e.kind,
            'kind',
            ReconstructionFetchFailureKind.unavailable,
          ),
        ),
      );
      expect(client.calls, 2);
    },
  );
  test(
    'GET rejects invalid input before send and invalid/mismatched results',
    () async {
      await expectLater(
        repository.getLatestJob(scanId: ''),
        throwsA(
          isA<ReconstructionFetchFailure>().having(
            (e) => e.kind,
            'kind',
            ReconstructionFetchFailureKind.invalidInput,
          ),
        ),
      );
      expect(client.calls, 0);
      for (final body in [{}, jobJson()..['scan_id'] = imageId]) {
        client.status = 200;
        client.body = body;
        await expectLater(
          repository.getLatestJob(scanId: scanId),
          throwsA(
            isA<ReconstructionFetchFailure>().having(
              (e) => e.kind,
              'kind',
              ReconstructionFetchFailureKind.invalidResponse,
            ),
          ),
        );
      }
    },
  );
  testWidgets('actual shared timeout does not replay a stalled start', (
    tester,
  ) async {
    final pending = Completer<http.StreamedResponse>();
    final stalled = _StalledClient(pending.future);
    final repo = ReconstructionRepositoryImpl(
      ReconstructionApi(ApiClient(client: stalled)),
    );
    final assertion = expectLater(
      repo.startJob(scanId: scanId, inputImageId: imageId),
      throwsA(
        startFailure(ReconstructionStartFailureKind.ambiguous, status: 408),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    await assertion;
    expect(stalled.calls, 1);
    pending.complete(
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(jobJson()))),
        202,
      ),
    );
    await tester.pump();
    expect(stalled.calls, 1);
  });
  for (final raw in ['', '{broken', 'null']) {
    test(
      'empty or malformed raw accepted response remains ambiguous: $raw',
      () async {
        client.rawBody = raw;
        await expectLater(
          repository.startJob(scanId: scanId, inputImageId: imageId),
          throwsA(startFailure(ReconstructionStartFailureKind.ambiguous)),
        );
        expect(client.calls, 1);
      },
    );
  }
  test('GET enforces 200 independently of POST acceptance', () async {
    await expectLater(
      repository.getLatestJob(scanId: scanId),
      throwsA(
        isA<ReconstructionFetchFailure>().having(
          (e) => e.kind,
          'kind',
          ReconstructionFetchFailureKind.invalidResponse,
        ),
      ),
    );
    expect(client.calls, 1);
  });
  test('shared JSON defaults still accept existing success statuses', () async {
    final api = ApiClient(client: client);
    client.status = 201;
    expect(
      await api.post('/existing', body: {'name': 'example'}),
      isA<Map<String, dynamic>>(),
    );
    client.status = 204;
    client.rawBody = '';
    expect(await api.get('/existing'), isNull);
  });
}

class _StalledClient extends http.BaseClient {
  _StalledClient(this.response);
  final Future<http.StreamedResponse> response;
  int calls = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    calls++;
    return response;
  }
}
