import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/main_screen.dart';
import 'package:memento3d_frontend_app/core/utils/app_messenger.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

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
      title: 'Memento3D',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppMessenger.navigatorKey,
      scaffoldMessengerKey: AppMessenger.messengerKey,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AuthState.instance.isAuthenticated
          ? const MainScreen()
          : const LoginScreen(),
    );
  }
}
