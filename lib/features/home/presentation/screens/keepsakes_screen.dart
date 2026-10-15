import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../orders/presentation/screens/print_order_config_screen.dart';
import '../../../scans/data/models/scan_item.dart';
import '../../../scans/data/repositories/scan_repository.dart';
import '../../../scans/presentation/screens/model_viewer_screen.dart';

/// "Kỷ vật yêu thích": the user's finished 3D keepsakes, ready to view or print.
class KeepsakesScreen extends StatefulWidget {
  const KeepsakesScreen({super.key, this.onProfile});

  final VoidCallback? onProfile;

  @override
  State<KeepsakesScreen> createState() => _KeepsakesScreenState();
}

enum _KeepsakeFilter { all, ready, processing }

class _KeepsakesScreenState extends State<KeepsakesScreen> {
  List<ScanItem> _scans = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  _KeepsakeFilter _filter = _KeepsakeFilter.all;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scans = await ScanRepository.instance.fetchScans();
      if (!mounted) return;
      setState(
        () => _scans = scans
            .where((scan) => scan.isDone || scan.isProcessing)
            .toList(),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải bộ sưu tập kỷ vật.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ScanItem> get _visible {
    final query = _query.trim().toLowerCase();
    final list = _scans.where((scan) {
      final matchesFilter = switch (_filter) {
        _KeepsakeFilter.all => true,
        _KeepsakeFilter.ready => scan.isDone,
        _KeepsakeFilter.processing => scan.isProcessing,
      };
      return matchesFilter &&
          (query.isEmpty || scan.name.toLowerCase().contains(query));
    }).toList();
    list.sort(
      (a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return list;
  }

  int _count(_KeepsakeFilter filter) => switch (filter) {
    _KeepsakeFilter.all => _scans.length,
    _KeepsakeFilter.ready => _scans.where((s) => s.isDone).length,
    _KeepsakeFilter.processing => _scans.where((s) => s.isProcessing).length,
  };

  void _openViewer(ScanItem scan) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ModelViewerScreen(scanId: scan.id, scan: scan),
    ),
  );

  void _orderPrint(ScanItem scan) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PrintOrderConfigScreen(scanId: scan.id, scanName: scan.name),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Column(
      children: [
        M3BrandHeader(actions: [M3Avatar(onTap: widget.onProfile)]),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _header()),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: M3Card(
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const M3IconTile(
                            Icons.favorite_border_rounded,
                            size: 64,
                            radius: 32,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Chưa có kỷ vật 3D nào',
                            style: m3Text(16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mô hình 3D hoàn tất sẽ được lưu vào bộ sưu tập này.',
                            textAlign: TextAlign.center,
                            style: m3Text(13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 296,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _KeepsakeCard(
                          scan: items[index],
                          onView: () => _openViewer(items[index]),
                          onOrder: () => _orderPrint(items[index]),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    const labels = {
      _KeepsakeFilter.all: 'Tất cả',
      _KeepsakeFilter.ready: 'Sẵn sàng in 3D',
      _KeepsakeFilter.processing: 'Đang xử lý',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BỘ SƯU TẬP LƯU GIỮ',
                    style: m3Text(
                      10.5,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kỷ vật yêu thích',
                    style: m3Text(19, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            M3Pill(
              '${_count(_KeepsakeFilter.all)} mô hình',
              icon: Icons.favorite_rounded,
              background: AppColors.tint,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: m3Text(13.5),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm kỷ vật yêu thích...',
                  hintStyle: m3Text(13.5, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _squareButton(
              Icons.sort_rounded,
              () => setState(() => _newestFirst = !_newestFirst),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _KeepsakeFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: M3FilterChip(
                    label: labels[filter]!,
                    count: _count(filter),
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Danh sách yêu thích',
                style: m3Text(15, weight: FontWeight.w700),
              ),
            ),
            Text(
              _newestFirst ? 'Mới nhất trước' : 'Cũ nhất trước',
              style: m3Text(11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
    ),
  );
}

class _KeepsakeCard extends StatelessWidget {
  const _KeepsakeCard({
    required this.scan,
    required this.onView,
    required this.onOrder,
  });

  final ScanItem scan;
  final VoidCallback onView;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final ready = scan.isDone;
    final day = scan.createdAt.day.toString().padLeft(2, '0');
    final month = scan.createdAt.month.toString().padLeft(2, '0');
    return M3Card(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: scan.thumbnailAsset != null
                      ? Image.asset(
                          scan.thumbnailAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: M3Pill(
                  ready ? 'Sẵn sàng in 3D' : scan.status.displayName,
                  dot: ready,
                  color: ready ? AppColors.badgeGreenText : AppColors.primary,
                  background: Colors.white.withValues(alpha: 0.92),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: m3Text(13.5, weight: FontWeight.w700),
                  ),
                  Text(
                    scan.description?.isNotEmpty == true
                        ? scan.description!
                        : 'Kỷ vật 3D',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: m3Text(11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _tag('${scan.fileCount} ảnh'),
                      _tag(scan.formattedSize),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lưu: $day/$month/${scan.createdAt.year}',
                    style: m3Text(10.5, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: ready ? onView : null,
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.tint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.view_in_ar_outlined,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Xem 3D',
                                  style: m3Text(
                                    12,
                                    weight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: ready ? onOrder : null,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: ready
                                ? AppColors.primary
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.tint,
    child: const Icon(
      Icons.view_in_ar_rounded,
      size: 44,
      color: AppColors.primaryLight,
    ),
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: m3Text(10, weight: FontWeight.w600, color: AppColors.primary),
    ),
  );
}
