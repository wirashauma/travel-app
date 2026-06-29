import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color orange = Color(0xFFF97316);
  static const Color error = Color(0xFFDC2626);
}

// ═══════════════════════════════════════════════════════════
//  POPULAR ROUTES PAGE — Dynamic Firestore Data
// ═══════════════════════════════════════════════════════════

class PopularRoutesPage extends StatelessWidget {
  const PopularRoutesPage({super.key});

  static final _routesRef = FirebaseFirestore.instance
      .collection('routes')
      .orderBy('price');

  String _fmtPrice(num price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _fmtDuration(dynamic duration) {
    if (duration == null) return '-';
    return duration.toString();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _routesRef.snapshots(),
          builder: (context, snapshot) {
            // ── Loading ──
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _buildAppBar(context, null),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _C.primary),
                    ),
                  ),
                ],
              );
            }

            // ── Error ──
            if (snapshot.hasError) {
              return Column(
                children: [
                  _buildAppBar(context, null),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.warning_2,
                              size: 48, color: _C.error),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat rute',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // ── Empty ──
            if (docs.isEmpty) {
              return Column(
                children: [
                  _buildAppBar(context, 0),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.route_square,
                              size: 48, color: _C.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada rute tersedia',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hubungi Super Admin untuk menambahkan rute.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _C.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildAppBar(context, docs.length),
                // ═══ ROUTE LIST — Dynamic Firestore ═══
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final docData =
                          docs[index].data() as Map<String, dynamic>?;
                      final from = docData?['from'] as String? ?? '-';
                      final to = docData?['to'] as String? ?? '-';
                      final price = (docData?['price'] as num?) ?? 0;
                      final duration = docData?['duration'];
                      final distance =
                          ((docData?['distance'] as num?) ?? 0).toDouble();

                      return _RouteCard(
                        from: from,
                        to: to,
                        price: _fmtPrice(price),
                        duration: _fmtDuration(duration),
                        distance: distance,
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int? count) {
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
              'Rute Tersedia',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Dynamic count badge
          if (count != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count rute',
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
//  ROUTE CARD WIDGET — Dynamic Data
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
