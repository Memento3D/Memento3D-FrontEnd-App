/// Frontend input semantics; these values are not a backend serialized enum.
enum QualityClassification { green, amber, red, unknown }

/// Presentation input supplied by the caller, not a backend DTO.
final class QualityOverrideContext {
  const QualityOverrideContext({
    required this.scanId,
    required this.qualityRunId,
    required this.classification,
    required this.qualifiedImageCount,
    required this.affectedImageCount,
    required this.overallQualityPercentage,
  });

  final String scanId;
  final String qualityRunId;
  final QualityClassification classification;
  final int qualifiedImageCount;
  final int affectedImageCount;

  /// Caller-supplied presentation percentage; never used as a threshold.
  final double overallQualityPercentage;

  bool get isEligible =>
      classification == QualityClassification.amber &&
      scanId.trim().isNotEmpty &&
      qualityRunId.trim().isNotEmpty;
}
