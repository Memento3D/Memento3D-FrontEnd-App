import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/login_screen.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/screens/verification_entry_screen.dart';
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

  Widget? _linkedScreen(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return null;
    if (uri.path == '/reset-password') {
      return ResetPasswordScreen(resetToken: uri.queryParameters['token']);
    }
    if (uri.path == '/verify-email/confirm') {
      return VerificationEntryScreen(token: uri.queryParameters['token']);
    }
    return null;
  }

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
      onGenerateInitialRoutes: (initialRoute) {
        final linked = _linkedScreen(initialRoute);
        if (linked != null) {
          return [MaterialPageRoute<void>(builder: (_) => linked)];
        }
        return [
          MaterialPageRoute<void>(
            builder: (_) => AuthState.instance.isAuthenticated
                ? const MainScreen()
                : const LoginScreen(),
          ),
        ];
      },
      onGenerateRoute: (settings) {
        final linked = _linkedScreen(settings.name ?? '');
        return linked == null
            ? null
            : MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => linked,
              );
      },
    );
  }
}
