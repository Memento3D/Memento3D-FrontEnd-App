import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

export 'create_scan_bottom_sheet.dart';

class CreateScanDialog extends StatefulWidget {
  final Function({
    required String name,
    required ScanInputMode inputMode,
    String? description,
    String? notes,
  }) onSubmit;

  const CreateScanDialog({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String name,
      required ScanInputMode inputMode,
      String? description,
      String? notes,
    }) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CreateScanDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<CreateScanDialog> createState() => _CreateScanDialogState();
}

class _CreateScanDialogState extends State<CreateScanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  ScanInputMode _selectedMode = ScanInputMode.image;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  void _handleSubmit() {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final mode = _selectedMode;
      final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      // Dismiss dialog immediately for instantaneous UX
      Navigator.of(context).pop();

      try {
        final result = widget.onSubmit(
          name: name,
          inputMode: mode,
          description: desc,
          notes: notes,
        );
        if (result is Future) {
          result.catchError((_) {});
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tạo phiên Scan mới ✨',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Khởi tạo phiên số hóa 3D cho vật thể hoặc khoảnh khắc của bạn',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 20),

              // 1. Scan Name (Required - US-005)
              Text(
                'Tên phiên scan *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'VD: Tượng chú cún cưng, Lọ hoa gốm...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên phiên scan';
                  }
                  if (val.trim().length < 3) {
                    return 'Tên scan phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 2. Select Mode (Image or Video)
              Text(
                'Chế độ thu thập dữ liệu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModeOption(
                      mode: ScanInputMode.image,
                      title: 'Ảnh chụp (Photo)',
                      subtitle: '30 - 100 ảnh góc bao quanh',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeOption(
                      mode: ScanInputMode.video,
                      title: 'Quay Video',
                      subtitle: 'Video >= 10s xoay mượt mà',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Description (Optional)
              Text(
                'Mô tả / Ghi chú (tùy chọn)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Thêm thông tin vật thể, điều kiện ánh sáng...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Hủy',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Tạo phiên scan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required ScanInputMode mode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mode.icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
