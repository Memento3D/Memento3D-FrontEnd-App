import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/model_confirmation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = CaptureSession()
    ..addPhoto(XFile('assets/images/besties_keepsake.jpg'))
    ..addPhoto(XFile('assets/images/polaroid_3d_hero.jpg'))
    ..addPhoto(XFile('assets/images/besties_keepsake.jpg'));
  runApp(
    MaterialApp(
      title: 'Confirm Scan Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: ModelConfirmationScreen(session: session),
    ),
  );
}
