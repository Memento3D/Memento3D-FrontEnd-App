import 'package:flutter/material.dart';

import '../features/scans/data/services/job_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_exception.dart';
import '../core/widgets/m3_ui.dart';
import '../core/utils/error_mapper.dart';

import 'processing_screen.dart';
import 'processing_state.dart';

enum _JobFailedState { initial, retrying, retryFailed, retryUnavailable }

/// Job Failed / Error screen ([#19]) shown when a 3D generation job fails.
class JobFailedScreen extends StatefulWidget {
  const JobFailedScreen({
    super.key,
    required this.jobId,
    this.scanId,
    this.errorMessage,
    this.jobService,
  });

  final String jobId;
  final String? scanId;
  final String? errorMessage;

  /// Injectable for tests.
  final JobService? jobService;

  @override
  State<JobFailedScreen> createState() => _JobFailedScreenState();
}

class _JobFailedScreenState extends State<JobFailedScreen> {
  _JobFailedState _state = _JobFailedState.initial;
  bool _navigated = false;

  Future<void> _retry() async {
    if (_state == _JobFailedState.retrying || _navigated) return;
    setState(() => _state = _JobFailedState.retrying);
    try {
      final service = widget.jobService ?? JobService();
      final job = await service.retryJob(widget.jobId);
      if (!mounted) return;
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) {
            // Observe the retried job by scan when known; otherwise show the
            // retry response as a static snapshot.
            final scanId = widget.scanId ?? job.scanId;
            return ProcessingScreen(
              scanId: scanId,
              jobService: widget.jobService,
              snapshot: scanId == null
                  ? ProcessingSnapshot(
                      status: ProcessingStatus.running,
                      stage: job.stage,
                      progress: job.progress,
                      etaSeconds: job.etaSeconds,
                      errorMessage: job.errorMessage,
                    )
                  : null,
            );
          },
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 400) {
        setState(() => _state = _JobFailedState.retryUnavailable);
      } else {
        setState(() => _state = _JobFailedState.retryFailed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _JobFailedState.retryFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final friendlyError = ErrorMapper.friendlyJobErrorMessage(
      widget.errorMessage,
    );
    final allowRetry = _state != _JobFailedState.retryUnavailable;

    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: M3TopBar(
        title: strings.jobFailedHeaderTitle,
        centerTitle: true,
        showAvatar: false,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Center(
              child: SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFECACA),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.view_in_ar_outlined,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: M3Pill(
                strings.jobFailedStatusBadge,
                dot: true,
                color: const Color(0xFFB91C1C),
                background: const Color(0xFFFEE2E2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.jobFailedTitle,
              textAlign: TextAlign.center,
              style: m3Text(21, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.jobFailedSubtitle,
              textAlign: TextAlign.center,
              style: m3Text(13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 18),
            M3Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const M3IconTile(
                        Icons.help_outline_rounded,
                        size: 32,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.jobFailedCardTitle,
                          style: m3Text(16, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friendlyError, style: m3Text(13, height: 1.5)),
                        if (widget.errorMessage != null &&
                            widget.errorMessage!.trim().isNotEmpty &&
                            widget.errorMessage != friendlyError) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.errorMessage!,
                            style: m3Text(10.5, color: const Color(0xFFB45309)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            M3Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const M3IconTile(
                        Icons.lightbulb_outline_rounded,
                        size: 32,
                        radius: 10,
                        color: AppColors.badgeGreenText,
                        background: AppColors.badgeGreenBg,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vi
                                  ? 'Gợi ý chụp lại hiệu quả'
                                  : 'Tips for a better capture',
                              style: m3Text(15, weight: FontWeight.w700),
                            ),
                            Text(
                              vi
                                  ? 'Để mô hình tái hiện sắc nét và chính xác'
                                  : 'For a sharper, more accurate model',
                              style: m3Text(
                                11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _tip(
                    1,
                    vi
                        ? 'Di chuyển chậm và đều tay'
                        : 'Move slowly and steadily',
                    vi
                        ? 'Đi xung quanh vật thể theo vòng tròn đều, giữ khoảng cách ổn định.'
                        : 'Circle the object evenly and keep a steady distance.',
                  ),
                  const SizedBox(height: 10),
                  _tip(
                    2,
                    vi ? 'Đảm bảo ánh sáng đồng đều' : 'Keep the lighting even',
                    vi
                        ? 'Chiếu sáng đều vật thể, hạn chế bóng đổ gắt và bề mặt phản chiếu chói.'
                        : 'Light the object evenly and avoid harsh shadows or glare.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_state == _JobFailedState.retryUnavailable) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningAmberBg,
                  border: Border.all(color: AppColors.warningAmberBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  strings.jobRetryLimit,
                  textAlign: TextAlign.center,
                  style: m3Text(12, color: AppColors.warningAmberText),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (allowRetry)
              M3Button(
                label: _state == _JobFailedState.retrying
                    ? strings.jobRetrying
                    : strings.jobRetry,
                style: M3ButtonStyle.solid,
                leading: _state == _JobFailedState.retrying
                    ? null
                    : Icons.refresh_rounded,
                onPressed: _state == _JobFailedState.retrying ? null : _retry,
              ),
            if (_state == _JobFailedState.retryFailed) ...[
              const SizedBox(height: 10),
              Text(
                strings.jobRetryFailedHint,
                textAlign: TextAlign.center,
                style: m3Text(11.5, color: const Color(0xFFB91C1C)),
              ),
            ],
            const SizedBox(height: 10),
            M3Button(
              label: strings.jobDashboard,
              style: M3ButtonStyle.tint,
              leading: Icons.dashboard_outlined,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(int number, String title, String body) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.tint.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: m3Text(12, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: m3Text(13, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                body,
                style: m3Text(12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
