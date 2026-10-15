import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../features/auth/data/services/auth_storage.dart';
import '../features/model_viewer/data/services/model_rating_service.dart';

class RateShareScreen extends StatefulWidget {
  const RateShareScreen({super.key, required this.scanId, this.scanName});
  final String scanId;
  final String? scanName;

  @override
  State<RateShareScreen> createState() => _RateShareScreenState();
}

class _RateShareScreenState extends State<RateShareScreen> {
  final _service = ModelRatingService();
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = true;
  bool _hasRating = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final user = await AuthStorage.getUser();
      final ratings = await _service.getRatings(widget.scanId);
      if (!mounted) return;
      final mine = ratings.where((r) => user != null && r['userId'] == user.id);
      if (mine.isNotEmpty) {
        final rating = mine.first['rating'];
        if (rating is! int || rating < 1 || rating > 5) {
          throw const FormatException('Invalid rating');
        }
        _rating = rating;
        _comment.text = mine.first['comment']?.toString() ?? '';
        _hasRating = true;
      }
    } catch (error) {
      if (mounted) {
        _feedback = error is ApiException ? error.message : error.toString();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit({bool delete = false}) async {
    if (_busy || (!delete && _rating == 0)) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      if (delete) {
        await _service.delete(widget.scanId);
      } else {
        await _service.save(widget.scanId, _rating, _comment.text);
      }
      if (!mounted) return;
      setState(() {
        _hasRating = !delete;
        _feedback = delete ? 'Đã xóa đánh giá.' : 'Đã lưu đánh giá.';
        if (delete) {
          _rating = 0;
          _comment.clear();
        }
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _feedback = error is ApiException
              ? error.message
              : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đánh giá mô hình')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          widget.scanName ?? widget.scanId,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        if (_busy) const LinearProgressIndicator(),
        Wrap(
          children: List.generate(
            5,
            (index) => IconButton(
              tooltip: '${index + 1} sao',
              onPressed: _busy
                  ? null
                  : () => setState(() => _rating = index + 1),
              icon: Icon(index < _rating ? Icons.star : Icons.star_border),
              color: Colors.amber.shade800,
            ),
          ),
        ),
        TextField(
          controller: _comment,
          enabled: !_busy,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Nhận xét',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || _rating == 0 ? null : () => _submit(),
          child: const Text('Lưu đánh giá'),
        ),
        if (_hasRating)
          TextButton(
            onPressed: _busy ? null : () => _submit(delete: true),
            child: const Text('Xóa đánh giá của tôi'),
          ),
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Text(_feedback!, semanticsLabel: _feedback),
          TextButton(
            onPressed: _busy ? null : _load,
            child: const Text('Tải lại'),
          ),
        ],
      ],
    ),
  );
}
