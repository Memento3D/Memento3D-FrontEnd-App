import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/recovery_presentation.dart';
import '../../data/services/password_recovery_service.dart';
import '../controllers/forgot_password_state.dart';

/// Recovery flow with a screen-owned controller and local email input.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.service = const UnavailablePasswordRecoveryService(),
  });

  final PasswordRecoveryService service;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final ForgotPasswordState _recovery;

  @override
  void initState() {
    super.initState();
    _recovery = ForgotPasswordState(widget.service);
    _recovery.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recovery.removeListener(_onChanged);
    _recovery.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_recovery.isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      _recovery.requestReset(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return RecoveryPageShell(
      title: strings.forgotPasswordHeader,
      child: _recovery.hasAcceptedRequest
          ? _sent(strings, textTheme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: RecoveryHero()),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    strings.forgotPasswordTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: RecoveryColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: RecoveryColors.secondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: RecoveryColors.surface),
                    boxShadow: [
                      BoxShadow(
                        color: RecoveryColors.primary.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_recovery.isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: strings.forgotPasswordEmailLabel,
                            hintText: strings.forgotPasswordEmailHint,
                            helperText: strings.forgotPasswordEmailHelper,
                            helperMaxLines: 5,
                            errorMaxLines: 5,
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: RecoveryColors.primary,
                            ),
                            filled: true,
                            fillColor: RecoveryColors.surfaceLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: RecoveryColors.light,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: RecoveryColors.primary,
                                width: 1.6,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: RecoveryColors.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: RecoveryColors.error,
                                width: 1.6,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              color: RecoveryColors.error,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? strings.forgotPasswordEmailRequired
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: _recovery.isSubmitting,
                          child: RecoveryPrimaryButton(
                            label: _recovery.isSubmitting
                                ? strings.forgotPasswordSubmitting
                                : _recovery.status ==
                                      ForgotPasswordStatus.recoverableFailure
                                ? strings.forgotPasswordRetry
                                : strings.forgotPasswordSubmit,
                            onPressed: _recovery.isSubmitting ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._failure(strings),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    strings.forgotPasswordCancel,
                    style: const TextStyle(color: RecoveryColors.secondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    strings.forgotPasswordBackToLogin,
                    style: const TextStyle(color: RecoveryColors.primary),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _failure(AppLocalizations strings) =>
      _recovery.status == ForgotPasswordStatus.recoverableFailure
      ? [
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              strings.forgotPasswordTechnicalFailure,
              textAlign: TextAlign.center,
              style: const TextStyle(color: RecoveryColors.error),
            ),
          ),
        ]
      : [];

  Widget _sent(AppLocalizations strings, TextTheme textTheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: RecoveryHero(icon: Icons.mark_email_unread_rounded)),
      const SizedBox(height: 20),
      Semantics(
        header: true,
        liveRegion: true,
        child: Text(
          strings.forgotPasswordSentTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: RecoveryColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(strings.forgotPasswordSentBody, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(strings.forgotPasswordSentSupport, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: RecoveryColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.forgotPasswordGuidanceTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(strings.forgotPasswordSpamGuidance),
            const SizedBox(height: 8),
            Text(strings.forgotPasswordDeliveryGuidance),
          ],
        ),
      ),
      ..._failure(strings),
      const SizedBox(height: 24),
      Semantics(
        liveRegion: _recovery.isSubmitting,
        child: RecoveryPrimaryButton(
          label: _recovery.isSubmitting
              ? strings.forgotPasswordResending
              : strings.forgotPasswordResend,
          onPressed: _recovery.isSubmitting
              ? null
              : () => _recovery.requestReset(_emailController.text.trim()),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: Text(strings.forgotPasswordBackToLogin),
      ),
    ],
  );
}
