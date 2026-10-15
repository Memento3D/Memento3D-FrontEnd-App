import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../scans/data/models/scan_item.dart';
import '../../../scans/data/repositories/scan_repository.dart';

/// Wide-screen workspace. Scan data and creation remain owned by the existing flow.
class DesktopWorkspace extends StatefulWidget {
  const DesktopWorkspace({
    super.key,
    required this.onCreate,
    required this.onDashboard,
    required this.onProfile,
    required this.onShop,
    required this.onNotifications,
    this.loadScans,
  });
  final Future<void> Function() onCreate;
  final VoidCallback onDashboard;
  final VoidCallback onProfile;
  final VoidCallback onShop;
  final VoidCallback onNotifications;
  final Future<List<ScanItem>> Function()? loadScans;

  @override
  State<DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<DesktopWorkspace> {
  final _search = TextEditingController();
  List<ScanItem> _scans = [];
  ScanItem? _selected;
  bool _loading = true;
  String? _error;

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scans =
          await (widget.loadScans?.call() ??
              ScanRepository.instance.fetchScans());
      if (mounted) {
        setState(() {
          _scans = scans;
          _selected = scans.where((s) => s.id == _selected?.id).firstOrNull;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải danh sách scan.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    await widget.onCreate();
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _scans
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FA),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rail(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 290, child: _setup()),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: _preview()),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _library(visible)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail() => Container(
    width: 76,
    color: Colors.white,
    child: Column(
      children: [
        const SizedBox(height: 22),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
        ),
        const SizedBox(height: 30),
        _nav(Icons.view_in_ar_rounded, 'Mô hình', true, () {}),
        _nav(Icons.dashboard_outlined, 'Scan', false, widget.onDashboard),
        _nav(Icons.storefront_outlined, 'Cửa hàng', false, widget.onShop),
        const Spacer(),
        _nav(
          Icons.notifications_none_rounded,
          'Thông báo',
          false,
          widget.onNotifications,
        ),
        _nav(Icons.person_outline_rounded, 'Hồ sơ', false, widget.onProfile),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _nav(IconData icon, String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.badgePurpleBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _panel({required Widget child, Color color = Colors.white}) =>
      Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECEAF4)),
        ),
        child: child,
      );

  Widget _setup() => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.badgePurpleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo mô hình',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Từ những khoảnh khắc của bạn',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.cardBorder),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'BẮT ĐẦU TỪ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5DFFF)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.image_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hình ảnh',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Chụp hoặc chọn ảnh vật thể',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Ảnh của bạn',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _create,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 190,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4DFF5)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Tạo scan và thêm ảnh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chọn ảnh hoặc chụp nhiều góc nhìn để bắt đầu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const _Tip(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Một chút chuẩn bị',
                  body: 'Chụp đủ ánh sáng và giữ vật thể trong khung hình.',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: _create,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo scan mới'),
          ),
        ),
      ],
    ),
  );

  Widget _preview() => _panel(
    color: const Color(0xFFFAF9FE),
    child: Stack(
      children: [
        Positioned(
          top: 24,
          left: 26,
          right: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KHÔNG GIAN SÁNG TẠO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selected?.name ?? 'Chào mừng đến với Memento3D',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE9E5FF), Color(0xFFF6EAFE)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .09),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _selected == null
                        ? Icons.view_in_ar_rounded
                        : _selected!.status.icon,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _selected == null
                      ? 'Biến khoảnh khắc thành kỷ vật 3D'
                      : _selected!.status.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _selected == null
                      ? 'Tạo một scan mới hoặc chọn một bản tạo ở bên phải để bắt đầu.'
                      : '${_selected!.fileCount} ảnh · ${_selected!.formattedDate}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _selected == null ? _create : widget.onDashboard,
                  icon: Icon(
                    _selected == null ? Icons.add : Icons.open_in_new,
                    size: 18,
                  ),
                  label: Text(
                    _selected == null ? 'Bắt đầu tạo' : 'Mở danh sách scan',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _library(List<ScanItem> scans) => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bản tạo của tôi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Những kỷ vật bạn đang tạo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loading ? null : _load,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm các bản tạo của tôi',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F7FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${scans.length} bản tạo',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onDashboard,
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.cardBorder),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : scans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 42,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          queryIsEmpty
                              ? 'Chưa có bản tạo nào'
                              : 'Không tìm thấy bản tạo',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Các scan của bạn sẽ xuất hiện tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: scans.length,
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    final selected = _selected?.id == scan.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? AppColors.badgePurpleBg
                            : const Color(0xFFFAF9FD),
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          onTap: () => setState(() => _selected = scan),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.view_in_ar_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            scan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${scan.status.displayName} · ${scan.formattedDate}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );

  bool get queryIsEmpty => _search.text.trim().isEmpty;
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
