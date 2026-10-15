import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/scan_item.dart';
import '../../data/repositories/scan_repository.dart';
import 'scan_job_monitor_screen.dart';

/// "Submit Reconstruction" review screen (US-027, FR-081, FR-082, FR-199).
///
/// Shown right after quality check passes (or is overridden, US-022) and
/// right before [ScanRepository.submitReconstructionJobAsync] fires
/// `POST /api/v1/scans/{id}/job`. Lets the user review the photo count,
/// quality score and estimated processing time, then submit or go back.
class ScanJobSubmitScreen extends StatefulWidget {
  const ScanJobSubmitScreen({super.key, required this.scan, this.repository});

  final ScanItem scan;

  /// Allows injecting a mock repository in tests.
  final ScanRepository? repository;

  @override
  State<ScanJobSubmitScreen> createState() => _ScanJobSubmitScreenState();
}

class _ScanJobSubmitScreenState extends State<ScanJobSubmitScreen> {
  // Below this score the pipeline rejects the submission outright (UC-04, E1).
  static const int _minSubmittableScore = 50;
  // Between the minimum and this score, submission is allowed but the user
  // is shown a non-blocking Amber warning (US-022, "Override & Submit").
  static const int _warningThreshold = 80;

  bool _isSubmitting = false;
  String? _errorMessage;

  ScanRepository get _repository =>
      widget.repository ?? ScanRepository.instance;

  bool get _belowMinimum {
    final score = widget.scan.qualityScore;
    return score != null && score < _minSubmittableScore;
  }

  bool get _hasWarning {
    final score = widget.scan.qualityScore;
    return score != null &&
        score >= _minSubmittableScore &&
        score < _warningThreshold;
  }

  bool get _canSubmit => !_isSubmitting && !_belowMinimum;

  /// Rough client-side estimate shown before a job (and its server-side ETA)
  /// even exists. ~0.4–0.9 minute per photo, floored at 2 minutes.
  int get _etaMinMinutes =>
      ((widget.scan.fileCount * 0.4).ceil()).clamp(2, 999);
  int get _etaMaxMinutes =>
      ((widget.scan.fileCount * 0.9).ceil()).clamp(_etaMinMinutes + 1, 999);

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final job = await _repository.submitReconstructionJobAsync(
        widget.scan.id,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              ScanJobMonitorScreen(scan: widget.scan, job: job),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Không thể gửi yêu cầu dựng mô hình 3D. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Quay lại',
        ),
        title: Text(
          'Xác nhận dựng mô hình 3D',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                children: [
                  Text(
                    widget.scan.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kiểm tra lại thông tin trước khi gửi yêu cầu dựng mô hình 3D.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _overviewCard(),
                  if (_hasWarning) ...[
                    const SizedBox(height: 14),
                    _amberWarningBanner(),
                  ],
                  if (_belowMinimum) ...[
                    const SizedBox(height: 14),
                    _blockedBanner(),
                  ],
                ],
              ),
            ),
            _bottomActions(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Overview card — file count / quality score / ETA
  // ---------------------------------------------------------------

  Widget _overviewCard() {
    final score = widget.scan.qualityScore;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _overviewRow(
            icon: Icons.photo_library_outlined,
            title: 'Số lượng ảnh/video',
            value: '${widget.scan.fileCount} tệp',
          ),
          const Divider(height: 22, color: AppColors.cardBorder),
          _overviewRow(
            icon: Icons.verified_outlined,
            title: 'Điểm chất lượng',
            value: score != null ? '$score/100' : 'Chưa có dữ liệu',
            trailing: score != null ? _qualityBadge(score) : null,
          ),
          const Divider(height: 22, color: AppColors.cardBorder),
          _overviewRow(
            icon: Icons.access_time_rounded,
            title: 'Thời gian dự kiến',
            value: '$_etaMinMinutes–$_etaMaxMinutes phút',
          ),
        ],
      ),
    );
  }

  Widget _overviewRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.badgePurpleBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _qualityBadge(int score) {
    final Color bg;
    final Color fg;
    final String label;
    if (score >= _warningThreshold) {
      bg = AppColors.badgeGreenBg;
      fg = AppColors.badgeGreenText;
      label = 'Tốt';
    } else if (score >= _minSubmittableScore) {
      bg = AppColors.warningAmberBg;
      fg = AppColors.warningAmberText;
      label = 'Cảnh báo';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = AppColors.error;
      label = 'Không đạt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Banners
  // ---------------------------------------------------------------

  Widget _amberWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.warningAmberIcon,
            semanticLabel: 'Warning',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Điểm chất lượng ở mức cảnh báo. Mô hình 3D vẫn sẽ được dựng, nhưng có thể thiếu chi tiết ở một số vùng. '
              'Bạn có thể quay lại bổ sung ảnh để có kết quả tốt hơn, hoặc tiếp tục gửi (Override & Submit).',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.warningAmberText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.error,
            semanticLabel: 'Error',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Điểm chất lượng dưới mức tối thiểu để dựng mô hình 3D. Vui lòng quay lại và bổ sung thêm ảnh.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Bottom actions — Back + Submit
  // ---------------------------------------------------------------

  Widget _bottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Quay lại',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Bắt đầu dựng 3D',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
