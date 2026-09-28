import '../models/reconstruction_summary.dart';

/// Local fixtures and submission only: no network request or job is created.
class MockReconstructionService {
  const MockReconstructionService();

  static const greenSummary = ReconstructionSummary(
    qualifiedImageCount: 42,
    qualityScore: 86,
    qualityStatus: ReconstructionQualityStatus.green,
    estimatedProcessingTime: Duration(minutes: 4),
  );

  /// Represents an Amber report whose warning was already acknowledged upstream.
  static const amberSummary = ReconstructionSummary(
    qualifiedImageCount: 32,
    qualityScore: 68,
    qualityStatus: ReconstructionQualityStatus.amber,
    estimatedProcessingTime: Duration(minutes: 6),
  );

  Future<void> submit(ReconstructionSummary summary) async {
    // Deliberately completes locally without inventing a job or progress.
  }
}
