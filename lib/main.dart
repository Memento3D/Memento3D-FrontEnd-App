import 'package:flutter/material.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.instance.initialize();
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
      home: AuthState.instance.isAuthenticated
          ? const MainScreen()
          : const LoginScreen(),
    );
  }
}
