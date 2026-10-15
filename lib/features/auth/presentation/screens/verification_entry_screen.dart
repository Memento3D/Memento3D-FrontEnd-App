import 'package:flutter/material.dart';

import '../../data/services/email_verification_service.dart';
import '../controllers/email_verification_state.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class VerificationEntryScreen extends StatefulWidget {
  const VerificationEntryScreen({super.key, this.email, this.token});

  final String? email;
  final String? token;

  @override
  State<VerificationEntryScreen> createState() =>
      _VerificationEntryScreenState();
}

class _VerificationEntryScreenState extends State<VerificationEntryScreen> {
  late final EmailVerificationState _state = EmailVerificationState(
    service: ApiEmailVerificationService(),
    email: widget.email,
  );

  @override
  void initState() {
    super.initState();
    final token = widget.token;
    if (token != null && token.isNotEmpty) _state.verifyToken(token);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EmailVerificationScreen(
    state: _state,
    onContinue: () => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    ),
  );
}
