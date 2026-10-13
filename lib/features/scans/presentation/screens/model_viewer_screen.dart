import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/scan_item.dart';
import '../../data/models/scan_output_model.dart';
import '../../data/repositories/scan_repository.dart';

/// Load state for the model fetched from `GET /api/v1/scans/{id}/outputs`.
enum _ViewerLoadState { loading, ready, error }

/// Shading mode toggle for the 3D preview surface.
enum _ShadingMode { shaded, wireframe }

/// Full-screen "Mô hình 3D" result/viewer screen shown after a scan finishes processing.
///
/// Fetches the generated output files via `GET /api/v1/scans/{scanId}/outputs` and
/// displays the primary GLB. The actual render surface is a placeholder (rotate/zoom
/// via gesture) until a real model-viewer package is wired in.
class ModelViewerScreen extends StatefulWidget {
  const ModelViewerScreen({super.key, required this.scanId, this.scan});

  final String scanId;
  final ScanItem? scan;

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  final ScanRepository _repository = ScanRepository.instance;

  _ViewerLoadState _loadState = _ViewerLoadState.loading;
  String _errorMessage = '';
  ScanOutputModel? _output;

  _ShadingMode _shadingMode = _ShadingMode.shaded;

  double _rotationY = -0.35;
  double _rotationX = -0.12;
  double _scale = 1.0;

  static const double _minScale = 0.7;
  static const double _maxScale = 1.8;

  String get _modelName => widget.scan?.name ?? 'Mô hình của bạn';

  @override
  void initState() {
    super.initState();
    _fetchOutputs();
  }

  Future<void> _fetchOutputs() async {
    setState(() {
      _loadState = _ViewerLoadState.loading;
      _errorMessage = '';
    });

    try {
      final response = await _repository.getScanOutputsAsync(widget.scanId);
      final primary = response.primaryOutput;

      if (!mounted) return;

      if (primary == null) {
        setState(() {
          _loadState = _ViewerLoadState.error;
          _errorMessage = 'Chưa có file mô hình nào được tạo cho phiên scan này.';
        });
        return;
      }

      setState(() {
        _output = primary;
        _loadState = _ViewerLoadState.ready;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadState = _ViewerLoadState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadState = _ViewerLoadState.error;
        _errorMessage = 'Không thể tải dữ liệu mô hình. Vui lòng thử lại.';
      });
    }
  }

