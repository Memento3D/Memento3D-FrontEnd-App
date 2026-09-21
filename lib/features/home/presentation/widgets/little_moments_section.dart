import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';

class LittleMomentsSection extends StatelessWidget {
  final VoidCallback? onViewAll;

  const LittleMomentsSection({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final moments = [
      _MomentItem(
        badgeText: '3D Ready 💖',
        title: 'Besties Forever',
        date: 'Aug 2024',
        tag: 'Lilac Pedestal',
        tagColor: const Color(0xFF7C3AED),
        tagBgColor: const Color(0xFFEDE9FE),
        imageAsset: 'assets/images/besties_keepsake.jpg',
      ),
      _MomentItem(
        badgeText: 'Cast in Resin 🌊',
        title: 'Our First Trip',
        date: 'June 2024',
        tag: 'Natural Wood',
        tagColor: const Color(0xFFB45309),
        tagBgColor: const Color(0xFFFEF3C7),
        imageAsset: 'assets/images/polaroid_3d_hero.jpg',
      ),
      _MomentItem(
        badgeText: 'Sculpting ✨',
        title: 'My Favorite H...',
        date: "Valentine's",
        tag: 'Pink Ceramic',
        tagColor: const Color(0xFFBE185D),
        tagBgColor: const Color(0xFFFCE7F3),
        imageAsset: 'assets/images/polaroid_3d_hero.jpg',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: [Your little moments] [4 total] ... [View all >]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Your little moments',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '4 total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Horizontal List of Moments
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: moments.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final moment = moments[index];
              return _buildMomentCard(context, moment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMomentCard(BuildContext context, _MomentItem moment) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F0F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.asset(
                    moment.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    moment.badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details below image
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      moment.date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        moment.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: moment.tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentItem {
  final String badgeText;
  final String title;
  final String date;
  final String tag;
  final Color tagColor;
  final Color tagBgColor;
  final String imageAsset;

  _MomentItem({
    required this.badgeText,
    required this.title,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.tagBgColor,
    required this.imageAsset,
  });
}
