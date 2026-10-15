import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
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
        appBar: M3TopBar(
          title: strings.emailVerificationTitle,
          showAvatar: false,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _emailHero(
                        tint: tint,
                        accent: accent,
                        icon: success
                            ? Icons.mark_email_read_outlined
                            : invalid
                            ? Icons.mark_email_unread_outlined
                            : Icons.mail_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: m3Text(22, weight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: m3Text(
                        13.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (state.hasEmail) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state.email!.trim(),
                            textAlign: TextAlign.center,
                            style: m3Text(13.5, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (verifying)
                      _card(
                        tint: AppColors.tint,
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
                              style: m3Text(
                                13.5,
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
                          style: m3Text(
                            13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.tintStrong),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RotationTransition(
                                  turns: MediaQuery.disableAnimationsOf(context)
                                      ? const AlwaysStoppedAnimation(0)
                                      : _pulse,
                                  child: const Icon(
                                    Icons.sync_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    strings.emailVerificationWaiting,
                                    style: m3Text(
                                      12.5,
                                      weight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        M3Button(
                          label: 'Tôi đã xác thực email',
                          style: M3ButtonStyle.solid,
                          trailing: Icons.arrow_forward_rounded,
                          onPressed: _continued ? null : _continue,
                        ),
                        const SizedBox(height: 10),
                        M3Button(
                          label: 'Thay đổi địa chỉ email',
                          style: M3ButtonStyle.outline,
                          leading: Icons.edit_outlined,
                          height: 46,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 18),
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
                            }, style: m3Text(13)),
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
                            : AppColors.tint,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.emailVerificationResendTitle,
                              textAlign: TextAlign.center,
                              style: m3Text(14, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.hasEmail
                                  ? strings.emailVerificationSpamHint
                                  : strings.emailVerificationUnknownEmail,
                              textAlign: TextAlign.center,
                              style: m3Text(
                                12.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              key: const ValueKey('emailResendButton'),
                              onPressed: state.canResend ? state.resend : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppColors.primary,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: AppColors.textMuted,
                                elevation: 0,
                                textStyle: m3Text(13, weight: FontWeight.w700)
                                    .copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (state.isResending)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      state.remainingSeconds > 0
                                          ? Icons.timer_outlined
                                          : Icons.send_rounded,
                                      size: 16,
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
                      const SizedBox(height: 14),
                      _card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const M3IconTile(
                              Icons.verified_user_rounded,
                              size: 36,
                              radius: 10,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Memento3D Cloud Auth',
                                          style: m3Text(
                                            13,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bảo mật tài khoản và quyền truy cập mô '
                                    'hình 3D đám mây được kích hoạt sau khi '
                                    'xác minh.',
                                    style: m3Text(
                                      12,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
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
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  Widget _card({required Widget child, Color tint = AppColors.surface}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
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

  Widget _emailHero({
    required Color tint,
    required Color accent,
    required IconData icon,
  }) => ExcludeSemantics(
    child: SizedBox(
      width: 150,
      height: 138,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 38, color: accent),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.badgeGreenBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 12,
                    color: AppColors.badgeGreenText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Link Auth',
                    style: m3Text(
                      10.5,
                      weight: FontWeight.w700,
                      color: AppColors.badgeGreenText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
