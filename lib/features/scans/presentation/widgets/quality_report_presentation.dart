import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';

abstract final class QualityReportColors {
  static const background = Color(0xFFFDF8FF);
  static const primary = Color(0xFF5B3CDD);
  static const lavender = Color(0xFFF1EBFF);
  static const ink = Color(0xFF1C1831);
  static const muted = Color(0xFF625B70);
  static Color accent(QualityCategory category) => switch (category) {
    QualityCategory.green => const Color(0xFF177449),
    QualityCategory.amber => const Color(0xFF946000),
    QualityCategory.red => const Color(0xFFBA1A1A),
  };
  static String label(QualityCategory category, AppLocalizations strings) =>
      switch (category) {
        QualityCategory.green => strings.qualityReportCategoryGreen,
        QualityCategory.amber => strings.qualityReportCategoryAmber,
        QualityCategory.red => strings.qualityReportCategoryRed,
      };
  static IconData icon(QualityCategory category) => switch (category) {
    QualityCategory.green => Icons.check_circle_outline,
    QualityCategory.amber => Icons.warning_amber_rounded,
    QualityCategory.red => Icons.error_outline,
  };
}

class QualityReportCard extends StatelessWidget {
  const QualityReportCard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: QualityReportColors.primary.withValues(alpha: 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: QualityReportColors.primary.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
