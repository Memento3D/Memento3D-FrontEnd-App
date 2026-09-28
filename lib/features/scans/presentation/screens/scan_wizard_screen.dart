import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../screens/camera_screen.dart';
import '../../data/models/scan_model.dart';
import '../../data/services/capture_wizard_storage.dart';
import '../../data/services/scan_sync_manager.dart';
import '../widgets/wizard_step_illustrations.dart';

/// Guided Capture Preparation Wizard Screen (Issue #45, Step 1 in Capture Flow)
///
/// Acceptance Criteria:
/// 1. Hiển thị đủ 4 bước hướng dẫn với hình minh hoạ, điều hướng Next/Back mượt.
/// 2. Nút Skip hiển thị đúng điều kiện (user đã từng hoàn thành wizard trước đó).
/// 3. "Bắt đầu chụp" chuyển đúng sang màn Camera Scan, mang theo scan_id.
/// 4. Nội dung dễ hiểu cho non-technical user.
/// 5. Hoạt động tốt cả khi xoay ngang/dọc màn hình mobile.
class ScanWizardScreen extends StatefulWidget {
  final String scanId;
  final ScanModel? scan;
  final String? scanName;

  /// Optional override for testing or manual forced completion state
  final bool? initialHasCompletedWizard;

  const ScanWizardScreen({
    super.key,
    required this.scanId,
    this.scan,
    this.scanName,
    this.initialHasCompletedWizard,
  });

  @override
  State<ScanWizardScreen> createState() => _ScanWizardScreenState();
}

