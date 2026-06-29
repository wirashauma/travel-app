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
  static const Color borderLight = Color(0xFFF1F5F9);
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
      statusBarIconBrightness: Brightness.light,
    ));

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── UNIFIED HEADER WITH FLOATING SELECTOR ──
          _buildHeader(topPadding),

          const SizedBox(height: 32),

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blue Header Container
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 48),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.primary, Color(0xFF1A6BB3)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Riwayat Transaksi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.receipt_21, size: 20, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pantau status perjalanan dan pengiriman Anda',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Floating category selector capsules
        Positioned(
          left: 20,
          right: 20,
          bottom: -22,
          child: _buildCategorySelector(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: _C.borderLight),
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
          // Tab 1: Kirim Paket
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
    );
  }
}
