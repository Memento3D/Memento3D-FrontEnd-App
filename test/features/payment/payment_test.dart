import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/payment/domain/payment.dart';
import 'package:memento3d_frontend_app/features/payment/domain/payment_repository.dart';
import 'package:memento3d_frontend_app/features/payment/data/fake_payment_repository.dart';
import 'package:memento3d_frontend_app/features/payment/presentation/controllers/payment_controller.dart';
import 'package:memento3d_frontend_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:memento3d_frontend_app/features/payment/presentation/payment_format.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

class PendingRepository implements PaymentRepository {
  final completer = Completer<PaymentStatus>();
  int calls = 0;
  @override
  Future<PaymentStatus> pay(CheckoutSummary summary, PaymentProvider provider) {
    calls++;
    return completer.future;
  }
}

Widget app(
  PaymentController controller, {
  String locale = 'vi',
  VoidCallback? viewOrder,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: PaymentScreen(controller: controller, onViewOrder: viewOrder),
);

Future<void> tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  test('integer money, fees and locale formatting', () {
    expect(CheckoutSummary.demo.total.vnd, 249000);
    expect(CheckoutSummary.demo.serviceFee.vnd, 0);
    expect(formatPaymentMoney(const Money(249000), 'vi'), '249.000 ₫');
    expect(formatPaymentMoney(const Money(249000), 'en'), '249,000 ₫');
  });

  test(
    'guards duplicate submission and ignores cancelled late completion',
    () async {
      final repository = PendingRepository();
      final controller = PaymentController(repository: repository);
      final first = controller.start();
      await controller.start();
      controller.selectProvider(PaymentProvider.vnpay);
      expect(repository.calls, 1);
      expect(controller.provider, PaymentProvider.momo);
      controller.cancel();
      controller.reset();
      repository.completer.complete(PaymentStatus.success);
      await first;
      expect(controller.status, PaymentStatus.initial);
      controller.dispose();
    },
  );

  test('dispose ignores outstanding completion', () async {
    final repository = PendingRepository();
    final controller = PaymentController(repository: repository);
    final pending = controller.start();
    controller.dispose();
    repository.completer.complete(PaymentStatus.success);
    await pending;
  });

  testWidgets('method layout, mutually exclusive selection and dynamic CTA', (
    tester,
  ) async {
    final controller = PaymentController(
      repository: FakePaymentRepository(delay: Duration.zero),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));
    expect(find.text('Hoàn tất đơn hàng'), findsOneWidget);
    expect(find.text('Mô hình 3D cá nhân hóa'), findsOneWidget);
    expect(find.text('Sandbox'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(controller.provider, PaymentProvider.momo);
    for (final provider in PaymentProvider.values) {
      await tester.ensureVisible(
        find.byKey(ValueKey('provider-${provider.name}')),
      );
      await tester.tap(find.byKey(ValueKey('provider-${provider.name}')));
      await tester.pump();
      expect(controller.provider, provider);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_off), findsNWidgets(2));
      expect(
        find.text('Thanh toán qua ${providerName(provider)} • 249.000 ₫'),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('double CTA starts once; processing has no simulation controls', (
    tester,
  ) async {
    final repository = PendingRepository();
    final controller = PaymentController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(controller));
    final cta = find.byKey(const ValueKey('payment-pay'));
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.tap(cta);
    await tester.pump();
    expect(repository.calls, 1);
    expect(find.text('Đang kết nối với MoMo'), findsOneWidget);
    expect(find.text('249.000 ₫'), findsOneWidget);
    expect(find.text('Thành công'), findsNothing);
    expect(find.text('Thất bại'), findsNothing);
    expect(find.textContaining('Giả lập kết quả'), findsNothing);
    await tap(tester, 'Hủy giao dịch');
    expect(find.text('Đã hủy thanh toán'), findsOneWidget);
    repository.completer.complete(PaymentStatus.success);
    await tester.pump();
    expect(find.text('Đã hủy thanh toán'), findsOneWidget);
    await tap(tester, 'Tiếp tục thanh toán');
    expect(find.text('Hoàn tất đơn hàng'), findsOneWidget);
  });

  for (final outcome in [
    PaymentStatus.success,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
  ]) {
    testWidgets('fake $outcome preserves provider and supports reset/retry', (
      tester,
    ) async {
      final controller = PaymentController(
        repository: FakePaymentRepository(
          outcome: outcome,
          delay: Duration.zero,
        ),
      );
      addTearDown(controller.dispose);
      var viewed = false;
      await tester.pumpWidget(app(controller, viewOrder: () => viewed = true));
      controller.selectProvider(PaymentProvider.zalopay);
      await controller.start();
      await tester.pump();
      expect(controller.status, outcome);
      expect(find.text('ZaloPay'), findsOneWidget);
      expect(find.text('249.000 ₫'), findsOneWidget);
      switch (outcome) {
        case PaymentStatus.success:
          expect(find.text('M3D-2026-00125'), findsOneWidget);
          await tap(tester, 'Xem đơn hàng');
          expect(viewed, isTrue);
          await tap(tester, 'Về trang thanh toán');
        case PaymentStatus.failed:
          expect(find.text('Thanh toán chưa thành công'), findsOneWidget);
          await tap(tester, 'Thử lại');
          expect(controller.status, PaymentStatus.failed);
          await tap(tester, 'Chọn phương thức khác');
        case PaymentStatus.cancelled:
          expect(find.text('Đã hủy thanh toán'), findsOneWidget);
          await tap(tester, 'Tiếp tục thanh toán');
        default:
          fail('Unexpected outcome');
      }
      expect(controller.status, PaymentStatus.initial);
      expect(controller.provider, PaymentProvider.zalopay);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English localization and narrow scaled layouts scroll safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PaymentController(
      repository: FakePaymentRepository(delay: Duration.zero),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.8)),
          child: child!,
        ),
        home: PaymentScreen(controller: controller),
      ),
    );
    expect(find.text('Complete your order'), findsOneWidget);
    await tap(tester, 'Pay with MoMo • 249,000 ₫');
    await tester.pump();
    expect(find.text('Payment successful!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