class _ScanWizardScreenState extends State<ScanWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _canSkip = false;
  StreamSubscription<ScanSyncEvent>? _syncSubscription;
  String? _syncError;
  bool _isRetryingSync = false;

  @override
  void initState() {
    super.initState();
    _checkWizardEligibility();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    _syncSubscription = ScanSyncManager.instance.watchScan(widget.scanId).listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.isFailed) {
          _syncError = event.errorMessage ?? 'Không thể lưu phiên scan lên máy chủ';
          _isRetryingSync = false;
        } else if (event.isSuccess) {
          _syncError = null;
          _isRetryingSync = false;
        } else if (event.isSyncing) {
          _isRetryingSync = true;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant ScanWizardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHasCompletedWizard != oldWidget.initialHasCompletedWizard) {
      _checkWizardEligibility();
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkWizardEligibility() async {
    if (widget.initialHasCompletedWizard != null) {
      if (mounted) {
        setState(() => _canSkip = widget.initialHasCompletedWizard!);
      }
      return;
    }

    final hasCompleted = await CaptureWizardStorage.hasCompletedWizard();
    if (mounted) {
      setState(() => _canSkip = hasCompleted);
    }
  }

  Future<void> _handleStartCapture() async {
    if (_syncError != null) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Lưu ý đồng bộ',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Phiên scan này chưa được lưu trên máy chủ: $_syncError.\n\nBạn có muốn tiếp tục chụp cục bộ hay quay lại Dashboard?',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
                Navigator.of(context).pop();
              },
              child: const Text('Về Dashboard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Tiếp tục chụp'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    // Save completion flag locally so subsequent sessions show the "Skip" button
    await CaptureWizardStorage.markWizardCompleted();

    if (!mounted) return;

    final resolvedScanId = ScanSyncManager.instance.resolveId(widget.scanId);

    // Navigate to Camera Scan 360° screen (#9) carrying resolved scan_id
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CameraScreen(scanId: resolvedScanId),
      ),
    );
  }

  void _handleNextStep() {
    if (_currentStep < 3) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleStartCapture();
    }
  }

  void _handlePreviousStep() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.scan?.name ?? widget.scanName ?? 'Phiên Scan 3D';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF111827),
          ),
          onPressed: _handlePreviousStep,
          tooltip: 'Quay lại',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chuẩn Bị Chụp Scan 3D',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          // Alt Flow 1a: Nút "Skip hướng dẫn" chỉ hiển thị khi user đã hoàn thành wizard trước đó
          if (_canSkip)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                key: const Key('skip_wizard_button'),
                onPressed: _handleStartCapture,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Skip hướng dẫn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          // Scan Sync Status / ID Tag badge
          Builder(
            builder: (context) {
              final resolvedId = ScanSyncManager.instance.resolveId(widget.scanId);
              final status = ScanSyncManager.instance.getStatus(widget.scanId);
              final isSyncing = _isRetryingSync || status == ScanSyncState.syncing;
              final isFailed = _syncError != null || status == ScanSyncState.failed;

              Color bg = const Color(0xFFEDE9FE);
              Color fg = AppColors.primary;
              IconData icon = Icons.cloud_done_rounded;
              String label = resolvedId.length > 8 ? resolvedId.substring(0, 8) : resolvedId;

              if (isFailed) {
                bg = const Color(0xFFFEF2F2);
                fg = AppColors.error;
                icon = Icons.cloud_off_rounded;
                label = 'Chưa lưu';
              } else if (isSyncing) {
                bg = const Color(0xFFFFFBEB);
                fg = const Color(0xFFD97706);
                icon = Icons.cloud_upload_outlined;
                label = 'Đang lưu';
              }

              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: fg),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            return Column(
              children: [
                if (_syncError != null) _buildSyncErrorBanner(),

                // 4-Step Stepper Header Indicator
                _buildStepperHeader(isLandscape),

                // Carousel Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      _buildStepPage(
                        stepIndex: 0,
                        tag: 'BƯỚC 1 / 4 • NỀN CHỤP',
                        title: 'Chuẩn bị hậu cảnh đơn giản',
                        description:
                            'Đặt vật thể trên mặt bàn/sàn có màu đồng sắc hoặc tương phản cao. Tránh bề mặt kính bóng loáng hoặc quá nhiều đồ vật lộn xộn xung quanh.',
                        illustration: const BackgroundPrepIllustration(),
                        doItem:
                            'Nên dùng bề mặt nhám, màu trơn (như giấy trắng, mặt bàn gỗ mờ).',
                        dontItem:
                            'Tránh nền kính gương phản chiếu bóng hoặc lẫn lộn nhiều đồ đạc.',
                        proTip:
                            'Mẹo: Một tờ giấy A3 hoặc tấm vải phẳng màu trung tính là phông nền lý tưởng nhất!',
                        isLandscape: isLandscape,
                      ),
                      _buildStepPage(
                        stepIndex: 1,
                        tag: 'BƯỚC 2 / 4 • CHIẾU SÁNG',
                        title: 'Đảm bảo ánh sáng đồng đều, tránh ngược sáng',
                        description:
                            'Chiếu sáng đều mọi góc quanh vật thể. Tránh nguồn sáng gắt từ một phía tạo bóng đen kịt hoặc chụp ngược hướng đèn/cửa sổ nắng.',
                        illustration: const LightingPrepIllustration(),
                        doItem:
                            'Bật đủ đèn trong phòng hoặc chụp vào ban ngày với ánh sáng tán xạ dịu.',
                        dontItem:
                            'Không chụp ngược nguồn sáng mạnh chiếu thẳng vào ống kính máy ảnh.',
                        proTip:
                            'Mẹo: Nếu chụp dưới đèn bàn, hãy chiếu đèn hắt vào tường để ánh sáng lan tỏa mềm mại.',
                        isLandscape: isLandscape,
                      ),
                      _buildStepPage(
                        stepIndex: 2,
                        tag: 'BƯỚC 3 / 4 • QUỸ ĐẠO CHỤP',
                        title: 'Giữ vật thể cố định trong suốt quá trình chụp',
                        description:
                            'Vật thể cần đứng yên hoàn toàn tại một vị trí. Người chụp sẽ cầm điện thoại và di chuyển thành vòng tròn 360 độ xung quanh.',
                        illustration: const StaticObjectIllustration(),
                        doItem:
                            'Bạn bước đi từ từ quanh vật thể, giữ độ cao điện thoại ổn định.',
                        dontItem:
                            'Tuyệt đối không dùng tay xoay vặn hay dịch chuyển vị trí vật thể.',
                        proTip:
                            'Mẹo: Đặt vật thể trên bàn thấp hoặc mặt ghế để bạn dễ dàng đi vòng quanh 360° thuận tiện.',
                        isLandscape: isLandscape,
                      ),
                      _buildStepPage(
                        stepIndex: 3,
                        tag: 'BƯỚC 4 / 4 • CỰ LY CAMERA',
                        title: 'Duy trì khoảng cách camera hợp lý',
                        description:
                            'Giữ khoảng cách ổn định từ 30cm đến 80cm. Điều chỉnh sao cho vật thể chiếm khoảng 70% diện tích khung hình và luôn lấy nét rõ.',
                        illustration: const CameraDistanceIllustration(),
                        doItem:
                            'Vật thể chiếm ~70% khung hình, sắc nét mọi chi tiết bề mặt.',
                        dontItem:
                            'Tránh đứng quá xa (dưới 30% khung hình) hoặc quá sát làm mất góc cạnh.',
                        proTip:
                            'Mẹo: Ứng dụng sẽ tự động cảnh báo nếu bạn di chuyển quá nhanh hoặc camera bị nghiêng!',
                        isLandscape: isLandscape,
                      ),
                    ],
                  ),
                ),

                // Bottom Footer Navigation Controls
                _buildBottomFooter(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepperHeader(bool isLandscape) {
    final stepTitles = ['Hậu cảnh', 'Ánh sáng', 'Cố định', 'Khoảng cách'];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 6 : 10,
      ),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : (isActive
                                    ? AppColors.primary
                                    : const Color(0xFFF3F4F6)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stepTitles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 16,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: index < _currentStep
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E7EB),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepPage({
    required int stepIndex,
    required String tag,
    required String title,
    required String description,
    required Widget illustration,
    required String doItem,
    required String dontItem,
    required String proTip,
    required bool isLandscape,
  }) {
    if (isLandscape) {
      // Landscape: 2-column side-by-side layout
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Visual illustration
            Expanded(
              flex: 5,
              child: illustration,
            ),
            const SizedBox(width: 20),

            // Right column: Content details
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTagBadge(tag),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistCards(doItem, dontItem),
                  const SizedBox(height: 10),
                  _buildTipBox(proTip),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Portrait: Vertical scrollable flow
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagBadge(tag),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Central Illustration
          illustration,
          const SizedBox(height: 14),

          // Do's & Don'ts Checklist Cards
          _buildChecklistCards(doItem, dontItem),
          const SizedBox(height: 10),

          // Pro Tip Box
          _buildTipBox(proTip),
        ],
      ),
    );
  }

  Widget _buildTagBadge(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildChecklistCards(String doItem, String dontItem) {
    return Column(
      children: [
        // Do item (green)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doItem,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF166534),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Don't item (red)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dontItem,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipBox(String proTip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              proTip,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFooter() {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0F5))),
      ),
      child: Row(
        children: [
          // "Quay lại" button
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                key: const Key('back_step_button'),
                onPressed: _handlePreviousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Quay lại',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),

          // Next or Start Capture CTA button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              key: Key(isLastStep ? 'start_capture_button' : 'next_step_button'),
              onPressed: _handleNextStep,
              icon: Icon(
                isLastStep
                    ? Icons.photo_camera_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(
                isLastStep ? 'Bắt đầu chụp' : 'Tiếp tục',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: isLastStep
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lưu ý: $_syncError',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isRetryingSync
                ? null
                : () {
                    setState(() => _isRetryingSync = true);
                    ScanSyncManager.instance.retrySync(widget.scanId);
                  },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _isRetryingSync
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                      ),
                    )
                  : Text(
                      'Thử lại',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience alias to align with CapturePreparationScreen naming convention
typedef CapturePreparationScreen = ScanWizardScreen;
