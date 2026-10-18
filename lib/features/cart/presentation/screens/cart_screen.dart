import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../payment/data/fake_payment_repository.dart';
import '../../../payment/presentation/controllers/payment_controller.dart';
import '../../../payment/presentation/payment_format.dart';
import '../../../payment/domain/payment.dart';
import '../../../payment/presentation/screens/payment_screen.dart';
import '../controllers/cart_controller.dart';

/// The caller owns the cart controller. No demo items are inserted here.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.controller});
  final CartController controller;

  Future<void> _checkout(BuildContext context) async {
    if (controller.cart.isEmpty) return;
    final payment = PaymentController(
      repository: FakePaymentRepository(),
      summary: controller.cart.toCheckoutSummary(),
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PaymentScreen(controller: payment)),
      );
    } finally {
      payment.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String money(int value) => formatPaymentMoney(Money(value), l.localeName);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final cart = controller.cart;
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8FF),
          appBar: AppBar(title: Text(l.cartTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cart.isEmpty) ...[
                        const Icon(Icons.shopping_cart_outlined, size: 64),
                        Text(l.cartEmptyTitle, textAlign: TextAlign.center),
                        Text(l.cartEmptyBody, textAlign: TextAlign.center),
                      ],
                      for (final item in cart.items)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (item.description != null)
                                  Text(item.description!),
                                Text(l.cartUnitPrice(money(item.unitPriceVnd))),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      key: ValueKey('decrease-${item.id}'),
                                      tooltip: l.cartDecrease(item.name),
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          controller.decreaseQuantity(item.id),
                                    ),
                                    Text(l.cartQuantity(item.quantity)),
                                    IconButton(
                                      key: ValueKey('increase-${item.id}'),
                                      tooltip: l.cartIncrease(item.name),
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          controller.increaseQuantity(item.id),
                                    ),
                                    IconButton(
                                      key: ValueKey('remove-${item.id}'),
                                      tooltip: l.cartRemove(item.name),
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          controller.removeItem(item.id),
                                    ),
                                  ],
                                ),
                                Text(money(item.totalVnd)),
                              ],
                            ),
                          ),
                        ),
                      Text(l.cartSubtotal(money(cart.subtotalVnd))),
                      const SizedBox(height: 12),
                      Text(
                        l.cartTotal(money(cart.totalVnd)),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const ValueKey('cart-checkout'),
                        onPressed: cart.isEmpty
                            ? null
                            : () => _checkout(context),
                        child: Text(l.cartCheckout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
