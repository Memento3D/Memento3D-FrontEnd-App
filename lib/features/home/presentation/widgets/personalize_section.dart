import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/constants/app_colors.dart';

class PersonalizeSection extends StatefulWidget {
  const PersonalizeSection({super.key});

  @override
  State<PersonalizeSection> createState() => _PersonalizeSectionState();
}

class _PersonalizeSectionState extends State<PersonalizeSection> {
  int _selectedColorIndex = 0;

  final _colors = [
    _ColorOption('Lavender Haze', const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), const Color(0xFF6D28D9)),
    _ColorOption('Peach Sorbet', const Color(0xFFF97316), const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
    _ColorOption('Matcha Mint', const Color(0xFF10B981), const Color(0xFFECFDF5), const Color(0xFF047857)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: "Make it so you 🎨" + Subtitle
        Row(
          children: [
            Text(
              'Make it so you ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const Text(
              '🎨',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Personalize every cute detail for that warm atelier feel',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Row 1: [Add your names] & [Keep a date]
        Row(
          children: [
            Expanded(
              child: _buildSmallFeatureCard(
                emoji: '🍰',
                title: 'Add your names',
                description: 'Engraved gently right onto the soft curved pedestal.',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallFeatureCard(
                emoji: '🗓️',
                title: 'Keep a date',
                description: 'Stamped in shimmering golden foil or blind deboss.',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 3. Middle Full-Width Card: [Pick favorite colors]
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF1F0F5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: [Pick favorite colors] ... [Signature finishes]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        'Pick favorite colors',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Signature finishes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Hand-tinted pastel palettes baked into every sculpture.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),

              // Color options pills
              Row(
                children: List.generate(_colors.length, (index) {
                  final color = _colors[index];
                  final isSelected = _selectedColorIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color.dotColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.dotColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              color.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 4. Row 2: [Tiny message] & [Cute display base]
        Row(
          children: [
            Expanded(
              child: _buildSmallFeatureCard(
                emoji: '💌',
                title: 'Tiny message',
                description: 'Subtly written underneath for only you two to know.',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallFeatureCard(
                emoji: '🏺',
                title: 'Cute display base',
                description: 'Scalloped ceramic porcelain or raw organic wood.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallFeatureCard({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption {
  final String name;
  final Color dotColor;
  final Color bgColor;
  final Color textColor;

  _ColorOption(this.name, this.dotColor, this.bgColor, this.textColor);
}
