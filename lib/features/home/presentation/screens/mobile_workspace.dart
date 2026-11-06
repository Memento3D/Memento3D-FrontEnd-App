import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../widgets/notification_bell.dart';
import '../../../scans/data/models/scan_item.dart';
import '../../../scans/data/repositories/scan_repository.dart';
import '../../../scans/data/services/job_service.dart';
import '../../../scans/presentation/widgets/rename_scan_dialog.dart';
import '../../../scans/presentation/widgets/scan_details_sheet.dart';
import '../../../customization/presentation/create_model_screen.dart';

/// A compact version of the studio workspace for phones.
class MobileWorkspace extends StatefulWidget {
  const MobileWorkspace({
    super.key,
    required this.onCreate,
    required this.onNotifications,
    required this.onProfile,
    this.showAllInitially = false,
  });

  final Future<void> Function() onCreate;
  final bool showAllInitially;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  State<MobileWorkspace> createState() => _MobileWorkspaceState();
}

class _MobileWorkspaceState extends State<MobileWorkspace> {
  List<ScanItem> _scans = [];
  late bool _showAll;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _showAll = widget.showAllInitially;
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
      setState(() {
        _scans = scans;
      });
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

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error is ApiException ? error.message : error.toString()),
      ),
    );
  }

  Future<void> _rename(ScanItem scan) async {
    await RenameScanDialog.show(
      context,
      scan: scan,
      onRename: (name) async {
        try {
          await ScanRepository.instance.updateScanNameAsync(scan.id, name);
          await _load();
        } catch (error) {
          _showError(error);
          rethrow;
        }
      },
    );
  }

  Future<void> _delete(ScanItem scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa scan?'),
        content: Text('Bạn có chắc muốn xóa "${scan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ScanRepository.instance.deleteScanAsync(scan.id);
      if (mounted) await _load();
    } catch (error) {
      _showError(error);
    }
  }

  bool _retrying = false;
  Future<void> _retry(ScanItem scan) async {
    if (_retrying) return;
    _retrying = true;
    try {
      final service = JobService();
      final job = await service.getScanJob(scan.id);
      await service.retryJob(job.id);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ModelProgressScreen(scanId: scan.id)),
      );
      if (mounted) await _load();
    } catch (error) {
      _showError(error);
    } finally {
      _retrying = false;
    }
  }

  Future<void> _openScan(ScanItem scan) async {
    await ScanDetailsSheet.show(
      context,
      scan: scan,
      onRename: () => _rename(scan),
      onDelete: () => _delete(scan),
      onRetry: () => _retry(scan),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        M3BrandHeader(
          actions: [
            const NotificationBell(),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Hồ sơ',
              child: GestureDetector(
                onTap: widget.onProfile,
                child: const M3CircleIconButton(
                  icon: Icons.person_outline_rounded,
                  filled: true,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                M3Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tạo scan mới',
                              style: m3Text(17, weight: FontWeight.w700),
                            ),
                          ),
                          const M3Pill('Nhanh chóng', fontSize: 10.5),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chụp hoặc chọn ảnh để bắt đầu tạo mô hình 3D.',
                        style: m3Text(12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      M3Button(
                        label: 'Tạo scan mới',
                        leading: Icons.add_rounded,
                        height: 48,
                        onPressed: _create,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bản tạo gần đây',
                        style: m3Text(15, weight: FontWeight.w700),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showAll = !_showAll),
                      child: Text(
                        _showAll ? 'Thu gọn' : 'Xem tất cả',
                        style: m3Text(
                          12.5,
                          weight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  M3Card(
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (_scans.isEmpty)
                  M3Card(
                    child: Text(
                      'Chưa có bản tạo nào. Scan của bạn sẽ xuất hiện tại đây.',
                      style: m3Text(13, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...(_showAll ? _scans : _scans.take(6)).map(_recentTile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentTile(ScanItem scan) {
    final done = scan.status.displayName.toLowerCase().contains('hoàn');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: M3Card(
        color: AppColors.tint.withValues(alpha: 0.55),
        borderColor: AppColors.tintStrong.withValues(alpha: 0.6),
        radius: 18,
        padding: const EdgeInsets.all(12),
        onTap: () => _openScan(scan),
        child: Row(
          children: [
            M3IconTile(
              done ? Icons.view_in_ar_outlined : Icons.hexagon_outlined,
              size: 48,
              background: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: m3Text(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scan.fileCount} ảnh • ${scan.formattedDate}',
                    style: m3Text(11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  M3Pill(
                    scan.status.displayName,
                    color: scan.isProcessing
                        ? AppColors.badgePurpleText
                        : scan.status.textColor,
                    background: scan.isProcessing
                        ? AppColors.badgePurpleBg
                        : scan.status.backgroundColor,
                    fontSize: 10.5,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
