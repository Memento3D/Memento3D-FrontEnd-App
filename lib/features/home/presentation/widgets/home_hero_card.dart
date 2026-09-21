import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';

class HomeHeroCard extends StatefulWidget {
  final VoidCallback? onCreateKeepsake;
  final VoidCallback? onSeeHowItWorks;

  const HomeHeroCard({
    super.key,
    this.onCreateKeepsake,
    this.onSeeHowItWorks,
  });

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<HomeHeroCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F0F5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badges: [Instant AI Sculpt • Ready in 2 mins] ... [Heart Favorite Icon]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mint Green Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F9F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: Color(0xFF047857),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Instant AI Sculpt • Ready in 2 mins',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),

              // Heart Favorite Icon Button
              GestureDetector(
                onTap: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Main Keepsake Showcase Image with Floating Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.05,
                  child: Image.asset(
                    'assets/images/besties_keepsake.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Top-Right Badge: "New drop"
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'New drop',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),

              // Bottom-Left Badge: Pink Dot + "Smooth Resin Matte"
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF472B6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Smooth Resin Matte',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Title: "Make a memory you can hold."
          Text(
            'Make a memory you can hold.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 6),

          // 4. Subtitle: "Your favorite photo, turned into your own little tangible keepsake figurine."
          Text(
            'Your favorite photo, turned into your own little tangible keepsake figurine.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          // 5. Primary Action Button: "Create a 3D Keepsake ✨"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onCreateKeepsake,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create a 3D Keepsake',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 6. Secondary Action Button: "See how it works →"
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton(
              onPressed: widget.onSeeHowItWorks,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF5F6FA),
                foregroundColor: const Color(0xFF1E1B4B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See how it works',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Color(0xFF1E1B4B),
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
