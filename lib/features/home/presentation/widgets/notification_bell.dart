import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../screens/notifications_screen.dart';

/// Bell button whose dot reflects the backend unread count.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.client});

  final ApiClient? client;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final ApiClient _client = widget.client ?? ApiClient();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final response = await _client.get('/api/v1/notifications/unread-count');
      final count = response is Map ? response['unreadCount'] : null;
      if (mounted && count is num) setState(() => _unread = count.toInt());
    } catch (_) {
      // The dot is decoration only; a failed count must not break the header.
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(client: widget.client),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: _unread > 0 ? 'Thông báo ($_unread chưa đọc)' : 'Thông báo',
    child: M3CircleIconButton(
      icon: Icons.notifications_none_rounded,
      badge: _unread > 0,
      onTap: _open,
    ),
  );
}
