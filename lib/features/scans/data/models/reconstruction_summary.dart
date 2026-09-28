enum ReconstructionQualityStatus { green, amber }

/// An upstream quality report supplies these values before reconstruction.
class ReconstructionSummary {
  const ReconstructionSummary({
    required this.qualifiedImageCount,
    required this.qualityScore,
    required this.qualityStatus,
    required this.estimatedProcessingTime,
  });

  final int qualifiedImageCount;
  final int qualityScore;
  final ReconstructionQualityStatus qualityStatus;
  final Duration estimatedProcessingTime;
}
