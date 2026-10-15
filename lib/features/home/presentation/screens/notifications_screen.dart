import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.client});
  final ApiClient? client;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _busy = true;
  String? _error;
  int _page = 0;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = more ? _page + 1 : 0;
      final response = await _client.get(
        '/api/v1/notifications?page=$page&size=20',
      );
      if (response is! Map ||
          response['content'] is! List ||
          response['last'] is! bool) {
        throw const FormatException('Invalid notifications response');
      }
      final items = (response['content'] as List).map((item) {
        if (item is! Map || item['id'] is! String) {
          throw const FormatException('Invalid notification');
        }
        return Map<String, dynamic>.from(item);
      }).toList();
      if (!mounted) return;
      setState(() {
        _items = more ? [..._items, ...items] : items;
        _page = page;
        _last = response['last'] as bool;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markRead(String? id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _client.patch(
        id == null
            ? '/api/v1/notifications/read-all'
            : '/api/v1/notifications/${Uri.encodeComponent(id)}/read',
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      actions: [
        TextButton(
          onPressed: _busy || _items.isEmpty ? null : () => _markRead(null),
          child: const Text('Đọc tất cả'),
        ),
      ],
    ),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          ListTile(
            title: Text(_error!),
            trailing: TextButton(
              onPressed: _busy ? null : () => _load(),
              child: const Text('Thử lại'),
            ),
          ),
        Expanded(
          child: _items.isEmpty && !_busy && _error == null
              ? const Center(child: Text('Chưa có thông báo'))
              : ListView.builder(
                  itemCount: _items.length + (_last ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return TextButton(
                        onPressed: _busy ? null : () => _load(more: true),
                        child: const Text('Xem thêm'),
                      );
                    }
                    final item = _items[index];
                    final read = item['read'] == true || item['isRead'] == true;
                    return ListTile(
                      leading: Icon(
                        read
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(item['title']?.toString() ?? ''),
                      subtitle: Text(item['message']?.toString() ?? ''),
                      onTap: read || _busy
                          ? null
                          : () => _markRead(item['id'] as String),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
