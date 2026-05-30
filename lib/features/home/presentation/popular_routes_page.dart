import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Clean Slate / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color orange = Color(0xFFF97316);
}

// ═══════════════════════════════════════════════════════════
//  POPULAR ROUTES PAGE — Static Sumatera Barat Data
// ═══════════════════════════════════════════════════════════

/// Representasi rute populer statis.
class _RouteData {
  final String from;
  final String to;
  final int price;
  final String duration;
  final double distance;

  const _RouteData({
    required this.from,
    required this.to,
    required this.price,
    required this.duration,
    required this.distance,
  });
}

class PopularRoutesPage extends StatelessWidget {
  const PopularRoutesPage({super.key});

  /// 7 Rute populer Sumatera Barat (statis).
  static const List<_RouteData> _routes = [
    _RouteData(from: 'Padang', to: 'Bukittinggi', price: 45000, duration: '1j 55m', distance: 90),
    _RouteData(from: 'Padang', to: 'Payakumbuh', price: 55000, duration: '2j 40m', distance: 127),
    _RouteData(from: 'Bukittinggi', to: 'Padang', price: 45000, duration: '1j 55m', distance: 90),
    _RouteData(from: 'Padang', to: 'Solok', price: 40000, duration: '1j 20m', distance: 64),
    _RouteData(from: 'Padang', to: 'Pariaman', price: 25000, duration: '1j 10m', distance: 55),
    _RouteData(from: 'Payakumbuh', to: 'Batusangkar', price: 30000, duration: '40m', distance: 30),
    _RouteData(from: 'Padang', to: 'Pesisir Selatan', price: 60000, duration: '1j 40m', distance: 77),
  ];

  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ═══ APP BAR ═══
            _buildAppBar(context),

            // ═══ ROUTE LIST — Static Data ═══
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: _routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = _routes[index];
                  return _RouteCard(
                    from: r.from,
                    to: r.to,
                    price: _fmtPrice(r.price),
                    duration: r.duration,
                    distance: r.distance,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 14),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Rute Populer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Static count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_routes.length} rute',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  ROUTE CARD WIDGET — Static Sumatera Barat Data
// ═══════════════════════════════════════════════════════════
class _RouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String price;
  final String duration;
  final double distance;
  final int index;

  const _RouteCard({
    required this.from,
    required this.to,
    required this.price,
    required this.duration,
    required this.distance,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: cities
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keberangkatan',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _C.borderLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.arrow_right_3,
                      size: 14,
                      color: _C.textTertiary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      to,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tujuan',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _C.textTertiary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: _C.borderLight,
          ),

          // Bottom row: duration, distance, price
          Row(
            children: [
              // Duration chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.clock, size: 13, color: _C.primary),
                    const SizedBox(width: 5),
                    Text(
                      duration,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Distance chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.routing_2, size: 13, color: _C.orange),
                    const SizedBox(width: 5),
                    Text(
                      '${distance.toStringAsFixed(0)} km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Mulai dari',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: _C.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (80 + index * 80).ms, duration: 420.ms)
        .slideY(
          begin: 0.04,
          delay: (80 + index * 80).ms,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
