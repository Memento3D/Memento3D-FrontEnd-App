import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MomentsCategoryGrid extends StatelessWidget {
  final Function(String category)? onCategoryTap;

  const MomentsCategoryGrid({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryItem(
        emoji: '👫',
        title: 'Couples',
        subtitle: 'Anniversaries & hugs',
        bgColor: const Color(0xFFFFEDD5),
      ),
      _CategoryItem(
        emoji: '👯',
        title: 'Best friends',
        subtitle: 'Festivals & trips',
        bgColor: const Color(0xFFFEF3C7),
      ),
      _CategoryItem(
        emoji: '🐾',
        title: 'Pets',
        subtitle: 'Paws & whiskers',
        bgColor: const Color(0xFFD1FAE5),
      ),
      _CategoryItem(
        emoji: '✈️',
        title: 'Travel',
        subtitle: 'Postcard spots',
        bgColor: const Color(0xFFE0F2FE),
      ),
      _CategoryItem(
        emoji: '🏡',
        title: 'Family',
        subtitle: 'Reunions & roasts',
        bgColor: const Color(0xFFFFEDD5),
      ),
      _CategoryItem(
        emoji: '💖',
        title: 'Self-love',
        subtitle: 'Celebrate yourself',
        bgColor: const Color(0xFFFCE7F3),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: [Made for your moments] ... [Tap to start]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Made for your moments',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              'Tap to start',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 2-Column Grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () => onCategoryTap?.call(cat.title),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF1F0F5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cat.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cat.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;

  _CategoryItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
  });
}
