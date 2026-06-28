import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/models/booking_model.dart';
import 'qr_scanner_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (consistent with app)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color occupied = Color(0xFF0F4C81);
  static const Color empty = Color(0xFFE2E8F0);
}

// ═══════════════════════════════════════════════════════════
//  LIVE TRIP MANIFEST PAGE — Firestore StreamBuilder
//
//  SINKRONISASI 2 (Admin/Sopir → User & Super Admin)
//  StreamBuilder on bookings where('fleetId', isEqualTo: ...)
//   AND where('departureDate', isEqualTo: ...)
//   AND where('origin', isEqualTo: ...)
//   AND where('destination', isEqualTo: ...)
//
//  When a ticket is scanned, status changes 'paid' → 'completed'
//  and this page reflects it in real-time:
//  - Seat layout shows validated seats
//  - Passenger list updates validation badges
//  - Stats (validated count) updates instantly
// ═══════════════════════════════════════════════════════════
class LiveTripManifestPage extends StatelessWidget {
  /// Fleet ID for filtering bookings
  final String fleetId;

  /// Trip identification — used to filter bookings for THIS specific trip
  final String departureDate;
  final String origin;
  final String destination;

  /// Display info
  final String fleetName;
  final int totalSeats;

  const LiveTripManifestPage({
    super.key,
    required this.fleetId,
    required this.departureDate,
    required this.origin,
    required this.destination,
    required this.fleetName,
    this.totalSeats = 8,
  });

