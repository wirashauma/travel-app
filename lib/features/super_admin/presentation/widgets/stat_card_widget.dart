import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────
//  STAT CARD — Reusable statistics card widget
// ─────────────────────────────────────────────────────────

class StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final bool isLoading;

  const StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    this.isLoading = false,
  });
}

class StatCard extends StatelessWidget {
  final StatCardData data;
  final int index;
  final bool isSmall;

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF0F4C81);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textTertiary = Color(0xFF94A3B8);

  const StatCard({
    super.key,
    required this.data,
    required this.index,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 160 : 175,
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (data.isLoading)
            SkeletonLoader(
              child: SkeletonLoader.bar(
                width: isSmall ? 60 : 80,
                height: isSmall ? 16 : 18,
              ),
            )
          else
            Text(
              data.value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (250 + index * 80).ms, duration: 400.ms)
        .slideX(begin: 0.08, delay: (250 + index * 80).ms, duration: 400.ms);
  }
}
