import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/scan_model.dart';

class ScanStatusBadge extends StatelessWidget {
  final ScanModel scan;

  const ScanStatusBadge({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scan.statusBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scan.statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scan.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            scan.statusTextVi,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scan.statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
