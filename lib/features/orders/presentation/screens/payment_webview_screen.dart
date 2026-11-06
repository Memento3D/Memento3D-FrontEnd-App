import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';

/// Hosts the e-wallet checkout page. Payment confirmation itself arrives on the
/// backend through the gateway callback, so this screen only shows the page and
/// lets the customer come back to the order.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url, this.returnUri});

  final String url;
  final Uri? returnUri;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            final actual = Uri.tryParse(url), expected = widget.returnUri;
            if (mounted &&
                actual != null &&
                expected != null &&
                actual.scheme == expected.scheme &&
                actual.host == expected.host &&
                actual.port == expected.port &&
                actual.path == expected.path) {
              // Return page has reached BE verification. The parent re-fetches order
              // status; the URL itself is never treated as payment confirmation.
              Navigator.of(context).pop();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Thanh toán')),
    body: Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    ),
  );
}
