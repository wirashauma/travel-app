import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../package/presentation/package_history_page.dart';
import 'booking_history_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
}

// ═══════════════════════════════════════════════════════════
//  COMBINED HISTORY PAGE — Unified travel and package history
// ═══════════════════════════════════════════════════════════
class CombinedHistoryPage extends StatefulWidget {
  const CombinedHistoryPage({super.key});

  @override
  State<CombinedHistoryPage> createState() => _CombinedHistoryPageState();
}

class _CombinedHistoryPageState extends State<CombinedHistoryPage> {
  int _selectedTab = 0; // 0: Ticket History, 1: Package History

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── UNIFIED HEADER ──
          _buildHeader(topPadding),

          // ── CATEGORY SWITCH capsules ──
          _buildCategorySelector(),

          // ── ACTIVE CONTENT ──
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                BookingHistoryPage(showHeader: false),
                PackageHistoryPage(showHeader: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 12),
      decoration: const BoxDecoration(
        color: _C.white,
      ),
      child: Row(
        children: [
          Text(
            'Riwayat Transaksi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.receipt_21, size: 20, color: _C.primary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCategorySelector() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _C.borderLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Tab 0: Tiket Travel
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? _C.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedTab == 0
                        ? [
                            BoxShadow(
                              color: _C.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.ticket,
                        size: 16,
                        color: _selectedTab == 0 ? Colors.white : _C.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tiket Travel',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 0 ? Colors.white : _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab 1: Paket Kirim
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? _C.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedTab == 1
                        ? [
                            BoxShadow(
                              color: _C.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.box,
                        size: 16,
                        color: _selectedTab == 1 ? Colors.white : _C.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kirim Paket',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 1 ? Colors.white : _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
