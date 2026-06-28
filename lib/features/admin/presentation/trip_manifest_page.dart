// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'admin_dashboard_page.dart';
import 'qr_scanner_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (consistent with app)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
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
//  TRIP MANIFEST PAGE — Detail Perjalanan & Daftar Penumpang
// ═══════════════════════════════════════════════════════════
class TripManifestPage extends StatefulWidget {
  final TripData trip;

  const TripManifestPage({super.key, required this.trip});

  @override
  State<TripManifestPage> createState() => _TripManifestPageState();
}

class _TripManifestPageState extends State<TripManifestPage> {
  late TripData _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  // ── Seat occupied check ──
  bool _isSeatOccupied(int seatNumber) {
    return _trip.passengers.any((p) => p.seatNumber == seatNumber);
  }

  PassengerData? _getPassengerBySeat(int seatNumber) {
    final matches = _trip.passengers.where((p) => p.seatNumber == seatNumber);
    return matches.isEmpty ? null : matches.first;
  }

  void _updateTripStatus(TripStatus newStatus) {
    setState(() {
      _trip = TripData(
        id: _trip.id,
        origin: _trip.origin,
        destination: _trip.destination,
        departureTime: _trip.departureTime,
        vehiclePlate: _trip.vehiclePlate,
        vehicleName: _trip.vehicleName,
        totalSeats: _trip.totalSeats,
        bookedSeats: _trip.bookedSeats,
        status: newStatus,
        passengers: _trip.passengers,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status diubah ke "${newStatus.label}"',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  void _onPassengerValidated(
    String ticketCode,
    String passengerName,
    int seatNumber,
  ) {
    setState(() {
      final updatedPassengers = _trip.passengers.map((p) {
        if (p.ticketCode == ticketCode) {
          return PassengerData(
            name: p.name,
            seatNumber: p.seatNumber,
            isValidated: true,
            ticketCode: p.ticketCode,
          );
        }
        return p;
      }).toList();

      _trip = TripData(
        id: _trip.id,
        origin: _trip.origin,
        destination: _trip.destination,
        departureTime: _trip.departureTime,
        vehiclePlate: _trip.vehiclePlate,
        vehicleName: _trip.vehicleName,
        totalSeats: _trip.totalSeats,
        bookedSeats: _trip.bookedSeats,
        status: _trip.status,
        passengers: updatedPassengers,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final w = mq.size.width;
    final isSmall = w < 360;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── APP BAR ──
              SliverToBoxAdapter(child: _buildAppBar(topPad)),

              // ── ROUTE HEADER CARD ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _buildRouteCard(isSmall),
                ),
              ),

              // ── STATUS ACTION BUTTONS ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildStatusActions(),
                ),
              ),

              // ── SEAT LAYOUT ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildSeatLayout(isSmall),
                ),
              ),

              // ── PASSENGER LIST HEADER ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Icon(Iconsax.people, size: 18, color: _C.primary),
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
                          '${_trip.passengers.length} orang',
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
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPassengerTile(_trip.passengers[index], index),
                    childCount: _trip.passengers.length,
                  ),
                ),
              ),
            ],
          ),

          // ── FAB — Scan QR ──
          Positioned(bottom: bottomPad + 24, right: 20, child: _buildScanFAB()),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────
  Widget _buildAppBar(double topPad) {
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
          // Back button
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
                  _trip.id,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _C.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _trip.status.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_trip.status.icon, size: 13, color: _trip.status.color),
                const SizedBox(width: 4),
                Text(
                  _trip.status.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _trip.status.color,
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
  Widget _buildRouteCard(bool isSmall) {
    final time = DateFormat('HH:mm').format(_trip.departureTime);
    final date = DateFormat(
      'EEEE, dd MMM yyyy',
      'id_ID',
    ).format(_trip.departureTime);

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
                  // Origin
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
                          _trip.origin,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isSmall ? 15 : 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
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
                  // Destination
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
                          _trip.destination,
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
                    _buildInfoChip(Iconsax.clock, time),
                    _buildInfoChipText(Iconsax.calendar_1, date),
                    _buildInfoChip(Iconsax.car, _trip.vehiclePlate),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChipText(IconData icon, String text) {
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
  //  STATUS ACTION BUTTONS
  // ─────────────────────────────────────────────────────
  Widget _buildStatusActions() {
    return Row(
      children: [
        if (_trip.status == TripStatus.menunggu)
          Expanded(
            child: _ActionButton(
              label: 'Mulai Perjalanan',
              icon: Iconsax.send_2,
              color: _C.primary,
              onTap: () => _updateTripStatus(TripStatus.berangkat),
            ),
          ),
        if (_trip.status == TripStatus.berangkat) ...[
          Expanded(
            child: _ActionButton(
              label: 'Selesai',
              icon: Iconsax.tick_circle,
              color: _C.success,
              onTap: () => _updateTripStatus(TripStatus.selesai),
            ),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Batal',
            icon: Iconsax.close_circle,
            color: _C.error,
            isOutlined: true,
            onTap: () => _updateTripStatus(TripStatus.dibatalkan),
          ),
        ],
        if (_trip.status == TripStatus.selesai ||
            _trip.status == TripStatus.dibatalkan)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _trip.status.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_trip.status.icon, size: 18, color: _trip.status.color),
                  const SizedBox(width: 8),
                  Text(
                    'Perjalanan ${_trip.status.label}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _trip.status.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  SEAT LAYOUT — 8 seats + driver (matching booking_seat)
  //   Row 1: [Driver]         [Seat 1]
  //   Row 2: [Seat 2] [─] [Seat 3] [Seat 4]
  //   Row 3: [Seat 5] [Seat 6] [Seat 7] [Seat 8]
  // ─────────────────────────────────────────────────────
  Widget _buildSeatLayout(bool isSmall) {
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
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.car, size: 15, color: _C.textTertiary),
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

              // Seat container
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
                        // Row 1: Driver + empty + empty + Seat1
                        _buildSeatRow(seatSize, gap, [
                          _SeatType.driver,
                          _SeatType.empty,
                          _SeatType.empty,
                          _SeatType.seat(1),
                        ]),
                        SizedBox(height: gap),
                        // Aisle line
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(
                            horizontal: seatSize * 0.3,
                            vertical: gap * 0.4,
                          ),
                          color: _C.border.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: gap * 0.4),
                        // Row 2: Seat2 + aisle + Seat3 + Seat4
                        _buildSeatRow(seatSize, gap, [
                          _SeatType.seat(2),
                          _SeatType.aisle,
                          _SeatType.seat(3),
                          _SeatType.seat(4),
                        ]),
                        SizedBox(height: gap),
                        // Row 3: Seat5 + Seat6 + Seat7 + Seat8
                        _buildSeatRow(seatSize, gap, [
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

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(_C.occupied, 'Terisi'),
                  const SizedBox(width: 20),
                  _buildLegendItem(_C.empty, 'Kosong'),
                  const SizedBox(width: 20),
                  _buildLegendItem(_C.textHint, 'Driver'),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.06, delay: 400.ms, duration: 500.ms);
  }

  Widget _buildSeatRow(double seatSize, double gap, List<_SeatType> seats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: seats.asMap().entries.map((entry) {
        final i = entry.key;
        final seat = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
          child: _buildSeatTile(seat, seatSize),
        );
      }).toList(),
    );
  }

  Widget _buildSeatTile(_SeatType type, double size) {
    if (type.isEmpty) {
      return SizedBox(width: size, height: size);
    }

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
    final occupied = _isSeatOccupied(seatNum);
    final passenger = _getPassengerBySeat(seatNum);

    return GestureDetector(
      onTap: passenger != null ? () => _showPassengerDetail(passenger) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: occupied ? _C.occupied.withValues(alpha: 0.12) : _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: occupied ? _C.occupied : _C.empty,
            width: occupied ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              occupied ? Iconsax.profile_tick : Iconsax.user,
              size: size * 0.26,
              color: occupied ? _C.occupied : _C.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              '$seatNum',
              style: GoogleFonts.inter(
                fontSize: size * 0.16,
                fontWeight: FontWeight.w700,
                color: occupied ? _C.occupied : _C.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color == _C.occupied
                ? color.withValues(alpha: 0.12)
                : color == _C.empty
                ? _C.bg
                : color.withValues(alpha: 0.15),
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

  void _showPassengerDetail(PassengerData passenger) {
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  passenger.name.split(' ').map((w) => w[0]).take(2).join(),
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
              passenger.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kursi ${passenger.seatNumber} • ${passenger.ticketCode}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _C.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: passenger.isValidated ? _C.successBg : _C.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passenger.isValidated ? Iconsax.tick_circle : Iconsax.clock,
                    size: 16,
                    color: passenger.isValidated ? _C.success : _C.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    passenger.isValidated ? 'Sudah Validasi' : 'Belum Hadir',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: passenger.isValidated ? _C.success : _C.warning,
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
  Widget _buildPassengerTile(PassengerData passenger, int index) {
    final initials = passenger.name
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
              color: passenger.isValidated
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
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: passenger.isValidated
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
                      color: passenger.isValidated ? _C.success : _C.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kursi ${passenger.seatNumber} • ${passenger.ticketCode}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Validation status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: passenger.isValidated ? _C.successBg : _C.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      passenger.isValidated
                          ? Iconsax.tick_circle
                          : Iconsax.clock,
                      size: 13,
                      color: passenger.isValidated ? _C.success : _C.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      passenger.isValidated ? 'Validasi' : 'Belum',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: passenger.isValidated ? _C.success : _C.warning,
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
  Widget _buildScanFAB() {
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
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerPage()),
                );
                if (result != null && mounted) {
                  _onPassengerValidated(
                    result['ticketCode'] as String,
                    result['name'] as String,
                    result['seatNumber'] as int,
                  );
                }
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
//  ACTION BUTTON WIDGET
// ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isOutlined ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
