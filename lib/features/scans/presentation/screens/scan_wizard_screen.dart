import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/scan_model.dart';

/// Guided Capture Wizard Screen (/scans/new per FRONTEND_ARCHITECTURE.md)
class ScanWizardScreen extends StatefulWidget {
  final String scanId;
  final ScanModel? scan;

  const ScanWizardScreen({
    super.key,
    required this.scanId,
    this.scan,
  });

  @override
  State<ScanWizardScreen> createState() => _ScanWizardScreenState();
}

class _ScanWizardScreenState extends State<ScanWizardScreen> {
  int _currentStep = 0;

  // Step 1: Environment Prep Checklist
  bool _chkBackground = false;
  bool _chkLighting = false;
  bool _chkStaticObject = false;
  bool _chkDistance = false;

  bool get _isChecklistComplete =>
      _chkBackground && _chkLighting && _chkStaticObject && _chkDistance;

  @override
  Widget build(BuildContext context) {
    final scanName = widget.scan?.name ?? 'Phiên Scan 3D';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guided Capture Wizard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              scanName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  widget.scanId.length > 8 ? widget.scanId.substring(0, 8) : widget.scanId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 4-Step Stepper Progress Bar
            _buildStepperHeader(),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Footer
            _buildBottomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final stepTitles = ['Môi trường', 'Chế độ', 'Thu thập', 'Tải lên'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isActive ? AppColors.primary : const Color(0xFFF3F4F6)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepTitles[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.primary : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 20,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: index < _currentStep ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Environment();
      case 1:
        return _buildStep2Mode();
      case 2:
        return _buildStep3Capture();
      case 3:
      default:
        return _buildStep4Upload();
    }
  }

  Widget _buildStep1Environment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 1: Chuẩn Bị Môi Trường Chụp',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Để mô hình 3D đạt độ chính xác cao nhất, vui lòng kiểm tra và xác nhận các điều kiện sau:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 18),
        _buildChecklistTile(
          title: 'Hậu cảnh đơn sắc hoặc có độ tương phản tốt',
          subtitle: 'Đặt vật thể trên mặt phẳng nhám, có hoa văn, không bóng gương.',
          value: _chkBackground,
          onChanged: (val) => setState(() => _chkBackground = val ?? false),
        ),
        _buildChecklistTile(
          title: 'Ánh sáng đều và tán xạ',
          subtitle: 'Tránh ánh sáng gắt một phía, không tạo bóng đổ đen đậm hoặc ngược sáng.',
          value: _chkLighting,
          onChanged: (val) => setState(() => _chkLighting = val ?? false),
        ),
        _buildChecklistTile(
          title: 'Cố định vật thể',
          subtitle: 'Tuyệt đối không di chuyển vật thể trong suốt toàn bộ quá trình chụp quanh nó.',
          value: _chkStaticObject,
          onChanged: (val) => setState(() => _chkStaticObject = val ?? false),
        ),
        _buildChecklistTile(
          title: 'Cự ly và độ phủ khung hình',
          subtitle: 'Vật thể chiếm khoảng 70% khung hình, lấy nét rõ mọi góc cạnh.',
          value: _chkDistance,
          onChanged: (val) => setState(() => _chkDistance = val ?? false),
        ),
      ],
    );
  }

  Widget _buildStep2Mode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 2: Chế Độ Thu Thập',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chế độ hiện tại cho phiên scan này:',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scan?.inputModeTextVi ?? 'Chế độ Chụp ảnh (Image Mode)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khuyến nghị từ 30 đến 100 bức ảnh 360 độ quanh vật thể',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Capture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 3: Thu Thập Hình Ảnh',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chụp ảnh trực tiếp hoặc tải ảnh có sẵn từ thư viện thiết bị:',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có ảnh nào được tải vào phiên',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mở máy ảnh hoặc chọn tệp .jpg/.png từ thư viện',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 4: Tải Lên Phân Đoạn (Chunked Upload)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dữ liệu sẽ được tự động chia thành các phân đoạn 5MB và gửi lên máy chủ.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4B5563)),
        ),
      ],
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppColors.primary : const Color(0xFFF1F0F5),
          width: value ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildBottomFooter() {
    final canProceed = _currentStep != 0 || _isChecklistComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0F5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep -= 1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Quay lại',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep += 1);
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _currentStep < 3 ? 'Tiếp tục' : 'Hoàn tất Wizard',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
