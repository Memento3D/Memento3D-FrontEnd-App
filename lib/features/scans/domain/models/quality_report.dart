/// Frontend presentation inputs only. Not a backend schema or DTO.
enum QualityCategory { green, amber, red }

enum QualityPhotoStatus { pass, warn, fail }

class QualityPhotoResult {
  const QualityPhotoResult({
    required this.id,
    required this.assetPath,
    required this.status,
  });

  /// Stable fixture identity; does not imply a server ID format.
  final String id;
  final String assetPath;
  final QualityPhotoStatus status;
}

/// Explicit supplied presentation counts, never calculated from photo statuses.
class QualityReportSummary {
  const QualityReportSummary({
    required this.checked,
    required this.passed,
    required this.warned,
    required this.failed,
  });
  final int checked;
  final int passed;
  final int warned;
  final int failed;
}

/// Optional caller-supplied support copy, never inferred from category or score.
enum QualityReportSupport { eligible }

class QualityReport {
  QualityReport({
    required this.overallScore,
    required this.category,
    required this.suggestion,
    required List<QualityPhotoResult> photos,
    this.summary,
    this.support,
  }) : photos = List.unmodifiable(photos);
  final num overallScore;
  final QualityCategory category;
  final String suggestion;
  final List<QualityPhotoResult> photos;
  final QualityReportSummary? summary;
  final QualityReportSupport? support;
}
