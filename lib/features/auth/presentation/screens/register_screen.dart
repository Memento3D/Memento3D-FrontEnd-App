import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:memento3d_frontend_app/core/widgets/m3_ui.dart';

import 'verification_entry_screen.dart';

import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  Future<void> _showLegal(String kind) async {
    final title = kind == 'terms'
        ? 'Điều khoản sử dụng'
        : 'Chính sách quyền riêng tư';
    try {
      final response = await ApiClient().get('/api/v1/legal/$kind/current');
      if (response is! Map || response['content'] is! String) {
        throw const FormatException('Invalid legal document');
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(response['title']?.toString() ?? title),
          content: SingleChildScrollView(
            child: SelectableText(response['content'] as String),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải $title. Vui lòng thử lại.')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đồng ý với điều khoản để tiếp tục!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : 'Đăng';

      final registerResponse = await AuthState.instance.register(
        email: email,
        password: password,
        fullName: fullName,
        agreeTerms: _agreeToTerms,
      );

      if (!mounted) return;

      if (registerResponse != null) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationEntryScreen(email: email),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        final error =
            AuthState.instance.errorMessage ?? 'Đăng ký không thành công';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header: Back tile + Welcome pill
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const M3Pill(
                      "Welcome",
                      color: AppColors.textSecondary,
                      background: AppColors.tint,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 4. Form Fields: Full Name, Email, Password, Confirm Password
                _buildFullNameField(),

                const SizedBox(height: 16),

                _buildEmailField(),

                const SizedBox(height: 16),

                _buildPasswordField(),

                const SizedBox(height: 16),

                _buildConfirmPasswordField(),

                const SizedBox(height: 18),

                // 5. Checkbox: I'm ready to turn moments into keepsakes ✨
                _buildTermsCheckbox(),

                const SizedBox(height: 20),

                // 6. Action Button: Create My Account
                _buildSubmitButton(),

                const SizedBox(height: 18),

                // 7. Divider: or continue with
                _buildDivider(),

                const SizedBox(height: 16),

                // 8. Google Sign-In Button
                GoogleSignInButton(
                  text: 'Sign up with Google',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tính năng đăng ký qua Google sẽ được tích hợp sau.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 9. Footer: Already have an account? Log in
                _buildFooter(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 4a. Full Name Field
  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Avery Morgan',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: Color(0xFF4B5563),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập họ và tên';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 4b. Email Address Field
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'avery.morgan@example.com',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 20,
                color: Color(0xFF4B5563),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập địa chỉ email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(value.trim())) {
              return 'Địa chỉ email không đúng định dạng';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 4c. Password Field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Use 8 or more characters',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: Color(0xFF4B5563),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 8) {
              return 'Mật khẩu phải chứa ít nhất 8 ký tự';
            }
            if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
              return 'Mật khẩu phải chứa ít nhất một chữ cái';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Mật khẩu phải chứa ít nhất một chữ số';
            }
            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
              return 'Mật khẩu phải chứa ít nhất một ký tự đặc biệt (!, @, #, \$, ...)';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 4d. Confirm Password Field
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Repeat your password',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: Color(0xFF4B5563),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận lại mật khẩu';
            }
            if (value != _passwordController.text) {
              return 'Mật khẩu xác nhận không khớp';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 5. Checkbox: I'm ready to turn moments into keepsakes ✨
  Widget _buildTermsCheckbox() {
    final bodyStyle = m3Text(12.5, color: const Color(0xFF374151));
    final linkStyle = m3Text(
      12.5,
      weight: FontWeight.w700,
      color: AppColors.primary,
    );
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _agreeToTerms ? AppColors.primary : AppColors.tint,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: _agreeToTerms
                          ? AppColors.primary
                          : AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  child: _agreeToTerms
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Tôi đồng ý với ', style: bodyStyle),
                      GestureDetector(
                        onTap: () => _showLegal('terms'),
                        child: Text('Điều khoản sử dụng', style: linkStyle),
                      ),
                      Text(' và ', style: bodyStyle),
                      GestureDetector(
                        onTap: () => _showLegal('privacy'),
                        child: Text(
                          'Chính sách quyền riêng tư',
                          style: linkStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 6. Primary Action Button: Create My Account 🚀
  Widget _buildSubmitButton() {
    return M3Button(
      label: 'Join Memento3D',
      leading: Icons.person_add_alt_1_outlined,
      loading: _isLoading,
      onPressed: _handleRegister,
    );
  }

  /// 8. Divider: or continue with
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: m3Text(
              11,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.cardBorder)),
      ],
    );
  }

  /// 9. Footer: Already have an account? Log in
  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Already have an account? ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
            },
            child: Text(
              'Log in',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
