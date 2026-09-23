import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/scan_model.dart';
import '../controllers/scan_state.dart';
import '../screens/scan_wizard_screen.dart';

/// Modal BottomSheet for creating a new 3D scan session (US-005, UF-02A)
/// Conforms precisely to the Memento3D NewScanModal UI Design
class CreateScanBottomSheet extends StatefulWidget {
  final void Function(ScanModel newScan)? onScanCreated;
  final VoidCallback? onNavigateToDashboard;
  final ScanState? scanState;

  const CreateScanBottomSheet({
    super.key,
    this.onScanCreated,
    this.onNavigateToDashboard,
    this.scanState,
  });

  /// Static helper to display the creation sheet
  static Future<ScanModel?> show(
    BuildContext context, {
    void Function(ScanModel newScan)? onScanCreated,
    VoidCallback? onNavigateToDashboard,
    ScanState? scanState,
  }) {
    return showModalBottomSheet<ScanModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CreateScanBottomSheet(
        onScanCreated: onScanCreated,
        onNavigateToDashboard: onNavigateToDashboard,
        scanState: scanState,
      ),
    );
  }

  @override
  State<CreateScanBottomSheet> createState() => _CreateScanBottomSheetState();
}

class _CreateScanBottomSheetState extends State<CreateScanBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _inputMode = 'video'; // Default to 'video' or 'image' matching design
  bool _isSubmitting = false;
  String? _serverInlineError;

  ScanState get _state => widget.scanState ?? ScanState.instance;

  static const List<String> _sampleNames = [
    'Tượng Chó Corgi Để Bàn',
    'Bình Hoa Gốm Cổ Men Rạn',
    'Mô Hình Đồ Chơi Mini',
    'Đôi Giày Sneaker Thể Thao',
    'Chậu Cây Sen Đá Để Bàn',
    'Tượng Gỗ Khắc Nghệ Thuật',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _suggestRandomName() {
    final random = Random();
    final name = _sampleNames[random.nextInt(_sampleNames.length)];
    _applyName(name);
  }

  void _applyName(String name) {
    setState(() {
      _nameController.text = name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
      _serverInlineError = null;
    });
  }

  Future<void> _handleSubmit() async {
    // Double-submit protection
    if (_isSubmitting) return;

    // Reset server inline error and trigger client-side validation
    setState(() => _serverInlineError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final newScan = await _state.createScan(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      notes: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      inputMode: _inputMode,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (newScan != null) {
      // 201 Created -> Pop bottom sheet & Redirect into Wizard with scan_id
      final navigator = Navigator.of(context);
      widget.onScanCreated?.call(newScan);
      navigator.pop(newScan);

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ScanWizardScreen(
            scanId: newScan.id,
            scan: newScan,
          ),
        ),
      );
    } else {
      final statusCode = _state.lastErrorStatusCode;

      if (statusCode == 403) {
        // 403 Forbidden -> Quota Exceeded Modal
        _showQuotaModal();
      } else if (statusCode == 400) {
        // 400 Bad Request -> Inline validation error under name field
        setState(() {
          _serverInlineError = _state.errorMessage ?? 'Tên phiên scan không hợp lệ';
        });
        _formKey.currentState?.validate();
      } else {
        // Generic fallback error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_state.errorMessage ?? 'Không thể tạo phiên scan. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showQuotaModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 26,
            ),
          ),
          title: Text(
            'Hết dung lượng lưu trữ',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Xoá scan cũ để tiếp tục. Tài khoản của bạn đã đạt hạn mức 10 GB.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Đóng',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final parentNav = Navigator.of(context);
                      Navigator.of(dialogContext).pop(); // Close dialog
                      parentNav.pop(); // Close bottom sheet
                      widget.onNavigateToDashboard?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Đi tới Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag indicator
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Header (Title, Subtitle & Close Button)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo Phiên Scan Mới ✨',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thu thập ảnh hoặc video để AI tái tạo mô hình 3D in được',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. TÊN PHIÊN SCAN *
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'TÊN PHIÊN SCAN ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFF334155),
                        ),
                        children: const [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _suggestRandomName,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Gợi ý tên',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  maxLength: 255,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_serverInlineError != null) {
                      setState(() => _serverInlineError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Tượng Chó Corgi Để Bàn',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    counterText: '',
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  validator: (value) {
                    if (_serverInlineError != null) {
                      return _serverInlineError;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Tên phiên scan không được để trống';
                    }
                    if (value.trim().length > 255) {
                      return 'Tên phiên scan không được vượt quá 255 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Gợi ý Tags
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      Text(
                        'Gợi ý: ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      _buildSuggestionChip('🐾 Cún cưng', 'Tượng Cún Cưng Corgi'),
                      const SizedBox(width: 6),
                      _buildSuggestionChip('🧸 Đồ chơi mini', 'Mô Hình Đồ Chơi Mini'),
                      const SizedBox(width: 6),
                      _buildSuggestionChip('🏺 Bình gốm', 'Bình Hoa Gốm Cổ'),
                      const SizedBox(width: 6),
                      _buildSuggestionChip('👟 Giày sneaker', 'Đôi Giày Sneaker Thể Thao'),
                      const SizedBox(width: 6),
                      _buildSuggestionChip('🪴 Chậu cây', 'Chậu Cây Sen Đá Mini'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. CHẾ ĐỘ THU THẬP DỮ LIỆU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHẾ ĐỘ THU THẬP DỮ LIỆU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      'chọn 1 phương thức',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF818CF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // Card 1: Chụp ảnh đa góc
                    Expanded(
                      child: _buildModeCard(
                        mode: 'image',
                        icon: Icons.camera_alt_outlined,
                        title: 'Chụp ảnh đa góc',
                        subtitle: '30 – 100 ảnh góc quét xoay quanh mẫu',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2: Quay video 360°
                    Expanded(
                      child: _buildModeCard(
                        mode: 'video',
                        icon: Icons.videocam_outlined,
                        title: 'Quay video 360°',
                        subtitle: '≥ 10s xoay mượt mà, AI tự trích xuất frame',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Secondary Action: Tải từ thư viện ảnh máy...
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Tính năng chọn ảnh từ thư viện sẽ mở sau khi khởi tạo phiên scan.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Tải từ thư viện ảnh máy...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. GHI CHÚ BỔ SUNG
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GHI CHÚ BỔ SUNG',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      'TÙY CHỌN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Ghi chú về chất liệu (bóng, kim loại, mờ), điều kiện chiếu sáng hoặc góc muốn lấy nét nhất...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Tip Banner (Mẹo quét chuẩn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 17)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'Mẹo quét chuẩn: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Đặt vật phẩm ở nền màu tương phản, ánh sáng tản đều không bóng gắt, xoay từ từ quanh góc 360° để thu được đầy đủ chiều sâu.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFB45309),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Submit Button (Bắt đầu Quét Ngay ➔)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4DF7),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF5B4DF7).withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Đang khởi tạo...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Bắt đầu Quét Ngay',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, String fillValue) {
    return InkWell(
      onTap: () => _applyName(fillValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _inputMode == mode;

    return InkWell(
      onTap: () => setState(() => _inputMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