  /// Build the Firestore query: bookings for this specific trip group
  Stream<List<BookingModel>> get _tripBookingsStream {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('fleetId', isEqualTo: fleetId)
        .where('departureDate', isEqualTo: departureDate)
        .where('origin', isEqualTo: origin)
        .where('destination', isEqualTo: destination)
        .where('status', whereIn: ['paid', 'used', 'completed'])
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => BookingModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final isSmall = mq.size.width < 360;

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<List<BookingModel>>(
        stream: _tripBookingsStream,
        builder: (context, snapshot) {
          final bookings = snapshot.data ?? [];

          // Build passenger list from bookings
          final passengers = <_Passenger>[];
          for (final b in bookings) {
            for (final seat in b.seatNumbers) {
              passengers.add(
                _Passenger(
                  name: b.userName,
                  seatNumber: seat,
                  isValidated: b.status.isValidated,
                  bookingCode: b.bookingCode,
                  bookingId: b.id ?? '',
                ),
              );
            }
          }
          passengers.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

          final validatedCount = passengers.where((p) => p.isValidated).length;

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── APP BAR ──
                  SliverToBoxAdapter(
                    child: _buildAppBar(
                      context,
                      topPad,
                      validatedCount,
                      passengers.length,
                    ),
                  ),

                  // ── ROUTE HEADER CARD ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _buildRouteCard(isSmall, passengers.length),
                    ),
                  ),

                  // ── SEAT LAYOUT ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildSeatLayout(context, isSmall, passengers),
                    ),
                  ),

                  // ── PASSENGER LIST HEADER ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.people,
                            size: 18,
                            color: _C.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daftar Penumpang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _C.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${passengers.length} orang',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.primary,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                    ),
                  ),

                  // ── PASSENGER LIST ──
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      bookings.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: _C.primary),
                      ),
                    )
                  else if (passengers.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.people, size: 48, color: _C.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada penumpang',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) => _buildPassengerTile(
                            context,
                            passengers[index],
                            index,
                          ),
                          childCount: passengers.length,
                        ),
                      ),
                    ),
                ],
              ),

              // ── FAB — Scan QR ──
              Positioned(
                bottom: bottomPad + 24,
                right: 20,
                child: _buildScanFAB(context),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────
  Widget _buildAppBar(
    BuildContext context,
    double topPad,
    int validated,
    int total,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 20, 12),
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Perjalanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$validated/$total tervalidasi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _C.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Validated badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: validated == total && total > 0
                  ? _C.successBg
                  : _C.warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  validated == total && total > 0
                      ? Iconsax.tick_circle
                      : Iconsax.clock,
                  size: 13,
                  color: validated == total && total > 0
                      ? _C.success
                      : _C.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  validated == total && total > 0
                      ? 'Lengkap'
                      : '$validated/$total',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: validated == total && total > 0
                        ? _C.success
                        : _C.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  ROUTE HEADER CARD
  // ─────────────────────────────────────────────────────
  Widget _buildRouteCard(bool isSmall, int bookedSeats) {
    return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Route row ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dari',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          origin,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isSmall ? 15 : 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tujuan',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isSmall ? 15 : 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Info row ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Iconsax.calendar_1, departureDate),
                    _infoChip(Iconsax.car, fleetName),
                    _infoChip(Iconsax.people, '$bookedSeats/$totalSeats'),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.06, delay: 200.ms, duration: 500.ms);
  }

  Widget _infoChip(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SEAT LAYOUT — 8 seats + driver
  // ─────────────────────────────────────────────────────
  Widget _buildSeatLayout(
    BuildContext context,
    bool isSmall,
    List<_Passenger> passengers,
  ) {
    bool isSeatOccupied(int n) => passengers.any((p) => p.seatNumber == n);
    _Passenger? passengerAt(int n) {
      final m = passengers.where((p) => p.seatNumber == n);
      return m.isEmpty ? null : m.first;
    }

    Widget seatTile(_SeatType type, double size) {
      if (type.isEmpty) return SizedBox(width: size, height: size);
      if (type.isAisle) {
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.arrow_down,
                  size: 12,
                  color: _C.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 1),
                Text(
                  'Lorong',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: _C.textHint.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (type.isDriver) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _C.textHint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.textHint.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.driving, size: size * 0.28, color: _C.textTertiary),
              const SizedBox(height: 2),
              Text(
                'Driver',
                style: GoogleFonts.inter(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w600,
                  color: _C.textTertiary,
                ),
              ),
            ],
          ),
        );
      }

      // Seat
      final seatNum = type.seatNumber!;
      final occ = isSeatOccupied(seatNum);
      final pax = passengerAt(seatNum);
      final validated = pax?.isValidated ?? false;

      return GestureDetector(
        onTap: pax != null ? () => _showPassengerDetail(context, pax) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: occ
                ? validated
                      ? _C.success.withValues(alpha: 0.12)
                      : _C.occupied.withValues(alpha: 0.12)
                : _C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: occ
                  ? validated
                        ? _C.success
                        : _C.occupied
                  : _C.empty,
              width: occ ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                occ
                    ? validated
                          ? Iconsax.tick_circle
                          : Iconsax.profile_tick
                    : Iconsax.user,
                size: size * 0.26,
                color: occ
                    ? validated
                          ? _C.success
                          : _C.occupied
                    : _C.textHint,
              ),
              const SizedBox(height: 2),
              Text(
                '$seatNum',
                style: GoogleFonts.inter(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w700,
                  color: occ
                      ? validated
                            ? _C.success
                            : _C.occupied
                      : _C.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget seatRow(double seatSize, double gap, List<_SeatType> seats) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: seats.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : gap),
            child: seatTile(e.value, seatSize),
          );
        }).toList(),
      );
    }

    return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.car, size: 15, color: _C.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Denah Kursi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Depan',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _C.textHint,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: _C.border.withValues(alpha: 0.5)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final usableWidth = constraints.maxWidth - 2;
                    final seatSize = (usableWidth / 4.45).clamp(40.0, 64.0);
                    final gap = seatSize * 0.15;
                    return Column(
                      children: [
                        seatRow(seatSize, gap, [
                          _SeatType.driver,
                          _SeatType.empty,
                          _SeatType.empty,
                          _SeatType.seat(1),
                        ]),
                        SizedBox(height: gap),
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(
                            horizontal: seatSize * 0.3,
                            vertical: gap * 0.4,
                          ),
                          color: _C.border.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: gap * 0.4),
                        seatRow(seatSize, gap, [
                          _SeatType.seat(2),
                          _SeatType.aisle,
                          _SeatType.seat(3),
                          _SeatType.seat(4),
                        ]),
                        SizedBox(height: gap),
                        seatRow(seatSize, gap, [
                          _SeatType.seat(5),
                          _SeatType.seat(6),
                          _SeatType.seat(7),
                          _SeatType.seat(8),
                        ]),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belakang',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _C.textHint,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(_C.success, 'Validasi'),
                  const SizedBox(width: 16),
                  _legendItem(_C.occupied, 'Terisi'),
                  const SizedBox(width: 16),
                  _legendItem(_C.empty, 'Kosong'),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.06, delay: 400.ms, duration: 500.ms);
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  PASSENGER DETAIL BOTTOMSHEET
  // ─────────────────────────────────────────────────────
  void _showPassengerDetail(BuildContext context, _Passenger p) {
    final initials = p.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              p.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kursi ${p.seatNumber} • ${p.bookingCode}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _C.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: p.isValidated ? _C.successBg : _C.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    p.isValidated ? Iconsax.tick_circle : Iconsax.clock,
                    size: 16,
                    color: p.isValidated ? _C.success : _C.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.isValidated ? 'Sudah Validasi' : 'Belum Hadir',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.isValidated ? _C.success : _C.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  PASSENGER TILE
  // ─────────────────────────────────────────────────────
  Widget _buildPassengerTile(BuildContext context, _Passenger p, int index) {
    final initials = p.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: p.isValidated
                  ? _C.success.withValues(alpha: 0.3)
                  : _C.border.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.isValidated
                      ? _C.success.withValues(alpha: 0.1)
                      : _C.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.isValidated ? _C.success : _C.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kursi ${p.seatNumber} • ${p.bookingCode}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: p.isValidated ? _C.successBg : _C.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.isValidated ? Iconsax.tick_circle : Iconsax.clock,
                      size: 13,
                      color: p.isValidated ? _C.success : _C.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.isValidated ? 'Validasi' : 'Belum',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.isValidated ? _C.success : _C.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (550 + index * 60).ms, duration: 350.ms)
        .slideX(begin: 0.05, delay: (550 + index * 60).ms, duration: 350.ms);
  }

  // ─────────────────────────────────────────────────────
  //  SCAN FAB
  // ─────────────────────────────────────────────────────
  Widget _buildScanFAB(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: _C.primary,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.scan_barcode,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Scan Tiket',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(
          begin: 0.3,
          delay: 600.ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────
//  PASSENGER DATA (local, derived from BookingModel)
// ─────────────────────────────────────────────────────────
class _Passenger {
  final String name;
  final int seatNumber;
  final bool isValidated;
  final String bookingCode;
  final String bookingId;

  const _Passenger({
    required this.name,
    required this.seatNumber,
    required this.isValidated,
    required this.bookingCode,
    required this.bookingId,
  });
}

// ─────────────────────────────────────────────────────────
//  SEAT TYPE HELPER
// ─────────────────────────────────────────────────────────
class _SeatType {
  final String type;
  final int? seatNumber;

  const _SeatType._(this.type, [this.seatNumber]);

  static const driver = _SeatType._('driver');
  static const empty = _SeatType._('empty');
  static const aisle = _SeatType._('aisle');
  static _SeatType seat(int number) => _SeatType._('seat', number);

  bool get isDriver => type == 'driver';
  bool get isEmpty => type == 'empty';
  bool get isAisle => type == 'aisle';
  bool get isSeat => type == 'seat';
}
