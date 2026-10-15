import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../widgets/hero_keepsake_card.dart';
import '../../../../core/network/api_exception.dart';
import '../controllers/auth_state.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient().post(
        '/api/v1/users/me/change-password',
        body: {'currentPassword': _current.text, 'newPassword': _password.text},
      );
      await AuthState.instance.clearSession();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.backendCode) {
          'INVALID_CURRENT_PASSWORD' => 'Mật khẩu hiện tại không đúng.',
          'PASSWORD_REUSE_NOT_ALLOWED' =>
            'Vui lòng chọn mật khẩu khác mật khẩu cũ.',
          'WEAK_PASSWORD' =>
            'Mật khẩu mới quá dễ đoán. Vui lòng chọn mật khẩu khác.',
          'NO_LOCAL_PASSWORD' => 'Tài khoản này chưa có mật khẩu đăng nhập.',
          _ => error.message,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _hidden = [true, true, true];

  Widget _passwordField(
    int index,
    String label,
    String hint,
    TextEditingController controller,
    FormFieldValidator<String> validator, {
    String? helper,
  }) => M3Field(
    label: label,
    hint: hint,
    controller: controller,
    obscure: _hidden[index],
    enabled: !_busy,
    helper: helper,
    validator: validator,
    suffix: IconButton(
      onPressed: () => setState(() => _hidden[index] = !_hidden[index]),
      icon: Icon(
        _hidden[index]
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 19,
        color: const Color(0xFF4B5563),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: const M3TopBar(title: 'Đổi mật khẩu', showAvatar: false),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const HeroKeepsakeCard(),
          const SizedBox(height: 22),
          _passwordField(
            0,
            'Mật khẩu hiện tại',
            'Nhập mật khẩu hiện tại',
            _current,
            (v) => v == null || v.isEmpty
                ? 'Vui lòng nhập mật khẩu hiện tại.'
                : null,
          ),
          const SizedBox(height: 16),
          _passwordField(
            1,
            'Mật khẩu mới',
            'Nhập mật khẩu mới',
            _password,
            (v) => v == null || v.length < 12 || v.length > 128
                ? 'Mật khẩu phải từ 12 đến 128 ký tự.'
                : null,
            helper: 'Từ 12 đến 128 ký tự',
          ),
          const SizedBox(height: 16),
          _passwordField(
            2,
            'Xác nhận mật khẩu mới',
            'Xác nhận mật khẩu mới',
            _confirmation,
            (v) => v != _password.text ? 'Mật khẩu xác nhận chưa khớp.' : null,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: m3Text(13, color: AppColors.error)),
            ),
          const SizedBox(height: 26),
          M3Button(
            label: 'Đổi mật khẩu',
            style: M3ButtonStyle.solid,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );
}
