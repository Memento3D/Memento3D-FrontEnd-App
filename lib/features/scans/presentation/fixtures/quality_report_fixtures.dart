import '../../domain/models/quality_report.dart';

/// Deterministic frontend preview fixtures. These are NOT API examples.
abstract final class QualityReportFixtures {
  static final green = QualityReport(
    overallScore: 82,
    category: QualityCategory.green,
    support: QualityReportSupport.eligible,
    suggestion: 'Giữ vật thể trong vùng đủ sáng và chụp thêm các góc còn thiếu để cải thiện độ chi tiết của mô hình.',
    summary: const QualityReportSummary(
      checked: 24,
      passed: 18,
      warned: 4,
      failed: 2,
    ),
    photos: [
      for (var i = 1; i <= 18; i++)
        QualityPhotoResult(
          id: 'green-pass-$i',
          assetPath: 'assets/images/polaroid_3d_hero.jpg',
          status: QualityPhotoStatus.pass,
        ),
      for (var i = 1; i <= 4; i++)
        QualityPhotoResult(
          id: 'green-warn-$i',
          assetPath: 'assets/images/besties_keepsake.jpg',
          status: QualityPhotoStatus.warn,
        ),
      for (var i = 1; i <= 2; i++)
        QualityPhotoResult(
          id: 'green-fail-$i',
          assetPath: 'assets/images/polaroid_3d_hero.jpg',
          status: QualityPhotoStatus.fail,
        ),
    ],
  );
  static final amber = QualityReport(
    overallScore: 67,
    category: QualityCategory.amber,
    suggestion: 'Review the supplied photo results before continuing.',
    summary: const QualityReportSummary(
      checked: 3,
      passed: 1,
      warned: 1,
      failed: 1,
    ),
    photos: const [
      QualityPhotoResult(
        id: 'amber-pass',
        assetPath: 'assets/images/polaroid_3d_hero.jpg',
        status: QualityPhotoStatus.pass,
      ),
      QualityPhotoResult(
        id: 'amber-warn',
        assetPath: 'assets/images/besties_keepsake.jpg',
        status: QualityPhotoStatus.warn,
      ),
      QualityPhotoResult(
        id: 'amber-fail',
        assetPath: 'assets/images/polaroid_3d_hero.jpg',
        status: QualityPhotoStatus.fail,
      ),
    ],
  );
  static final red = QualityReport(
    overallScore: 31,
    category: QualityCategory.red,
    suggestion: 'Return to your photos to review the supplied results.',
    summary: const QualityReportSummary(
      checked: 2,
      passed: 0,
      warned: 1,
      failed: 1,
    ),
    photos: const [
      QualityPhotoResult(
        id: 'red-warn',
        assetPath: 'assets/images/besties_keepsake.jpg',
        status: QualityPhotoStatus.warn,
      ),
      QualityPhotoResult(
        id: 'red-fail',
        assetPath: 'assets/images/polaroid_3d_hero.jpg',
        status: QualityPhotoStatus.fail,
      ),
    ],
  );
}
