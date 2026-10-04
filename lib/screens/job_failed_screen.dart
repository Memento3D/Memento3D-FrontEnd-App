import 'package:flutter/material.dart';

import '../features/scans/data/services/job_service.dart';
import '../l10n/app_localizations.dart';
import '../core/network/api_exception.dart';
import '../core/utils/error_mapper.dart';

import 'capture_session.dart';
import 'processing_screen.dart';
import 'processing_state.dart';

const _purple = Color(0xFF6B4FE8);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _border = Color(0xFFE6DFFF);

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
          builder: (_) => ProcessingScreen(
            session: CaptureSession(),
            snapshot: ProcessingSnapshot(
              status: ProcessingStatus.processing,
              jobId: job.id,
              progressPercent: job.progress != null
                  ? job.progress! * 100
                  : null,
              errorMessage: job.errorMessage,
            ),
          ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _ink),
                    tooltip: strings.back,
                  ),
                  Expanded(
                    child: Text(
                      strings.jobFailedHeaderTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: _purple,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFB91C1C),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings.jobFailedStatusBadge,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/polaroid_3d_hero.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: _lavender,
                    child: const Center(
                      child: Icon(
                        Icons.view_in_ar_outlined,
                        color: _purple,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.jobFailedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.jobFailedSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF777183), fontSize: 12),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.jobFailedCardTitle,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    friendlyError,
                    style: const TextStyle(
                      color: Color(0xFF777183),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.errorMessage != null &&
                      widget.errorMessage!.trim().isNotEmpty &&
                      widget.errorMessage != friendlyError) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_state == _JobFailedState.retryUnavailable) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  strings.jobRetryLimit,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (allowRetry)
              FilledButton.icon(
                onPressed: _state == _JobFailedState.retrying ? null : _retry,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  disabledBackgroundColor: _purple.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _state == _JobFailedState.retrying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _state == _JobFailedState.retrying
                      ? strings.jobRetrying
                      : strings.jobRetry,
                ),
              ),
            if (_state == _JobFailedState.retryFailed) ...[
              const SizedBox(height: 10),
              Text(
                strings.jobRetryFailedHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 11),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.dashboard_outlined, color: _purple),
              label: Text(
                strings.jobDashboard,
                style: const TextStyle(color: _purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
