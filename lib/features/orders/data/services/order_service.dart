import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

/// One page of orders returned by `GET /api/v1/orders/me`.
class OrderPage {
  const OrderPage({
    required this.orders,
    required this.page,
    required this.total,
  });

  final List<Map<String, dynamic>> orders;
  final int page;
  final int total;
}

/// Checkout and order history endpoints used by the ordering flow.
class OrderService {
  OrderService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const _orders = '/api/v1/orders';
  static const _cart = '/api/v1/cart';
  static const _addresses = '/api/v1/users/me/addresses';

  /// Catalog packages a bespoke scan print can be ordered as.
  Future<List<Map<String, dynamic>>> loadProducts({int size = 20}) async {
    final response = await _client.get('/api/v1/products?page=0&size=$size');
    if (response is! Map || response['content'] is! List) {
      throw const FormatException('Invalid catalog');
    }
    return (response['content'] as List).map((item) {
      if (item is! Map || item['id'] is! String) {
        throw const FormatException('Invalid product');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  /// Personalization options (SIZE, MATERIAL, BASE, ENGRAVING, …) for a product.
  Future<List<Map<String, dynamic>>> loadCustomizationOptions(
    String productId,
  ) async {
    final response = await _client.get(
      '/api/v1/customization-options?productId=${Uri.encodeComponent(productId)}',
    );
    if (response is! List) {
      throw const FormatException('Invalid customization options');
    }
    return response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Server-authoritative price for a configuration. A bespoke scan order is
  /// rejected without this quote, so the client never prices the print itself.
  Future<Map<String, dynamic>> requestQuote({
    required String productId,
    int? sizeCm,
    Map<String, Object?> customization = const {},
    String? shippingAddress,
  }) async {
    final response = await _client.post(
      '/api/v1/pricing/quotes',
      body: {
        'productId': productId,
        'sizeCm': ?sizeCm,
        'customization': customization,
        'shippingRequired': true,
        'shippingAddress': ?shippingAddress,
      },
    );
    if (response is! Map || response['id'] is! String) {
      throw const FormatException('Invalid quote');
    }
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> loadCart() async {
    final response = await _client.get(_cart);
    if (response is! Map || response['items'] is! List) {
      throw const FormatException('Invalid cart');
    }
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> loadAddresses() async {
    final response = await _client.get(_addresses);
    if (response is! List) {
      throw const FormatException('Invalid address list');
    }
    return response.map((item) {
      if (item is! Map || item['id'] is! String) {
        throw const FormatException('Invalid address');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  /// Sends the checkout once. A timeout leaves the server outcome unknown, so
  /// callers must not replay it blindly; the idempotency key lets the server
  /// collapse a deliberate retry of the same checkout.
  Future<Map<String, dynamic>> createOrder({
    required String recipientName,
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    required String idempotencyKey,
    String? note,
    String? scanId,
    String? quoteId,
    num? totalPrice,
  }) async {
    final response = await _client.post(
      _orders,
      body: {
        'recipientName': recipientName,
        'shippingAddress': shippingAddress,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'paymentType': paymentMethod == 'CASH' ? 'COD' : 'FULL_PAYMENT',
        'fulfillmentType': 'PHYSICAL',
        'currency': 'VND',
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
        'scanId': ?scanId,
        'quoteId': ?quoteId,
        'totalPrice': ?totalPrice,
      },
    );
    return _order(response);
  }

  Future<OrderPage> myOrders({
    String? status,
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
      if (query != null && query.isNotEmpty) 'query': query,
    };
    final response = await _client.get(
      '$_orders/me?${Uri(queryParameters: params).query}',
    );
    if (response is! Map || response['orders'] is! List) {
      throw const FormatException('Invalid order list');
    }
    return OrderPage(
      orders: (response['orders'] as List).map((item) {
        if (item is! Map) throw const FormatException('Invalid order');
        return Map<String, dynamic>.from(item);
      }).toList(),
      page: (response['page'] as num?)?.toInt() ?? page,
      total: (response['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, int>> statusCounts() async {
    final response = await _client.get('$_orders/me/counts');
    if (response is! Map) throw const FormatException('Invalid counts');
    return {
      for (final entry in response.entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };
  }

  Future<Map<String, dynamic>> orderDetail(String orderId) async {
    final response = await _client.get(
      '$_orders/${Uri.encodeComponent(orderId)}',
    );
    return _order(response);
  }

  Future<Map<String, dynamic>> acceptWorkshopQuote(String orderId) async =>
      _order(
        await _client.post(
          '$_orders/${Uri.encodeComponent(orderId)}/accept-quote',
        ),
      );

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final response = await _client.post(
      '$_orders/${Uri.encodeComponent(orderId)}/cancel',
    );
    return _order(response);
  }

  /// Starts an e-wallet payment attempt for an order already created.
  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required String paymentMethod,
  }) async {
    if (paymentMethod == 'VNPAY') {
      final response = await _client.post(
        '/api/v1/payments/vnpay/create',
        body: {
          'orderId': orderId,
          'returnUrl': Uri.parse(ApiConfig.baseUrl)
              .resolve('/api/v1/payments/vnpay/return')
              .toString(),
        },
      );
      if (response is! Map) throw const FormatException('Invalid payment');
      return Map<String, dynamic>.from(response);
    }
    final response = await _client.post(
      '$_orders/${Uri.encodeComponent(orderId)}/payments',
      body: {'paymentMethod': paymentMethod},
    );
    if (response is! Map) throw const FormatException('Invalid payment');
    return Map<String, dynamic>.from(response);
  }

  Map<String, dynamic> _order(dynamic response) {
    if (response is! Map || response['id'] is! String) {
      throw const FormatException('Invalid order');
    }
    return Map<String, dynamic>.from(response);
  }
}
