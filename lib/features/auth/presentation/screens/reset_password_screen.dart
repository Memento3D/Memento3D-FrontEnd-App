import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/password_recovery_service.dart';
import '../controllers/reset_password_state.dart';
import '../widgets/recovery_presentation.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';

/// In-memory entry only; token URL handling remains deferred.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.resetToken,
    this.loginRoute,
    this.service = const UnavailablePasswordRecoveryService(),
  });

  final String? resetToken;

  /// Optional caller-owned Login boundary in this Navigator. Routes below it
  /// are preserved; without it, only this Reset route is replaced.
  final Route<dynamic>? loginRoute;
  final PasswordRecoveryService service;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final ResetPasswordState _recovery;
  bool _showPassword = false;
  bool _showConfirmation = false;
  bool _validationAttempted = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _recovery = ResetPasswordState(
      widget.service,
      hasToken: widget.resetToken?.trim().isNotEmpty ?? false,
    )..addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    if (_recovery.isTerminal) {
      _validationAttempted = false;
      _password.clear();
      _confirmation.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _recovery.removeListener(_onChanged);
    _recovery.dispose();
    _password.clear();
    _confirmation.clear();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _revalidate(String _) {
    if (_validationAttempted) _formKey.currentState?.validate();
  }

  void _submit() {
    if (_recovery.isSubmitting || _recovery.isTerminal) {
      return;
    }
    _validationAttempted = true;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _recovery.submit(token: widget.resetToken, newPassword: _password.text);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback toggle,
    required String? Function(String?) validator,
    required AppLocalizations strings,
    required TextInputAction action,
  }) => TextFormField(
    controller: controller,
    enabled: !_recovery.isSubmitting,
    obscureText: !visible,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: action,
    onChanged: _revalidate,
    onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      errorMaxLines: 5,
      filled: true,
      fillColor: RecoveryColors.surfaceLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      suffixIcon: Semantics(
        label: visible
            ? strings.resetPasswordHidePassword
            : strings.resetPasswordShowPassword,
        child: IconButton(
          tooltip: visible
              ? strings.resetPasswordHidePassword
              : strings.resetPasswordShowPassword,
          onPressed: _recovery.isSubmitting ? null : toggle,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final accepted = _recovery.status == ResetPasswordStatus.accepted;
    if (_recovery.isTerminal) return _terminal(strings, textTheme, accepted);
    return RecoveryPageShell(
      title: strings.resetPasswordHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: RecoveryHero(icon: Icons.password_rounded)),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              strings.resetPasswordTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: RecoveryColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.resetPasswordSupport,
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
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    controller: _password,
                    label: strings.resetPasswordNewPassword,
                    visible: _showPassword,
                    toggle: () =>
                        setState(() => _showPassword = !_showPassword),
                    validator: (value) => value == null || value.isEmpty
                        ? strings.resetPasswordNewRequired
                        : null,
                    strings: strings,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: _confirmation,
                    label: strings.resetPasswordConfirmPassword,
                    visible: _showConfirmation,
                    toggle: () =>
                        setState(() => _showConfirmation = !_showConfirmation),
                    validator: (value) => value == null || value.isEmpty
                        ? strings.resetPasswordConfirmRequired
                        : value != _password.text
                        ? strings.resetPasswordMismatch
                        : null,
                    strings: strings,
                    action: TextInputAction.done,
                  ),
                  if (_recovery.status ==
                      ResetPasswordStatus.recoverableFailure) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        strings.resetPasswordTechnicalFailure,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: RecoveryColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: _recovery.isSubmitting,
                    child: RecoveryPrimaryButton(
                      label: _recovery.isSubmitting
                          ? strings.resetPasswordSubmitting
                          : _recovery.status ==
                                ResetPasswordStatus.recoverableFailure
                          ? strings.resetPasswordRetry
                          : strings.resetPasswordSubmit,
                      onPressed: _recovery.isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(strings.resetPasswordCancel),
            ),
          ],
        ],
      ),
    );
  }

  void _goLogin({bool requestNewLink = false}) {
    if (!mounted || _navigating) return;
    _navigating = true;
    final navigator = Navigator.of(context);
    final loginRoute = widget.loginRoute;
    if (loginRoute != null &&
        loginRoute.isActive &&
        identical(loginRoute.navigator, navigator)) {
      // The active caller-owned boundary is guaranteed to be in this stack.
      navigator.popUntil((route) => identical(route, loginRoute));
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
    if (requestNewLink) {
      // Capture only the service; the route builder must not retain this screen.
      final service = widget.service;
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordScreen(service: service),
        ),
      );
    }
  }

  Widget _terminal(
    AppLocalizations strings,
    TextTheme textTheme,
    bool accepted,
  ) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _goLogin();
    },
    child: RecoveryPageShell(
      title: accepted
          ? strings.resetPasswordHeader
          : strings.forgotPasswordHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: RecoveryHero(
              icon: accepted
                  ? Icons.check_circle_outline_rounded
                  : Icons.link_off_rounded,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              accepted
                  ? strings.resetPasswordSuccessTitle
                  : strings.resetPasswordInvalidTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: RecoveryColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            accepted
                ? strings.resetPasswordSuccessBody
                : strings.resetPasswordInvalidBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          RecoveryPrimaryButton(
            label: accepted
                ? strings.resetPasswordBackToLogin
                : strings.resetPasswordRequestNewLink,
            onPressed: () => _goLogin(requestNewLink: !accepted),
          ),
          if (!accepted) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goLogin,
              child: Text(strings.resetPasswordBackToLogin),
            ),
          ],
        ],
      ),
    ),
  );
}
