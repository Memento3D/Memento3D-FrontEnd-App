import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';
import 'quality_report_presentation.dart';

/// Direct score visualization; category is supplied independently.
class QualityScoreGauge extends StatelessWidget {
  const QualityScoreGauge({
    super.key,
    required this.score,
    required this.category,
  });
  final num score;
  final QualityCategory category;
  @override
  Widget build(BuildContext context) {
    final color = QualityReportColors.accent(category);
    // Invalid numbers get a track only, never a fabricated valid score/category.
    final progress = score.isFinite && score >= 0 && score <= 100
        ? score.toDouble() / 100
        : 0.0;
    return Semantics(
      label: AppLocalizations.of(context)!.qualityReportScore(score.toString()),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: QualityScoreGaugePainter(
                progress: progress,
                color: color,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$score/100',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QualityScoreGaugePainter extends CustomPainter {
  const QualityScoreGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Rect.fromCircle(
      center: rect.center,
      radius: math.min(size.width, size.height) / 2 - 6,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      circle,
      0,
      2 * math.pi,
      false,
      paint..color = color.withValues(alpha: 0.10),
    );
    if (progress > 0) {
      canvas.drawArc(
        circle,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QualityScoreGaugePainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
