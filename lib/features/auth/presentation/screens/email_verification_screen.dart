import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/email_verification_state.dart';

/// The caller owns and disposes [state], and decides what continuation means.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  final EmailVerificationState state;
  final VoidCallback onContinue;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.state.refreshTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  void _continue() {
    if (_continued) return;
    setState(() => _continued = true);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final state = widget.state;
      final strings = AppLocalizations.of(context)!;
      final theme = Theme.of(context).textTheme;
      final success = state.phase == EmailVerificationStatus.success;
      final invalid = state.phase == EmailVerificationStatus.invalidOrExpired;
      final verifying = state.phase == EmailVerificationStatus.verifying;
      final accent = success
          ? AppColors.badgeGreenText
          : invalid
          ? AppColors.badgeOrangeText
          : AppColors.primary;
      final tint = success
          ? AppColors.badgeGreenBg
          : invalid
          ? AppColors.badgeOrangeBg
          : AppColors.badgePurpleBg;
      final heading = success
          ? strings.emailVerificationSuccessTitle
          : invalid
          ? strings.emailVerificationInvalidTitle
          : verifying
          ? strings.emailVerificationVerifying
          : strings.emailVerificationHeading;
      final body = success
          ? strings.emailVerificationSuccessBody
          : invalid
          ? strings.emailVerificationInvalidBody
          : verifying
          ? strings.emailVerificationVerifyingBody
          : state.hasEmail
          ? strings.emailVerificationSentBody
          : strings.emailVerificationUnknownEmail;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: strings.back,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.emailVerificationTitle,
                            style: theme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _emailHero(
                        tint: tint,
                        accent: accent,
                        icon: success
                            ? Icons.mark_email_read_outlined
                            : invalid
                            ? Icons.mark_email_unread_outlined
                            : Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: theme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (state.hasEmail) ...[
                      const SizedBox(height: 16),
                      _card(
                        tint: AppColors.badgePurpleBg,
                        child: Text(
                          state.email!.trim(),
                          textAlign: TextAlign.center,
                          style: theme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (verifying)
                      _card(
                        tint: AppColors.badgePurpleBg,
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              semanticsLabel:
                                  strings.emailVerificationVerifying,
                              color: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.emailVerificationVerifyingHint,
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium?.copyWith(
                                color: AppColors.primaryDark,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (success)
                      FilledButton(
                        onPressed: _continued ? null : _continue,
                        style: _buttonStyle(),
                        child: Text(strings.emailVerificationContinue),
                      )
                    else ...[
                      if (!invalid) ...[
                        Text(
                          strings.emailVerificationInstruction,
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          tint: AppColors.badgePurpleBg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeTransition(
                                    opacity:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? const AlwaysStoppedAnimation(1)
                                        : Tween<double>(
                                            begin: 0.35,
                                            end: 1,
                                          ).animate(_pulse),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.hourglass_top_rounded,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      strings.emailVerificationWaiting,
                                      style: theme.titleMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                strings.emailVerificationWaitingBody,
                                style: theme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (state.feedback != null) ...[
                        _card(
                          tint:
                              state.feedback ==
                                  EmailVerificationFeedback.resendSent
                              ? AppColors.badgeGreenBg
                              : AppColors.badgeOrangeBg,
                          child: Semantics(
                            liveRegion: true,
                            child: Text(switch (state.feedback!) {
                              EmailVerificationFeedback.resendSent =>
                                strings.emailVerificationResendSuccess,
                              EmailVerificationFeedback.resendFailed =>
                                strings.emailVerificationResendFailure,
                              EmailVerificationFeedback.verificationFailed =>
                                strings.emailVerificationFailure,
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (state.canRetryVerification) ...[
                          OutlinedButton(
                            onPressed: state.retryVerification,
                            child: Text(strings.retry),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      _card(
                        tint: invalid
                            ? AppColors.badgeOrangeBg
                            : AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.emailVerificationResendTitle,
                              style: theme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (state.hasEmail) ...[
                              _hint(
                                context,
                                Icons.inbox_outlined,
                                strings.emailVerificationSpamHint,
                              ),
                              const SizedBox(height: 14),
                              _hint(
                                context,
                                Icons.alternate_email_rounded,
                                strings.emailVerificationAddressHint,
                              ),
                              const SizedBox(height: 14),
                              _hint(
                                context,
                                Icons.schedule_rounded,
                                strings.emailVerificationDeliveryHint,
                              ),
                            ] else
                              Text(
                                strings.emailVerificationUnknownEmail,
                                style: theme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 18),
                            FilledButton(
                              key: const ValueKey('emailResendButton'),
                              onPressed: state.canResend ? state.resend : null,
                              style: _buttonStyle(),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  if (state.isResending)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      state.remainingSeconds > 0
                                          ? Icons.timer_outlined
                                          : Icons.send_rounded,
                                      size: 18,
                                    ),
                                  Text(
                                    state.isResending
                                        ? strings.emailVerificationSending
                                        : state.remainingSeconds > 0
                                        ? strings.emailVerificationRetryAfter(
                                            state.remainingSeconds,
                                          )
                                        : invalid
                                        ? strings.emailVerificationResendNew
                                        : strings.emailVerificationResend,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.badgePurpleBg,
    disabledForegroundColor: AppColors.primaryDark,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  Widget _card({required Widget child, Color tint = AppColors.surface}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  Widget _hint(BuildContext context, IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.badgePurpleBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      ),
    ],
  );

  Widget _emailHero({
    required Color tint,
    required Color accent,
    required IconData icon,
  }) => ExcludeSemantics(
    child: SizedBox(
      width: 176,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 104,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: accent.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 56, color: accent),
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: Icon(Icons.auto_awesome, size: 22, color: accent),
          ),
          Positioned(
            left: 12,
            bottom: 22,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
