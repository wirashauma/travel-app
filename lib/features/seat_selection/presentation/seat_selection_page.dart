import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/services/booking_service.dart';
import '../../checkout/presentation/checkout_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Navy / Amber / Clean Slate
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  // ── Seat state colors ──
  static const Color soldBg = Color(0xFFF1F5F9);
  static const Color soldBorder = Color(0xFFCBD5E1);
  static const Color soldText = Color(0xFF94A3B8);

  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingBorder = Color(0xFFFBBF24);
  static const Color pendingText = Color(0xFFB45309);

  static const Color selectedBg = Color(0xFF0F4C81);
  static const Color selectedBorder = Color(0xFF1A6BB5);

  // ── Car interior colors ──
  static const Color carBody = Color(0xFFF8FAFC);
  static const Color carBorder = Color(0xFFCBD5E1);
  static const Color carDashboard = Color(0xFFE2E8F0);
}

// ─────────────────────────────────────────────────────────
//  SEAT STATE — 4 visual states for each seat tile
// ─────────────────────────────────────────────────────────
enum SeatState { available, selected, pending, sold }

// ═══════════════════════════════════════════════════════════
//  SEAT SELECTION PAGE — Real-Time MPV/Innova 7-Seat Picker
//
//  FORMASI KURSI (Travel MPV/Innova):
//  ┌─────────────────────────────────────────────────┐
//  │ BARIS 1 (Depan):  [Kursi 1]  ---  [🎡 Supir]  │
//  │ BARIS 2 (Tengah): [Kursi 2] [Kursi 3] [Kursi 4]│
//  │ BARIS 3 (Belakang):[Kursi 5] [Kursi 6] [Kursi 7]│
//  └─────────────────────────────────────────────────┘
//
//  ARSITEKTUR "Timestamp Expiration":
//  StreamBuilder on bookings collection
//  → Client-side filter:
//    • paid/used   → SOLD    (abu-abu, disabled)
//    • pending+exp > now → PENDING (kuning, locked)
//    • pending+exp < now → AVAILABLE (expired!)
//    • cancelled   → IGNORE
//
//  CLEANUP: initState → cleanupExpiredBookings()
// ═══════════════════════════════════════════════════════════
class SeatSelectionPage extends StatefulWidget {
  final String fleetId;
  final String fleetName;
  final int totalSeats;
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;
  final int routePrice;
  final String routeSummary;
  final double totalDistance;
  final int totalDurationMinutes;

