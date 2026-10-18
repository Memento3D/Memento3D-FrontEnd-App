import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/payment/data/fake_payment_repository.dart';
import 'features/payment/domain/payment.dart';
import 'features/payment/presentation/controllers/payment_controller.dart';
import 'features/payment/presentation/screens/payment_screen.dart';
import 'l10n/app_localizations.dart';

/// Isolated demo: flutter run -t lib/main_payment_preview.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaymentPreviewApp());
}

class PaymentPreviewApp extends StatefulWidget {
  const PaymentPreviewApp({super.key});

  @override
  State<PaymentPreviewApp> createState() => _PaymentPreviewAppState();
}

class _PaymentPreviewAppState extends State<PaymentPreviewApp> {
  late final PaymentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaymentController(
      repository: FakePaymentRepository(),
      summary: CheckoutSummary.demo,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Memento3D',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: PaymentScreen(controller: _controller),
  );
}