  void _resetView() {
    setState(() {
      _rotationY = -0.35;
      _rotationX = -0.12;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildInfoBar(),
              const SizedBox(height: 16),
              _buildViewer(),
              const SizedBox(height: 16),
              _buildModelInfoCard(),
              const SizedBox(height: 20),
              _buildPrimaryButton(),
              const SizedBox(height: 10),
              _buildSecondaryButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Text(
          'Mô hình 3D',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        _pillBadge(label: '360°', bg: AppColors.badgePurpleBg, fg: AppColors.badgePurpleText),
        const Spacer(),
        _circleIconButton(
          icon: Icons.help_outline_rounded,
          onTap: () => _showInfoSheet(context),
        ),
        const SizedBox(width: 8),
        _circleIconButton(
          icon: Icons.ios_share_rounded,
          onTap: () => _showShareSnackBar(context),
        ),
      ],
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 19, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Info bar
  // ---------------------------------------------------------------------

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.dotGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(_output?.format ?? 'GLB').toUpperCase()} • Primary',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switch (_loadState) {
                        _ViewerLoadState.ready => '100% Hoàn tất',
                        _ViewerLoadState.loading => 'Đang tải...',
                        _ViewerLoadState.error => 'Lỗi tải',
                      },
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.cardBorder),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(Icons.threesixty_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tương tác',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xoay • Zoom • Di chuyển',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Viewer
  // ---------------------------------------------------------------------

  Widget _buildViewer() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1EEFE), Color(0xFFFBFBFE)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_loadState != _ViewerLoadState.error) _buildModelSurface(),
              if (_loadState == _ViewerLoadState.ready) _buildFloatingSparkles(),
              if (_loadState == _ViewerLoadState.ready) ...[
                Positioned(left: 14, bottom: 14, child: _buildResetViewChip()),
                Positioned(right: 14, bottom: 14, child: _buildShadingToggle()),
              ],
              if (_loadState == _ViewerLoadState.loading) _buildLoadingOverlay(),
              if (_loadState == _ViewerLoadState.error) _buildErrorOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelSurface() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleUpdate: (details) {
        setState(() {
          _rotationY += details.focalPointDelta.dx * 0.01;
          _rotationX = (_rotationX + details.focalPointDelta.dy * 0.01).clamp(-0.9, 0.9);
          if (details.pointerCount > 1) {
            _scale = (_scale * details.scale).clamp(_minScale, _maxScale);
          }
        });
      },
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0018)
            ..rotateX(_rotationX)
            ..rotateY(_rotationY)
            ..scaleByDouble(_scale, _scale, _scale, 1),
          child: _ClayBustPlaceholder(wireframe: _shadingMode == _ShadingMode.wireframe),
        ),
      ),
    );
  }

  Widget _buildFloatingSparkles() {
    const positions = [
      Offset(0.14, 0.22),
      Offset(0.82, 0.18),
      Offset(0.1, 0.72),
      Offset(0.86, 0.68),
    ];
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (final p in positions)
                Positioned(
                  left: constraints.maxWidth * p.dx,
                  top: constraints.maxHeight * p.dy,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResetViewChip() {
    return _ViewerPill(
      onTap: _resetView,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_rounded, size: 15, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(
            'Reset View',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildShadingToggle() {
    return _ViewerPill(
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _shadingSegment('Shaded', _ShadingMode.shaded),
          _shadingSegment('Wireframe', _ShadingMode.wireframe),
        ],
      ),
    );
  }

  Widget _shadingSegment(String label, _ShadingMode mode) {
    final selected = _shadingMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _shadingMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.75),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
            SizedBox(height: 12),
            Text(
              'Đang tải mô hình…',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: AppColors.error),
          const SizedBox(height: 10),
          Text(
            'Không tải được mô hình',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Vui lòng thử lại sau',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _fetchOutputs,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Thử lại'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Model info card
  // ---------------------------------------------------------------------

  Widget _buildModelInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.badgePurpleBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.view_in_ar_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _modelName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _pillBadge(
                      label: 'Đã hoàn tất',
                      bg: AppColors.badgeGreenBg,
                      fg: AppColors.badgeGreenText,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _output != null
                      ? 'Mô hình 3D đã được tạo thành công từ ảnh của bạn (${_output!.formattedSize}).'
                      : 'Mô hình 3D đã được tạo thành công từ ảnh của bạn.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pillBadge(
            label: (_output?.format ?? 'GLB').toUpperCase(),
            bg: const Color(0xFFF3F4F6),
            fg: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------

  Widget _buildPrimaryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang kiểm tra khả năng in 3D…'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.settings_suggest_rounded, size: 20),
      label: const Text('Kiểm tra khả năng in 3D'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton.icon(
      onPressed: () => _showShareSnackBar(context),
      icon: Icon(Icons.star_outline_rounded, size: 20, color: AppColors.textPrimary),
      label: Text('Đánh giá / Chia sẻ', style: TextStyle(color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.cardBorder),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showShareSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đánh giá / chia sẻ sắp ra mắt ✨'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Thao tác với mô hình 3D',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              '• Kéo 1 ngón để xoay mô hình\n'
              '• Chụm 2 ngón để phóng to / thu nhỏ\n'
              '• Nhấn "Reset View" để quay lại góc nhìn ban đầu\n'
              '• Chuyển "Shaded / Wireframe" để xem dạng khối hoặc lưới',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillBadge({required String label, required Color bg, required Color fg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Small translucent pill used for the floating controls over the viewer.
class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: content),
    );
  }
}

/// Stylized placeholder "clay bust" standing in for the rendered GLB model
/// until a real model-viewer surface is wired in.
class _ClayBustPlaceholder extends StatelessWidget {
  const _ClayBustPlaceholder({required this.wireframe});

  final bool wireframe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: CustomPaint(
        painter: _BustPainter(wireframe: wireframe),
      ),
    );
  }
}

class _BustPainter extends CustomPainter {
  _BustPainter({required this.wireframe});

  final bool wireframe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.34;

    final shoulders = Path()
      ..moveTo(size.width * 0.16, size.height)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.68, size.width * 0.5, size.height * 0.64)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.68, size.width * 0.84, size.height)
      ..close();

    if (!wireframe) {
      final headGradient = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: const [Color(0xFFE8C9A3), Color(0xFFCB9F6D)],
      );
      final shoulderPaint = Paint()..color = const Color(0xFFD8DCE8);
      canvas.drawPath(shoulders, shoulderPaint);

      final headPaint = Paint()..shader = headGradient.createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, headPaint);

      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.35), radius * 0.28, highlight);
    } else {
      final strokePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(shoulders, strokePaint);
      canvas.drawCircle(center, radius, strokePaint);

      // Latitude/longitude guide lines to sell the "wireframe" look.
      for (var i = 1; i < 4; i++) {
        final r = radius * (i / 4);
        canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2, height: r * 2 * 0.5), strokePaint);
      }
      for (var i = 0; i < 6; i++) {
        final angle = math.pi * i / 6;
        canvas.drawLine(
          Offset(center.dx - math.cos(angle) * radius, center.dy - math.sin(angle) * radius),
          Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius),
          strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BustPainter oldDelegate) => oldDelegate.wireframe != wireframe;
}
