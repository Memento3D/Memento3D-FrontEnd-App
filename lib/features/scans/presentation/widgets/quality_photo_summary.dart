import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';
import 'quality_report_presentation.dart';

class QualityPhotoSummary extends StatelessWidget {
  const QualityPhotoSummary({
    super.key,
    required this.report,
    required this.onViewDetails,
  });
  final QualityReport report;
  final VoidCallback onViewDetails;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final summary = report.summary;
    final label = switch (report.category) {
      QualityCategory.green => strings.qualityReportViewDetails,
      QualityCategory.amber => strings.qualityReportViewWarningDetails,
      QualityCategory.red => strings.qualityReportViewErrorDetails,
    };
    return QualityReportCard(
      color: QualityReportColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.qualityReportPhotoQuality,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (summary != null) ...[
            const SizedBox(height: 6),
            Text(strings.qualityReportPhotosChecked(summary.checked)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _count(
                  context,
                  summary.passed,
                  strings.qualityReportPass,
                  QualityCategory.green,
                ),
                _count(
                  context,
                  summary.warned,
                  strings.qualityReportWarn,
                  QualityCategory.amber,
                ),
                _count(
                  context,
                  summary.failed,
                  strings.qualityReportFail,
                  QualityCategory.red,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            key: const Key('quality-report-view-details'),
            onPressed: onViewDetails,
            style: TextButton.styleFrom(
              foregroundColor: QualityReportColors.primary,
              minimumSize: const Size(48, 48),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _count(
    BuildContext context,
    int count,
    String label,
    QualityCategory category,
  ) => Text(
    '$count $label',
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: QualityReportColors.accent(category),
      fontWeight: FontWeight.w700,
    ),
  );
}