  const SeatSelectionPage({
    super.key,
    required this.fleetId,
    required this.fleetName,
    required this.totalSeats,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
    required this.routePrice,
    required this.routeSummary,
    required this.totalDistance,
    required this.totalDurationMinutes,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final Set<String> _selectedSeats = {};
  late final String _dateStr;

  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  @override
  void initState() {
    super.initState();
    _dateStr = DateFormat('dd MMM yyyy').format(widget.date);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    BookingService.cleanupExpiredBookings(
      fleetId: widget.fleetId,
      departureDate: _dateStr,
    );
  }

  // ─────────────────────────────────────────────────────
  //  DERIVE SEAT STATES — Client-side filtering
  // ─────────────────────────────────────────────────────
  Map<String, SeatState> _deriveSeatStates(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final states = <String, SeatState>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final docUserId = data['userId'] as String? ?? '';
      final seats =
          (data['selectedSeatLabels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (status == 'paid' ||
          status == 'validated' ||
          status == 'used' ||
          status == 'completed') {
        for (final seat in seats) {
          states[seat] = SeatState.sold;
        }
      } else if (status == 'pending') {
        final expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();

        if (expiryDate != null && expiryDate.isAfter(now)) {
          if (docUserId == currentUid) continue;

          for (final seat in seats) {
            if (states[seat] != SeatState.sold) {
              states[seat] = SeatState.pending;
            }
          }
        }
      }
    }

    return states;
  }

  // ─────────────────────────────────────────────────────
  //  TOGGLE SEAT — Select / deselect
  // ─────────────────────────────────────────────────────
  void _toggleSeat(String label, Map<String, SeatState> seatStates) {
    final state = seatStates[label];
    if (state == SeatState.sold || state == SeatState.pending) return;

    setState(() {
      if (_selectedSeats.contains(label)) {
        _selectedSeats.remove(label);
      } else {
        if (_selectedSeats.length < widget.passengers) {
          _selectedSeats.add(label);
        } else {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Maksimal ${widget.passengers} kursi untuk pemesanan ini',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: _C.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────
  //  GO TO CHECKOUT
  // ─────────────────────────────────────────────────────
  void _goToCheckout(Map<String, SeatState> seatStates) {
    final conflicted = _selectedSeats
        .where(
          (s) =>
              seatStates[s] == SeatState.sold ||
              seatStates[s] == SeatState.pending,
        )
        .toSet();

    if (conflicted.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kursi ${conflicted.join(", ")} sudah tidak tersedia!',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: _C.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      setState(() => _selectedSeats.removeAll(conflicted));
      return;
    }

    final sortedSeats = _selectedSeats.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          origin: widget.origin,
          destination: widget.destination,
          date: widget.date,
          passengers: _selectedSeats.length,
          routePrice: widget.routePrice,
          routeSummary: widget.routeSummary,
          totalDistance: widget.totalDistance,
          totalDurationMinutes: widget.totalDurationMinutes,
          fleetId: widget.fleetId,
          fleetName: widget.fleetName,
          availableSeats: widget.totalSeats,
          selectedSeats: sortedSeats,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('fleetId', isEqualTo: widget.fleetId)
            .where('departureDate', isEqualTo: _dateStr)
            .snapshots(),
        builder: (context, snapshot) {
          final seatStates = snapshot.hasData
              ? _deriveSeatStates(snapshot.data!)
              : <String, SeatState>{};

          // ── Auto-deselect seats snatched by others ──
          final snatched = _selectedSeats
              .where(
                (s) =>
                    seatStates[s] == SeatState.sold ||
                    seatStates[s] == SeatState.pending,
              )
              .toSet();

          if (snatched.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedSeats.removeAll(snatched));
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Kursi ${snatched.join(", ")} baru saja terisi. Silakan pilih ulang.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: _C.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
            });
          }

          return Column(
            children: [
              _buildAppBar(topPadding),
              _buildRouteInfo().animate().fadeIn(
                delay: 100.ms,
                duration: 400.ms,
              ),
              _buildLegend().animate().fadeIn(delay: 200.ms, duration: 400.ms),
              Expanded(child: _buildCarSeatMap(seatStates)),
              _buildBottomCTA(bottomPadding, seatStates),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────
  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 16),
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
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Kursi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.fleetName,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _C.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.people, size: 14, color: _C.primary),
                const SizedBox(width: 5),
                Text(
                  '${_selectedSeats.length}/${widget.passengers}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─────────────────────────────────────────────────
  //  ROUTE INFO
  // ─────────────────────────────────────────────────
  Widget _buildRouteInfo() {
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id_ID').format(widget.date);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Iconsax.location, size: 14, color: _C.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.origin} → ${widget.destination}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: _C.primary.withValues(alpha: 0.15),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 14, color: _C.primary),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  LEGEND — 4 visual states
  // ─────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Tersedia', _C.white, _C.border),
          const SizedBox(width: 14),
          _legendItem('Dipilih', _C.selectedBg, _C.selectedBorder),
          const SizedBox(width: 14),
          _legendItem('Dikunci', _C.pendingBg, _C.pendingBorder),
          const SizedBox(width: 14),
          _legendItem('Terjual', _C.soldBg, _C.soldBorder),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color fill, Color border) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _C.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  CAR SEAT MAP — MPV/Innova Interior Layout
  //
  //  ┌─────────────────────────────────────┐
  //  │         « Bagian Depan »            │
  //  │  ┌──────────┬──────────────────┐    │
  //  │  │ [Kursi 1]│    [🎡 Supir]   │    │
  //  │  ├──────────┴──────────────────┤    │
  //  │  │ [Kursi 2] [Kursi 3] [Kursi 4]   │
  //  │  ├─────────────────────────────┤    │
  //  │  │ [Kursi 5] [Kursi 6] [Kursi 7]   │
  //  │  └─────────────────────────────┘    │
  //  │      « Bagian Belakang / Bagasi »   │
  //  └─────────────────────────────────────┘
  // ─────────────────────────────────────────────────────
  Widget _buildCarSeatMap(Map<String, SeatState> seatStates) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Center(
        child:
            Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: _C.carBody,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: _C.carBorder, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: _C.carBorder.withValues(alpha: 0.3),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ═══ "Bagian Depan" Label + Windshield ═══
                      _buildFrontLabel(),

                      // ═══ BARIS 1: Kursi 1 + Supir ═══
                      _buildRow1Front(seatStates),

                      // ═══ Row divider ═══
                      _buildRowDivider(),

                      // ═══ BARIS 2: Kursi 2, 3, 4 ═══
                      _buildRow2Middle(seatStates),

                      // ═══ Row divider ═══
                      _buildRowDivider(),

                      // ═══ BARIS 3: Kursi 5, 6, 7 ═══
                      _buildRow3Back(seatStates),

                      // ═══ "Bagian Belakang / Bagasi" Label ═══
                      _buildRearLabel(),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.05, delay: 300.ms, duration: 500.ms),
      ),
    );
  }

  // ── "Bagian Depan" label with windshield effect ──
  Widget _buildFrontLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.carDashboard.withValues(alpha: 0.6), _C.carBody],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Windshield indicator
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: _C.carBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.arrow_up_2, size: 14, color: _C.textTertiary),
              const SizedBox(width: 6),
              Text(
                'BAGIAN DEPAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _C.textTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Iconsax.arrow_up_2, size: 14, color: _C.textTertiary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.fleetName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── BARIS 1: 1 Kursi Penumpang (Kiri) + Spacer + Supir (Kanan) ──
  Widget _buildRow1Front(Map<String, SeatState> seatStates) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Kursi 1 (kiri depan, di samping supir)
          Expanded(
            child: _buildSeat('1', seatStates)
                .animate()
                .fadeIn(delay: 350.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 350.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),

          // Spacer (lorong tengah)
          const SizedBox(width: 12),

          // Supir (kanan depan) — tidak bisa diklik
          Expanded(
            child: _buildDriverSeat()
                .animate()
                .fadeIn(delay: 380.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 380.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }

  // ── BARIS 2: 3 Kursi Sejajar (Kursi 2, 3, 4) ──
  Widget _buildRow2Middle(Map<String, SeatState> seatStates) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSeat('2', seatStates)
                .animate()
                .fadeIn(delay: 450.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 450.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSeat('3', seatStates)
                .animate()
                .fadeIn(delay: 480.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 480.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSeat('4', seatStates)
                .animate()
                .fadeIn(delay: 510.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 510.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }

  // ── BARIS 3: 3 Kursi Sejajar (Kursi 5, 6, 7) ──
  Widget _buildRow3Back(Map<String, SeatState> seatStates) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSeat('5', seatStates)
                .animate()
                .fadeIn(delay: 580.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 580.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSeat('6', seatStates)
                .animate()
                .fadeIn(delay: 610.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 610.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSeat('7', seatStates)
                .animate()
                .fadeIn(delay: 640.ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  delay: 640.ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }

  // ── Row divider (visual separator between seat rows) ──
  Widget _buildRowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.carBorder.withValues(alpha: 0),
                    _C.carBorder.withValues(alpha: 0.5),
                    _C.carBorder.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── "Bagian Belakang / Bagasi" label ──
  Widget _buildRearLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.carBody, _C.carDashboard.withValues(alpha: 0.4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.arrow_down_1, size: 14, color: _C.textTertiary),
              const SizedBox(width: 6),
              Text(
                'BAGIAN BELAKANG / BAGASI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _C.textTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Iconsax.arrow_down_1, size: 14, color: _C.textTertiary),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: _C.carBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  buildSeat — Reusable Real-Time Seat Widget
  //
  //  Menerima nomor kursi (String) dan map seatStates
  //  dari StreamBuilder. Menentukan state visual:
  //   • PUTIH/OUTLINE BIRU → Available (bisa diklik)
  //   • TRUST BLUE → Dipilih user saat ini
  //   • ABU-ABU/MERAH → Terkunci/Terjual (disabled)
  // ─────────────────────────────────────────────────────
  Widget _buildSeat(String seatNumber, Map<String, SeatState> seatStates) {
    final isSelected = _selectedSeats.contains(seatNumber);
    SeatState state;
    if (isSelected) {
      state = SeatState.selected;
    } else {
      state = seatStates[seatNumber] ?? SeatState.available;
    }

    return _SeatWidget(
      label: seatNumber,
      state: state,
      onTap: () => _toggleSeat(seatNumber, seatStates),
    );
  }

  // ── Driver seat (non-interactive, display only) ──
  Widget _buildDriverSeat() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _C.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _C.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Steering wheel icon
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _C.primary.withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SUPIR',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: _C.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  BOTTOM CTA — Price summary + Continue button
  // ─────────────────────────────────────────────────
  Widget _buildBottomCTA(
    double bottomPadding,
    Map<String, SeatState> seatStates,
  ) {
    final totalPrice = widget.routePrice * _selectedSeats.length;
    final isReady = _selectedSeats.length == widget.passengers;

    return Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
          decoration: BoxDecoration(
            color: _C.white,
            border: const Border(
              top: BorderSide(color: _C.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedSeats.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _C.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.driver, size: 16, color: _C.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kursi: ${(_selectedSeats.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)))).join(", ")}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Harga',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _C.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtPrice(totalPrice),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isReady
                          ? () => _goToCheckout(seatStates)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        disabledBackgroundColor: _C.soldBorder,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isReady
                                ? 'Lanjut'
                                : 'Pilih ${widget.passengers - _selectedSeats.length} lagi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isReady) ...[
                            const SizedBox(width: 8),
                            const Icon(Iconsax.arrow_right_3, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, delay: 400.ms, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  SEAT WIDGET — Individual seat tile with 4 visual states
//
//  • PUTIH / OUTLINE BIRU  → Available (bisa diklik)
//  • TRUST BLUE (solid)    → Dipilih oleh user saat ini
//  • KUNING / AMBER        → Dikunci (pending user lain)
//  • ABU-ABU               → Terjual (disabled)
// ═══════════════════════════════════════════════════════════
class _SeatWidget extends StatelessWidget {
  final String label;
  final SeatState state;
  final VoidCallback onTap;

  const _SeatWidget({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    Color iconColor;

    switch (state) {
      case SeatState.available:
        bgColor = _C.white;
        borderColor = _C.primary.withValues(alpha: 0.25);
        textColor = _C.textSecondary;
        icon = Iconsax.driver;
        iconColor = _C.primary.withValues(alpha: 0.35);
        break;
      case SeatState.selected:
        bgColor = _C.selectedBg;
        borderColor = _C.selectedBorder;
        textColor = Colors.white;
        icon = Iconsax.tick_circle;
        iconColor = Colors.white.withValues(alpha: 0.8);
        break;
      case SeatState.pending:
        bgColor = _C.pendingBg;
        borderColor = _C.pendingBorder;
        textColor = _C.pendingText;
        icon = Iconsax.lock;
        iconColor = _C.pendingText.withValues(alpha: 0.6);
        break;
      case SeatState.sold:
        bgColor = _C.soldBg;
        borderColor = _C.soldBorder;
        textColor = _C.soldText;
        icon = Iconsax.close_circle;
        iconColor = _C.soldText;
        break;
    }

    final isTappable =
        state == SeatState.available || state == SeatState.selected;

    return GestureDetector(
      onTap: isTappable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 72,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: state == SeatState.selected ? 2 : 1.5,
          ),
          boxShadow: state == SeatState.selected
              ? [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
