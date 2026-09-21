import 'package:flutter/material.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const Memento3DApp());
}

class Memento3DApp extends StatelessWidget {
  const Memento3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'memento3d',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
