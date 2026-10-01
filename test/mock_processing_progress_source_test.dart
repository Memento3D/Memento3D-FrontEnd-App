import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/models/processing_state.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/services/mock_processing_progress_source.dart';

void main() {
  test(
    'manual success has exact order and excludes upload from percentages',
    () {
      final source = MockProcessingProgressSource();
      addTearDown(source.dispose);
      for (var step = 0; step <= 5; step++) {
        final state = source.current.snapshot;
        expect(state.progressPercent, step * 20);
        expect(state.provenance, ProgressProvenance.simulated);
        expect(state.hasMeasuredProgress, isFalse);
        expect(
          state.statusFor(ProcessingStage.dataUpload),
          ProcessingStageStatus.completed,
        );
        expect(
          state.status,
          step == 5 ? ProcessingStatus.completed : ProcessingStatus.processing,
        );
        for (var i = 0; i < ProcessingStage.values.length; i++) {
          expect(
            state.statusFor(ProcessingStage.values[i]),
            i <= step
                ? ProcessingStageStatus.completed
                : i == step + 1
                ? ProcessingStageStatus.active
                : ProcessingStageStatus.pending,
          );
        }
        source.advance();
      }
      expect(source.current.snapshot.progressPercent, 100);
    },
  );

  test(
    'fixed failure preserves detail context and retry starts a new attempt',
    () async {
      final source = MockProcessingProgressSource(
        scenario: MockProcessingScenario.failure,
      );
      addTearDown(source.dispose);
      source.advance();
      source.advance();
      source.advance();
      final failed = source.current.snapshot;
      expect(failed.status, ProcessingStatus.failed);
      expect(failed.progressPercent, 40);
      expect(failed.failure, ProcessingFailure.simulated);
      expect(failed.canRetry, isTrue);
      expect(
        failed.statusFor(ProcessingStage.detailGeneration),
        ProcessingStageStatus.active,
      );
      source.advance();
      expect(source.current.snapshot, same(failed));
      await source.retry(1);
      expect(source.current.attempt, 1);
      expect(source.current.snapshot.progressPercent, 0);
      expect(source.current.snapshot.failure, isNull);
      expect(source.current.snapshot.errorMessage, isNull);
      expect(source.current.snapshot.canRetry, isFalse);
      source.advance();
      source.advance();
      source.advance();
      expect(source.current.snapshot.status, ProcessingStatus.failed);
    },
  );

  test('unknown progression never invents a percentage', () {
    final source = MockProcessingProgressSource(
      scenario: MockProcessingScenario.unknown,
    );
    addTearDown(source.dispose);
    source.advance();
    expect(source.current.snapshot.progressPercent, isNull);
    expect(source.current.snapshot.hasKnownProgress, isFalse);
    expect(source.current.snapshot.isRunning, isTrue);
  });

  test('snapshot copies maps and percentage alone does not complete', () {
    final stages = {
      ProcessingStage.imagePreparation: ProcessingStageStatus.active,
    };
    final state = ProcessingSnapshot(
      status: ProcessingStatus.processing,
      progressPercent: 100,
      provenance: ProgressProvenance.measured,
      stageStatuses: stages,
    );
    stages.clear();
    expect(
      state.statusFor(ProcessingStage.imagePreparation),
      ProcessingStageStatus.active,
    );
    expect(() => state.stageStatuses.clear(), throwsUnsupportedError);
    expect(state.isTerminal, isFalse);
    expect(state.hasMeasuredProgress, isTrue);
    expect(
      ProcessingSnapshot(status: ProcessingStatus.completed).isTerminal,
      isTrue,
    );
  });
}
