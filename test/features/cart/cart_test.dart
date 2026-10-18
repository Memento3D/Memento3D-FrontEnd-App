import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/cart/domain/cart.dart';
import 'package:memento3d_frontend_app/features/cart/domain/cart_item.dart';
import 'package:memento3d_frontend_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:memento3d_frontend_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:memento3d_frontend_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

CartItem item({int quantity = 1}) => CartItem(
  id: 'local-a',
  name: 'Keepsake',
  description: 'Digital',
  unitPriceVnd: 73000,
  quantity: quantity,
);
Widget app(CartController controller, {double textScale = 1}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: CartScreen(controller: controller),
);

void main() {
  test('multiple lines contribute integer totals without fees', () {
    final c = CartController();
    addTearDown(c.dispose);
    c.addItem(item(quantity: 2));
    c.addItem(
      CartItem(id: 'local-b', name: 'Second', unitPriceVnd: 17501, quantity: 3),
    );
    expect(c.cart.itemCount, 5);
    expect(c.cart.subtotalVnd, 198503);
    expect(c.cart.totalVnd, 198503);
    expect(c.cart.toCheckoutSummary().serviceFee.vnd, 0);
  });
  test(
    'empty, add, merge, quantities, totals, remove and clear notify correctly',
    () {
      final c = CartController();
      addTearDown(c.dispose);
      var notifications = 0;
      c.addListener(() => notifications++);
      expect(c.cart.isEmpty, isTrue);
      expect(c.cart.itemCount, 0);
      expect(c.cart.totalVnd, 0);
      expect(() => c.cart.toCheckoutSummary(), throwsStateError);
      c.addItem(item());
      final snapshot = c.cart;
      c.addItem(item(quantity: 2));
      expect(c.cart.items.length, 1);
      expect(c.cart.itemCount, 3);
      c.increaseQuantity('local-a');
      expect(c.cart.itemCount, 4);
      c.decreaseQuantity('local-a');
      expect(c.cart.subtotalVnd, 219000);
      expect(c.cart.totalVnd, 219000);
      expect(snapshot.itemCount, 1);
      expect(() => c.cart.items.clear(), throwsUnsupportedError);
      final checkout = c.cart.toCheckoutSummary();
      c.updateQuantity('local-a', 1);
      expect(checkout.total.vnd, 219000);
      expect(checkout.items.single.quantity, 3);
      expect(checkout.reference, isNull);
      c.decreaseQuantity('local-a');
      expect(c.cart.isEmpty, isTrue);
      c.addItem(item());
      c.removeItem('local-a');
      c.addItem(item());
      c.clear();
      expect(notifications, 10);
      c.clear();
      c.removeItem('missing');
      c.increaseQuantity('missing');
      expect(notifications, 10);
    },
  );

  test('invalid quantities/prices and conflicting identities are rejected', () {
    final c = CartController();
    addTearDown(c.dispose);
    expect(() => item(quantity: 0), throwsArgumentError);
    expect(() => item(quantity: -1), throwsArgumentError);
    expect(
      () => CartItem(id: '', name: 'a', unitPriceVnd: 0),
      throwsArgumentError,
    );
    expect(
      () => CartItem(id: 'a', name: 'a', unitPriceVnd: -1),
      throwsArgumentError,
    );
    c.addItem(item());
    expect(() => c.updateQuantity('local-a', 0), throwsArgumentError);
    expect(() => c.updateQuantity('local-a', -2), throwsArgumentError);
    expect(
      () => c.addItem(CartItem(id: 'local-a', name: 'Other', unitPriceVnd: 1)),
      throwsArgumentError,
    );
    expect(() => Cart([item(), item()]), throwsArgumentError);
    expect(c.cart.itemCount, 1);
  });

  testWidgets('empty state disables checkout', (tester) async {
    final c = CartController();
    addTearDown(c.dispose);
    await tester.pumpWidget(app(c));
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('cart-checkout')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('items, quantity controls, removal and narrow scaled layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = CartController();
    addTearDown(c.dispose);
    c.addItem(item());
    await tester.pumpWidget(app(c, textScale: 1.8));
    expect(find.text('Keepsake'), findsOneWidget);
    expect(find.text('Digital'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('increase-local-a')));
    await tester.pump();
    expect(find.text('Total: 146,000 ₫'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('decrease-local-a')));
    await tester.pump();
    expect(find.text('Total: 73,000 ₫'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('remove-local-a')));
    await tester.pump();
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout uses immutable cart data rather than demo amount', (
    tester,
  ) async {
    final c = CartController();
    addTearDown(c.dispose);
    c.addItem(item(quantity: 2));
    await tester.pumpWidget(app(c));
    final button = find.byKey(const ValueKey('cart-checkout'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final screen = tester.widget<PaymentScreen>(find.byType(PaymentScreen));
    expect(screen.controller.summary.total.vnd, 146000);
    expect(find.text('146,000 ₫'), findsNWidgets(2));
    expect(find.text('249,000 ₫'), findsNothing);
    expect(find.text('Keepsake'), findsOneWidget);
    c.clear();
    expect(screen.controller.summary.total.vnd, 146000);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
  });
}
