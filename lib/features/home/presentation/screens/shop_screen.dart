import 'package:flutter/material.dart';

import '../../../orders/presentation/screens/cart_screen.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.client});
  final ApiClient? client;
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _busy = true;
  String? _error;
  int _page = 0;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = more ? _page + 1 : 0;
      final keyword = Uri.encodeQueryComponent(_search.text.trim());
      final response = await _client.get(
        '/api/v1/products?page=$page&size=20&keyword=$keyword',
      );
      if (response is! Map ||
          response['content'] is! List ||
          response['last'] is! bool) {
        throw const FormatException('Invalid catalog');
      }
      final items = (response['content'] as List).map((item) {
        if (item is! Map || item['id'] is! String) {
          throw const FormatException('Invalid product');
        }
        return Map<String, dynamic>.from(item);
      }).toList();
      if (mounted) {
        setState(() {
          _products = more ? [..._products, ...items] : items;
          _page = page;
          _last = response['last'] as bool;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải sản phẩm.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(Map<String, dynamic> product) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _client.post(
        '/api/v1/cart/items',
        body: {'productId': product['id'], 'quantity': 1},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng.')));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể thêm sản phẩm.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sản phẩm'),
      actions: [
        IconButton(
          tooltip: 'Giỏ hàng',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CartScreen(client: _client),
            ),
          ),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              labelText: 'Tìm sản phẩm',
              suffixIcon: IconButton(
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          ListTile(
            title: Text(_error!),
            trailing: TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Thử lại'),
            ),
          ),
        Expanded(
          child: _products.isEmpty && !_busy && _error == null
              ? const Center(child: Text('Không có sản phẩm.'))
              : ListView.builder(
                  itemCount: _products.length + (_last ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == _products.length) {
                      return TextButton(
                        onPressed: _busy ? null : () => _load(more: true),
                        child: const Text('Xem thêm'),
                      );
                    }
                    final product = _products[index];
                    return Card(
                      child: ListTile(
                        title: Text(product['name']?.toString() ?? ''),
                        subtitle: Text(
                          '${product['shortDescription'] ?? ''}\n${product['price'] ?? ''} VND',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Thêm vào giỏ',
                          onPressed:
                              _busy ||
                                  product['active'] != true ||
                                  product['availability'] == 'OUT_OF_STOCK'
                              ? null
                              : () => _add(product),
                          icon: const Icon(Icons.add_shopping_cart),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
