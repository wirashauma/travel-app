import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unused_field, unused_import, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state_widget.dart';
import '../../seat_selection/presentation/seat_selection_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Navy / Teal / Clean Slate
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFEF4444);
}

// ═══════════════════════════════════════════════════════════
//  SELECT FLEET PAGE — Real-time StreamBuilder on `fleets`
// ═══════════════════════════════════════════════════════════
class SelectFleetPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;
  final int routePrice;
  final String routeSummary;
  final double totalDistance;
  final int totalDurationMinutes;

  const SelectFleetPage({
    super.key,
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
  State<SelectFleetPage> createState() => _SelectFleetPageState();
}

class _SelectFleetPageState extends State<SelectFleetPage> {
  final bool _isBooking = false;
  String _selectedTime = '10:00 WIB';

  // ── Firestore ref ──
  static final _fleetsRef = FirebaseFirestore.instance
      .collection('fleets')
      .orderBy('name');

  // ── Helpers ──
  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m menit';
    if (m == 0) return '$h jam';
    return '$h jam $m menit';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // ── Time Selector ──
  Widget _buildTimeSelector() {
    final times = [
      ('10:00 WIB', 'Pagi', Iconsax.sun_1),
      ('14:00 WIB', 'Siang', Iconsax.sun_fog),
      ('20:00 WIB', 'Malam', Iconsax.moon),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: times.map((t) {
          final isSelected = _selectedTime == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = t.$1;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _C.primary : _C.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _C.primary : _C.border,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _C.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 16,
                      color: isSelected ? Colors.white : _C.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.$1.split(' ')[0],
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Navigate to Seat Selection ──
  void _goToSeatSelection(String fleetId, String fleetName, int totalSeats, String departureTime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionPage(
          fleetId: fleetId,
          fleetName: fleetName,
          totalSeats: totalSeats,
          origin: widget.origin,
          destination: widget.destination,
          date: widget.date,
          passengers: widget.passengers,
          routePrice: widget.routePrice,
          routeSummary: widget.routeSummary,
          totalDistance: widget.totalDistance,
          totalDurationMinutes: widget.totalDurationMinutes,
          departureTime: departureTime,
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

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ═══ APP BAR ════════════════════════════
          _buildAppBar(topPadding),

          // ═══ ROUTE INFO STRIP ═══════════════════
          _buildRouteStrip().animate().fadeIn(delay: 100.ms, duration: 400.ms),

          // ═══ TIME SELECTOR ══════════════════════
          _buildTimeSelector().animate().fadeIn(delay: 150.ms, duration: 400.ms),

          // ═══ FLEET LIST — StreamBuilder ═════════
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fleetsRef.snapshots(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.primary),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                // Filter route & time client-side (safe, robust fallback to avoid Firestore compound index failures)
                final routeDocs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fOrigin = data['origin'] as String? ?? '';
                  final fDest = data['destination'] as String? ?? '';
                  final fTimes = List<String>.from(data['departureTimes'] ?? ['10:00 WIB', '14:00 WIB', '20:00 WIB']);
                  return fOrigin.toLowerCase() == widget.origin.toLowerCase() &&
                         fDest.toLowerCase() == widget.destination.toLowerCase() &&
                         fTimes.contains(_selectedTime);
                }).toList();

                if (routeDocs.isEmpty) {
                  return _buildEmptyState();
                }

                // Fleet cards
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: routeDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final doc = routeDocs[index];
                    final d = doc.data() as Map<String, dynamic>;
                    return _FleetCard(
                          fleetId: doc.id,
                          name: d['name'] as String? ?? 'Armada',
                          imageUrl: d['imageUrl'] as String? ?? '',
                          totalSeats: (d['totalSeats'] as num?)?.toInt() ?? 0,
                          description: d['description'] as String? ?? '',
                          routePrice: widget.routePrice,
                          passengers: widget.passengers,
                          formatPrice: _fmtPrice,
                          isBooking: _isBooking,
                          departureDate: widget.date,
                          selectedTime: _selectedTime,
                          onBook: () => _goToSeatSelection(
                            doc.id,
                            d['name'] as String? ?? 'Armada',
                            (d['totalSeats'] as num?)?.toInt() ?? 0,
                            _selectedTime,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (200 + index * 80).ms, duration: 450.ms)
                        .slideY(
                          begin: 0.06,
                          delay: (200 + index * 80).ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
            ),
          ),
        ],
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
                  'Pilih Armada',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.origin} → ${widget.destination}',
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
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ── Route Info Strip ──────────────────────────────
  Widget _buildRouteStrip() {
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id_ID').format(widget.date);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.routing_2, size: 14, color: _C.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.routeSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _stripChip(Iconsax.calendar_1, dateStr),
                    _stripChip(Iconsax.people, '${widget.passengers} pax'),
                    _stripChip(
                      Iconsax.clock,
                      _fmtDuration(widget.totalDurationMinutes),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _fmtPrice(widget.routePrice * widget.passengers),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _C.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stripChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _C.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Empty State ─────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.textTertiary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Iconsax.car,
              size: 36,
              color: _C.textTertiary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Armada',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Armada belum ditambahkan oleh Super Admin.',
            style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Error State ─────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: _C.danger),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Armada',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FLEET CARD — shows fleet info, price, seats, book button
//
//  ARSITEKTUR: Menghitung kursi tersedia secara REAL-TIME
//  dari koleksi `bookings` — BUKAN dari field `availableSeats`
//  di dokumen `fleets`. Jika booking dihapus manual di
//  Firebase Console, jumlah kursi otomatis update.
// ═══════════════════════════════════════════════════════════
class _FleetCard extends StatelessWidget {
  final String fleetId;
  final String name;
  final String imageUrl;
  final int totalSeats;
  final String description;
  final int routePrice;
  final int passengers;
  final String Function(int) formatPrice;
  final bool isBooking;
  final DateTime departureDate;
  final String selectedTime;
  final VoidCallback onBook;

  const _FleetCard({
    required this.fleetId,
    required this.name,
    required this.imageUrl,
    required this.totalSeats,
    required this.description,
    required this.routePrice,
    required this.passengers,
    required this.formatPrice,
    required this.isBooking,
    required this.departureDate,
    required this.selectedTime,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    // ── StreamBuilder: hitung kursi terpakai dari bookings ──
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('fleetId', isEqualTo: fleetId)
          .where('status', whereIn: ['pending', 'paid', 'validated', 'used'])
          .snapshots(),
      builder: (context, bookingSnap) {
        int bookedSeatCount = 0;
        if (bookingSnap.hasData) {
          final targetDate = DateFormat('dd MMM yyyy').format(departureDate);
          for (final doc in bookingSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final status = d['status'] as String? ?? '';
            final depDate = d['departureDate'] as String? ?? '';
            final depTime = d['departureTime'] as String? ?? '';
            if (depDate == targetDate &&
                depTime == selectedTime &&
                (status == 'pending' || status == 'paid' || status == 'validated' || status == 'used' || status == 'completed')) {
              bookedSeatCount += (d['seatsBooked'] as num?)?.toInt() ?? 0;
            }
          }
        }

        final availableSeats = (totalSeats - bookedSeatCount).clamp(
          0,
          totalSeats,
        );
        final hasEnoughSeats = availableSeats >= passengers;
        final isLowSeat = availableSeats > 0 && availableSeats <= 3;

        return Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F4C81).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Fleet Image ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _C.inputFill,
                            child: const Center(
                              child: Icon(
                                Iconsax.car,
                                size: 48,
                                color: _C.textHint,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: _C.inputFill,
                          child: const Center(
                            child: Icon(
                              Iconsax.car,
                              size: 48,
                              color: _C.textHint,
                            ),
                          ),
                        ),
                ),
              ),

              // ── Fleet Info ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Seat badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _C.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: availableSeats == 0
                                ? _C.danger.withValues(alpha: 0.08)
                                : isLowSeat
                                ? const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.08)
                                : _C.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.people,
                                size: 12,
                                color: availableSeats == 0
                                    ? _C.danger
                                    : isLowSeat
                                    ? const Color(0xFFF59E0B)
                                    : _C.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$availableSeats/$totalSeats kursi',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: availableSeats == 0
                                      ? _C.danger
                                      : isLowSeat
                                      ? const Color(0xFFF59E0B)
                                      : _C.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: _C.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Divider
                    Container(height: 1, color: _C.borderLight),

                    const SizedBox(height: 14),

                    // Price + Book button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total ($passengers pax)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatPrice(routePrice * passengers),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _C.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Book button
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: hasEnoughSeats && !isBooking
                                ? onBook
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasEnoughSeats
                                  ? _C.primary
                                  : _C.border,
                              foregroundColor: hasEnoughSeats
                                  ? Colors.white
                                  : _C.textHint,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isBooking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        hasEnoughSeats
                                            ? 'Pesan'
                                            : 'Kuota Penuh',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (hasEnoughSeats) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Iconsax.arrow_right_3,
                                          size: 15,
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }, // StreamBuilder builder
    ); // StreamBuilder
  }
}
