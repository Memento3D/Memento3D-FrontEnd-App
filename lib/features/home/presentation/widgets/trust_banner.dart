import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrustBanner extends StatelessWidget {
  const TrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEDE9FE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left Shield / Verified Icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Middle Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Every piece hand-reviewed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Crafted with non-toxic botanical resins',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Right subtle icon
          const Icon(
            Icons.spa_outlined,
            size: 18,
            color: Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}
