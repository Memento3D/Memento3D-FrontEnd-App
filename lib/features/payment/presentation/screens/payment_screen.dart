import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/payment.dart';
import '../controllers/payment_controller.dart';
import '../payment_format.dart';

/// The caller owns and disposes [controller]. No production route is assumed.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.controller,
    this.onViewOrder,
    this.onGoHome,
  });
  final PaymentController controller;
  final VoidCallback? onViewOrder;
  final VoidCallback? onGoHome;

  static const _lavender = Color(0xFFFDF8FF);
  static const _tint = Color(0xFFEBE4FF);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: _lavender,
        appBar: AppBar(
          backgroundColor: _lavender,
          centerTitle: true,
          title: Text(l.paymentTitle),
          leading: IconButton(
            tooltip: l.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              controller.cancel();
              Navigator.of(context).maybePop();
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.status == PaymentStatus.initial)
                      ..._method(context, l)
                    else
                      ..._result(context, l),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _money(AppLocalizations l, Money money) =>
      formatPaymentMoney(money, l.localeName);

  Widget _title(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
  );

  Widget _card(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: const [
        BoxShadow(
          color: Color(0x105B3CDD),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _row(String label, String value, {bool prominent = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: prominent ? 22 : 14,
            color: prominent ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _button(
    String label,
    VoidCallback action, {
    bool secondary = false,
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: FilledButton(
      key: key,
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? _tint : AppColors.primary,
        foregroundColor: secondary ? AppColors.primary : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: const StadiumBorder(),
      ),
      onPressed: action,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _sandbox(AppLocalizations l) => Align(
    alignment: Alignment.centerRight,
    child: Chip(
      avatar: const Icon(Icons.science_outlined, size: 15),
      label: Text(l.paymentSandbox),
      backgroundColor: const Color(0xFFFFDAD2),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    ),
  );

  List<Widget> _method(BuildContext context, AppLocalizations l) => [
    Text(
      l.paymentHeading,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 4),
    Text(
      l.paymentSubtitle,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
    _card([
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _tint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.view_in_ar,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.paymentProduct,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.paymentProductType,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _row(l.paymentSubtotal, _money(l, controller.summary.subtotal)),
      _row(l.paymentFee, _money(l, controller.summary.serviceFee)),
      const Divider(color: _tint, height: 28),
      _row(
        l.paymentTotal,
        _money(l, controller.summary.total),
        prominent: true,
      ),
    ]),
    Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            l.paymentMethods,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        _sandbox(l),
      ],
    ),
    for (final provider in PaymentProvider.values) _provider(provider, l),
    const SizedBox(height: 20),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 15, color: Color(0xFF006A3B)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l.paymentSecurity,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 6),
    _button(
      l.paymentPay(
        providerName(controller.provider),
        _money(l, controller.summary.total),
      ),
      () => controller.start(),
      key: const ValueKey('payment-pay'),
    ),
  ];

  Widget _badge(PaymentProvider provider) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: switch (provider) {
        PaymentProvider.momo => const Color(0xFFA50064),
        PaymentProvider.zalopay => const Color(0xFF0068FF),
        PaymentProvider.vnpay => const Color(0xFF9D422C),
      },
    ),
    alignment: Alignment.center,
    child: provider == PaymentProvider.momo
        ? const Text(
            'MoMo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )
        : Icon(
            provider == PaymentProvider.zalopay
                ? Icons.wallet
                : Icons.qr_code_scanner,
            color: Colors.white,
          ),
  );

  Widget _provider(PaymentProvider provider, AppLocalizations l) {
    final selected = controller.provider == provider;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? _tint : Colors.white,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            key: ValueKey('provider-${provider.name}'),
            borderRadius: BorderRadius.circular(32),
            onTap: () => controller.selectProvider(provider),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _badge(provider),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName(provider),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          switch (provider) {
                            PaymentProvider.momo => l.paymentMomoDescription,
                            PaymentProvider.zalopay =>
                              l.paymentZalopayDescription,
                            PaymentProvider.vnpay => l.paymentVnpayDescription,
                          },
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _result(BuildContext context, AppLocalizations l) {
    final status = controller.status;
    final processing = status == PaymentStatus.processing;
    final success = status == PaymentStatus.success;
    final failed = status == PaymentStatus.failed;
    final name = providerName(controller.provider);
    final amount = _money(l, controller.summary.total);
    final color = success
        ? const Color(0xFF006A3B)
        : failed
        ? const Color(0xFFBA1A1A)
        : AppColors.textSecondary;
    return [
      _sandbox(l),
      const SizedBox(height: 20),
      Center(
        child: processing
            ? SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: AppColors.primary,
                        backgroundColor: _tint,
                      ),
                    ),
                    _badge(controller.provider),
                  ],
                ),
              )
            : Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? const Color(0xFF88F9B0)
                      : failed
                      ? const Color(0xFFFFDAD6)
                      : _tint,
                ),
                child: Icon(
                  success
                      ? Icons.check_circle
                      : failed
                      ? Icons.error_outline
                      : Icons.cancel_outlined,
                  size: 54,
                  color: color,
                ),
              ),
      ),
      const SizedBox(height: 24),
      Semantics(
        liveRegion: true,
        child: _title(
          processing
              ? l.paymentConnecting(name)
              : success
              ? l.paymentSuccessTitle
              : failed
              ? l.paymentFailedTitle
              : l.paymentCancelledTitle,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        processing
            ? l.paymentProcessingBody
            : success
            ? l.paymentSuccessBody
            : failed
            ? l.paymentFailedBody
            : l.paymentCancelledBody,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      _card([
        if (success) _row(l.paymentReference, controller.summary.reference),
        if (processing) _row(l.paymentAmount, amount, prominent: true),
        _row(
          status == PaymentStatus.cancelled
              ? l.paymentSelectedMethod
              : l.paymentMethod,
          name,
        ),
        if (!processing)
          _row(
            success ? l.paymentTotal : l.paymentAmount,
            amount,
            prominent: success,
          ),
        if (success || status == PaymentStatus.cancelled)
          _row(success ? l.paymentTime : l.paymentCancelTime, l.paymentJustNow),
        if (status != PaymentStatus.cancelled)
          _row(
            l.paymentStatus,
            processing
                ? l.paymentProcessing
                : success
                ? l.paymentSuccess
                : l.paymentFailed,
          ),
        if (failed) ...[
          const Divider(color: _tint),
          Text(l.paymentFailureNote),
        ],
      ]),
      if (processing)
        _button(l.paymentCancel, controller.cancel, secondary: true),
      if (success) ...[
        _button(
          l.paymentViewOrder,
          onViewOrder ??
              () {
                Navigator.of(context).maybePop();
              },
        ),
        _button(l.paymentBack, controller.reset, secondary: true),
      ],
      if (failed) ...[
        _button(l.paymentRetry, () => controller.start()),
        _button(l.paymentChooseOther, controller.reset, secondary: true),
      ],
      if (status == PaymentStatus.cancelled) ...[
        _button(l.paymentContinue, controller.reset),
        _button(
          l.paymentHome,
          onGoHome ??
              () {
                Navigator.of(context).maybePop();
              },
          secondary: true,
        ),
      ],
    ];
  }
}
