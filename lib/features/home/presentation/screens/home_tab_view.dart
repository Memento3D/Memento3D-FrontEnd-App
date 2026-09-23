import 'package:flutter/material.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:memento3d_frontend_app/features/home/presentation/widgets/home_header.dart';
import 'package:memento3d_frontend_app/features/home/presentation/widgets/home_hero_card.dart';
import 'package:memento3d_frontend_app/features/home/presentation/widgets/little_moments_section.dart';
import 'package:memento3d_frontend_app/features/home/presentation/widgets/trust_banner.dart';

class HomeTabView extends StatelessWidget {
  final VoidCallback? onCreateKeepsake;
  final VoidCallback? onViewAllScans;

  const HomeTabView({
    super.key,
    this.onCreateKeepsake,
    this.onViewAllScans,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header:
          HomeHeader(
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không có thông báo mới.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onProfileTap: () {
              final user = AuthState.instance.currentUser;
              final name = (user != null && user.fullName.trim().isNotEmpty)
                  ? user.fullName.trim()
                  : 'bạn';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hồ sơ người dùng $name.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // 2. Peach Pill Handle Indicator
          Center(
            child: Container(
              width: 52,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFF6B8A2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Hero Keepsake Card: "Make a memory you can hold."
          HomeHeroCard(
            onCreateKeepsake: onCreateKeepsake ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Bắt đầu tạo 3D Keepsake mới! ✨'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            onSeeHowItWorks: () {
              _showHowItWorksModal(context);
            },
          ),

          const SizedBox(height: 24),

          // 4. Section: Your little moments (4 total)
          LittleMomentsSection(
            onViewAll: onViewAllScans ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Xem toàn bộ các kỷ niệm của bạn.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 5. Trust Banner: Every piece hand-reviewed
          const TrustBanner(),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  void _showHowItWorksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 18),
              const Text(
                'How It Works ✨',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              _buildStepRow('1', 'Tải ảnh khoảnh khắc đẹp nhất của bạn lên.'),
              const SizedBox(height: 10),
              _buildStepRow('2', 'AI của Memento3D sẽ tái tạo và điêu khắc thành mô hình 3D trong 2 phút.'),
              const SizedBox(height: 10),
              _buildStepRow('3', 'Tùy chỉnh đế, màu sắc, khắc tên và nhận sản phẩm tượng kỷ niệm tận tay!'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
