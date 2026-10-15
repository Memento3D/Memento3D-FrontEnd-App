import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// Interactive illustration widget for Step 1: Chuẩn bị hậu cảnh đơn giản (Before / After).
class BackgroundPrepIllustration extends StatefulWidget {
  const BackgroundPrepIllustration({super.key});

  @override
  State<BackgroundPrepIllustration> createState() =>
      _BackgroundPrepIllustrationState();
}

class _BackgroundPrepIllustrationState
    extends State<BackgroundPrepIllustration> {
  bool _showAfter = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Before / After Toggle Buttons
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  title: '❌ Nên tránh',
                  isSelected: !_showAfter,
                  activeColor: const Color(0xFFEF4444),
                  onTap: () => setState(() => _showAfter = false),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildToggleButton(
                  title: '✅ Khuyên dùng',
                  isSelected: _showAfter,
                  activeColor: const Color(0xFF10B981),
                  onTap: () => setState(() => _showAfter = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Animated illustration card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _showAfter ? _buildAfterCard() : _buildBeforeCard(),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeCard() {
    return Container(
      key: const ValueKey('before_card'),
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Stack(
        children: [
          // Background clutter graphics
          Positioned(
            left: 20,
            top: 20,
            child: Icon(
              Icons.blur_on_rounded,
              size: 34,
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: Icon(
              Icons.auto_delete_outlined,
              size: 28,
              color: const Color(0xFFEF4444).withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 30,
            child: Icon(
              Icons.coffee_rounded,
              size: 24,
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),

          // Central confused object on messy surface
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        size: 38,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'Nền rối mắt, bề mặt bóng phản chiếu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfterCard() {
    return Container(
      key: const ValueKey('after_card'),
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Stack(
        children: [
          // Clean background guides
          Center(
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 64,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'Mặt phẳng nhám, đơn sắc, tương phản rõ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration widget for Step 2: Đảm bảo ánh sáng đồng đều, tránh ngược sáng.
class LightingPrepIllustration extends StatelessWidget {
  const LightingPrepIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 soft light sources radiating inwards
          Positioned(
            top: 12,
            left: 30,
            child: _buildLightNode(Icons.light_mode_rounded, 'Đèn trái'),
          ),
          Positioned(
            top: 12,
            right: 30,
            child: _buildLightNode(Icons.light_mode_rounded, 'Đèn phải'),
          ),
          Positioned(
            bottom: 14,
            left: 36,
            child: _buildLightNode(Icons.wb_twilight_rounded, 'Ánh sáng phòng'),
          ),
          Positioned(
            bottom: 14,
            right: 36,
            child: _buildLightNode(Icons.wb_sunny_outlined, 'Tán xạ đều'),
          ),

          // Glowing central subject
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

          // Central badge
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Chiếu sáng đều 360° • Không đổ bóng đen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightNode(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFD97706), size: 17),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF92400E),
          ),
        ),
      ],
    );
  }
}

/// Illustration widget for Step 3: Giữ vật thể cố định, người di chuyển 360°.
class StaticObjectIllustration extends StatelessWidget {
  const StaticObjectIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit circular track
          CustomPaint(
            size: const Size(140, 140),
            painter: _OrbitTrackPainter(),
          ),

          // 4 Orbiting camera viewpoints (static for testability and performance)
          _buildCameraAtAngle(0, 62),
          _buildCameraAtAngle(math.pi / 2, 62),
          _buildCameraAtAngle(math.pi, 62),
          _buildCameraAtAngle(3 * math.pi / 2, 62),

          // Central fixed object on pedestal
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.view_in_ar_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CỐ ĐỊNH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom caption
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Text(
                'Vật thể đứng yên • Bạn đi vòng tròn 360°',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraAtAngle(double angle, double radius) {
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.photo_camera_rounded,
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }
}

class _OrbitTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dashed circle
    const count = 28;
    for (int i = 0; i < count; i += 2) {
      final startAngle = (i / count) * 2 * math.pi;
      final sweepAngle = (1 / count) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration widget for Step 4: Duy trì khoảng cách camera hợp lý (30 - 80cm, ~70% khung hình).
class CameraDistanceIllustration extends StatelessWidget {
  const CameraDistanceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Viewfinder Frame Outline
          Container(
            width: 200,
            height: 125,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Viewfinder Reticle Corners
                const Positioned(
                  top: 5,
                  left: 5,
                  child: Icon(
                    Icons.crop_free_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    Icons.crop_free_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Positioned(
                  bottom: 5,
                  left: 5,
                  child: Icon(
                    Icons.crop_free_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Positioned(
                  bottom: 5,
                  right: 5,
                  child: Icon(
                    Icons.crop_free_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),

                // Centered 70% subject
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.view_in_ar_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '~70% KHUNG HÌNH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Distance Ruler Gauge below
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.straighten_rounded,
                    size: 13,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Khoảng cách chuẩn: 30 cm – 80 cm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
