import '../../domain/reconstruction_repository.dart';
import '../services/processing_progress_source.dart';
import '../models/processing_state.dart';
import '../models/reconstruction_job_presentation_mapper.dart';

/// Presentation adapter preserving the existing controller's local lifecycle.
/// Observation errors remain available on the domain contract; integrating them
/// into controller state is deliberately deferred to Refactor B.
class RepositoryProcessingProgressSource implements ProcessingProgressSource {
  RepositoryProcessingProgressSource(this._repository);
  final ReconstructionRepository _repository;

  @override
  ProcessingUpdate get current => ProcessingUpdate(
    0,
    _repository.current == null
        ? const ProcessingSnapshot.waiting()
        : presentReconstructionJob(_repository.current!),
  );

  @override
  Stream<ProcessingUpdate> get updates => _repository.jobs.map(
    (job) => ProcessingUpdate(0, presentReconstructionJob(job)),
  );

  @override
  Future<void> retry(int attempt) =>
      Future.error(UnsupportedError('Reconstruction retry is unavailable'));

  @override
  void dispose() => _repository.dispose();
}
