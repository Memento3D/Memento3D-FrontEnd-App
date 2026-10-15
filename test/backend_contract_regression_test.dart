import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/data/models/model_output.dart';
import 'package:memento3d_frontend_app/features/reconstruction/data/real_execution_guard.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/job_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_output_model.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/model_confirmation_state.dart';

void main() {
  test(
    'missing API submitter cannot simulate a queued reconstruction',
    () async {
      await expectLater(
        submitCaptureSession(CaptureSession()),
        throwsStateError,
      );
    },
  );

  test('unverified execution mode cannot enter the real job flow', () {
    for (final response in [
      null,
      [],
      {},
      {'execution_mode': 'unknown'},
    ]) {
      expect(() => requireRealExecution(response), throwsFormatException);
    }
  });

  test('both output consumers read the backend delivery URL and identity', () {
    final payload = <String, dynamic>{
      'output_id': 'output-identity',
      'job_id': 'job-identity',
      'format': 'glb',
      'delivery_url': 'https://assets.example/model.glb',
      'file_size_bytes': 4096,
      'sha256': 'artifact-digest',
    };
    final model = ModelOutput.fromJson(payload);
    final scanOutput = ScanOutputModel.fromJson(payload);
    expect(model.id, payload['output_id']);
    expect(scanOutput.id, model.id);
    expect(scanOutput.fileUrl, model.downloadUrl);
    expect(model.fileHash, payload['sha256']);
  });

  test('one percent from reconstruction is never rendered as completion', () {
    final job = JobModel.fromJson({
      'job_id': 'job-identity',
      'status': 'running',
      'execution_mode': 'real',
      'progress': 1,
    });
    expect(job.effectiveProgress, 0.01);
    expect(job.isDone, isFalse);
  });

  test(
    'backend simulation is rejected at the production transport boundary',
    () {
      expect(
        () => requireRealExecution({'execution_mode': 'mock'}),
        throwsFormatException,
      );
      expect(
        () => requireRealExecution({
          'job': {'execution_mode': 'mock'},
        }),
        throwsFormatException,
      );
      expect(
        () => requireRealExecution({'execution_mode': 'real'}),
        returnsNormally,
      );
    },
  );
}
