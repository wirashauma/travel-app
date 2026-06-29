import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/booking_model.dart';
import 'ticket_scanner_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / Enterprise
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color error = Color(0xFFDC2626);
}

// ═══════════════════════════════════════════════════════════
//  FLEET MANIFEST PAGE — Passenger Manifest for a Specific Fleet
//
//  StreamBuilder: bookings where fleetId == X
//    AND status IN ['paid', 'validated', 'used']
//
//  Features:
//  • Real-time passenger list with 3-state visual
//  • Stats row: total, paid, validated, boarded
//  • Floating "Scan QR Tiket" button → TicketScannerPage
// ═══════════════════════════════════════════════════════════
class FleetManifestPage extends StatefulWidget {
  final String fleetId;
  final String fleetName;
  final String vehicleType;
  final String origin;
  final String destination;
  final String? departureTime;

  const FleetManifestPage({
    super.key,
    required this.fleetId,
    required this.fleetName,
    this.vehicleType = '',
    this.origin = '',
    this.destination = '',
    this.departureTime,
  });

  @override
  State<FleetManifestPage> createState() => _FleetManifestPageState();
}

class _FleetManifestPageState extends State<FleetManifestPage> {
  late String _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.departureTime ?? '10:00 WIB';
  }

  String _fmtPrice(int price) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Widget _buildTimeFilterSelector() {
    final times = [
      ('10:00 WIB', 'Pagi', Iconsax.sun_1),
      ('14:00 WIB', 'Siang', Iconsax.sun_fog),
      ('20:00 WIB', 'Malam', Iconsax.moon),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.borderLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: times.map((t) {
          final isSelected = _selectedTime == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = t.$1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _C.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _C.primary.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.$3,
                      size: 14,
                      color: isSelected ? Colors.white : _C.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.$2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _C.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('fleetId', isEqualTo: widget.fleetId)
            .where('status', whereIn: ['paid', 'validated', 'used'])
            .snapshots(),
        builder: (context, snapshot) {
          final bookingDocs = snapshot.data?.docs ?? [];
          final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());
          final bookings = bookingDocs
              .map((d) => BookingModel.fromFirestore(d))
              .where((b) => b.origin == widget.origin &&
                            b.destination == widget.destination &&
                            b.departureDate == todayStr &&
                            b.departureTime == _selectedTime)
              .toList();

          final paidCount = bookings
              .where((b) => b.status == BookingStatus.paid)
              .length;
          final validatedCount = bookings
              .where((b) => b.status == BookingStatus.validated)
              .length;
          final completedCount = bookings
              .where((b) => b.status == BookingStatus.used)
              .length;

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── APP BAR ──
                  SliverToBoxAdapter(child: _buildAppBar(context, topPad)),

                  // ── FLEET INFO CARD ──
                  SliverToBoxAdapter(child: _buildFleetInfo()),

                  // ── TIME FILTER SELECTOR ──
                  if (widget.departureTime == null)
                    SliverToBoxAdapter(child: _buildTimeFilterSelector()),

                  // ── STATS ROW ──
                  SliverToBoxAdapter(
                    child: _buildStatsRow(
                      isSmall,
                      total: bookings.length,
                      paid: paidCount,
                      validated: validatedCount,
                      completed: completedCount,
                    ),
                  ),

                  // ── SECTION LABEL ──
                  SliverToBoxAdapter(
                    child: _buildSectionLabel(bookings.length),
                  ),

                  // ── LOADING ──
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      bookings.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: _C.primary),
                      ),
                    )
                  // ── ERROR ──
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.warning_2, size: 48, color: _C.error),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat data',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // ── EMPTY ──
                  else if (bookings.isEmpty)
                    SliverFillRemaining(child: _buildEmptyPassenger())
                  // ── PASSENGER LIST ──
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final booking = bookings[index];
                          return _PassengerCard(
                            booking: booking,
                            index: index,
                            fmtPrice: _fmtPrice,
                          );
                        }, childCount: bookings.length),
                      ),
                    ),
                ],
              ),

              // ── FLOATING SCAN BUTTON ──
              Positioned(
                bottom: bottomPad + 20,
                left: 20,
                right: 20,
                child: _buildScanButton(context),
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
  Widget _buildAppBar(BuildContext context, double topPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 20, 16),
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
                  'Manifest Penumpang',
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
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─────────────────────────────────────────────────────
  //  FLEET INFO CARD
  // ─────────────────────────────────────────────────────
  Widget _buildFleetInfo() {
    final route = (widget.origin.isNotEmpty && widget.destination.isNotEmpty)
        ? '${widget.origin} → ${widget.destination}'
        : '';

    return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.successBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.car, size: 22, color: _C.success),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fleetName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.success,
                        ),
                      ),
                      if (widget.vehicleType.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.vehicleType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.textTertiary,
                          ),
                        ),
                      ],
                      if (route.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          route,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                        ),
                      ],
                      if (widget.departureTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Iconsax.clock, size: 13, color: _C.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Jadwal: ${widget.departureTime}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _C.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _C.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.08, delay: 150.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  STATS ROW (Unified Single Card with Dividers)
  // ─────────────────────────────────────────────────────
  Widget _buildStatsRow(
    bool isSmall, {
    required int total,
    required int paid,
    required int validated,
    required int completed,
  }) {
    final stats = [
      _StatItem(
        icon: Iconsax.people,
        label: 'Total',
        value: '$total',
        color: _C.primary,
        bgColor: _C.primary.withValues(alpha: 0.08),
      ),
      _StatItem(
        icon: Iconsax.ticket_2,
        label: 'Paid',
        value: '$paid',
        color: _C.warning,
        bgColor: _C.warningBg,
      ),
      _StatItem(
        icon: Iconsax.shield_tick,
        label: 'Validated',
        value: '$validated',
        color: _C.info,
        bgColor: _C.infoBg,
      ),
      _StatItem(
        icon: Iconsax.tick_circle,
        label: 'Boarded',
        value: '$completed',
        color: _C.success,
        bgColor: _C.successBg,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: stats.asMap().entries.map((entry) {
              final i = entry.key;
              final stat = entry.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: stat.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(stat.icon, size: 16, color: stat.color),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            stat.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isSmall ? 15 : 18,
                              fontWeight: FontWeight.w800,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat.label,
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 10.5 : 12,
                              fontWeight: FontWeight.w600,
                              color: _C.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (i < stats.length - 1)
                      Container(
                        width: 1,
                        height: 36,
                        color: _C.border.withValues(alpha: 0.6),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  SECTION LABEL
  // ─────────────────────────────────────────────────────
  Widget _buildSectionLabel(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            'Daftar Penumpang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count tiket',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  EMPTY PASSENGER STATE
  // ─────────────────────────────────────────────────────
  Widget _buildEmptyPassenger() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.people, size: 56, color: _C.textHint),
          const SizedBox(height: 16),
          Text(
            'Belum ada penumpang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tiket yang sudah dibayar akan muncul di sini',
            style: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  FLOATING SCAN BUTTON
  // ─────────────────────────────────────────────────────
  Widget _buildScanButton(BuildContext context) {
    return SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TicketScannerPage()),
              );
            },
            icon: const Icon(Iconsax.scan_barcode, size: 20),
            label: Text(
              'Scan QR Tiket',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.teal,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: _C.teal.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.3, delay: 500.ms, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  PASSENGER CARD — Real-Time Manifest Item
//
//  3-State Visual:
//  • paid      → white bg, yellow clock, "Belum Check-in"
//  • validated → blue bg, shield icon, "Tervalidasi"
//  • used      → green bg, check icon, "Sudah Naik"
// ═══════════════════════════════════════════════════════════
class _PassengerCard extends StatelessWidget {
  final BookingModel booking;
  final int index;
  final String Function(int) fmtPrice;

  const _PassengerCard({
    required this.booking,
    required this.index,
    required this.fmtPrice,
  });

  Future<void> _openGoogleMaps(BuildContext context, BookingModel booking) async {
    final lat = booking.pickupLatitude;
    final lng = booking.pickupLongitude;
    final addr = booking.pickupAddress;

    if ((lat == null || lng == null) && (addr == null || addr.isEmpty)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber 100
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  color: Color(0xFFD97706), // Amber 700
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lokasi Tidak Tersedia',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF0F172A), // Slate 900
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Penumpang ini belum menentukan alamat penjemputan mereka. Silakan hubungi penumpang secara langsung untuk koordinasi lokasi.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569), // Slate 600
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mengerti',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Uri url;
    if (lat != null && lng != null) {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr!)}');
    }

    try {
      // Modern launch pattern: directly trigger external launch to bypass package visibility queries checks
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to defaults (system browser / maps application)
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka peta: $e'),
            backgroundColor: _C.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = booking.status == BookingStatus.used;
    final isValidated = booking.status == BookingStatus.validated;

    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    final Color cardBg;
    final Color borderColor;
    final Color nameColor;
    final TextDecoration nameDecoration;

    if (isUsed) {
      statusLabel = 'Sudah Naik';
      statusColor = _C.success;
      statusBg = _C.successBg;
      statusIcon = Iconsax.tick_circle;
      cardBg = const Color(0xFFF0FDF4);
      borderColor = _C.success.withValues(alpha: 0.35);
      nameColor = _C.success;
      nameDecoration = TextDecoration.lineThrough;
    } else if (isValidated) {
      statusLabel = 'Tervalidasi';
      statusColor = _C.info;
      statusBg = _C.infoBg;
      statusIcon = Iconsax.shield_tick;
      cardBg = const Color(0xFFF0F9FF);
      borderColor = _C.info.withValues(alpha: 0.35);
      nameColor = _C.info;
      nameDecoration = TextDecoration.none;
    } else {
      statusLabel = 'Belum Check-in';
      statusColor = _C.warning;
      statusBg = _C.warningBg;
      statusIcon = Iconsax.clock;
      cardBg = _C.card;
      borderColor = _C.border.withValues(alpha: 0.6);
      nameColor = _C.textPrimary;
      nameDecoration = TextDecoration.none;
    }

    final seatLabel = booking.seatNumbers.isNotEmpty
        ? booking.seatNumbers.map((s) => 'No. $s').join(', ')
        : '${booking.seatsBooked} kursi';

    return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: (isUsed || isValidated) ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUsed
                    ? _C.success.withValues(alpha: 0.08)
                    : isValidated
                    ? _C.info.withValues(alpha: 0.08)
                    : _C.primary.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top: Name + Status badge ──
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isUsed
                            ? _C.success.withValues(alpha: 0.12)
                            : isValidated
                            ? _C.info.withValues(alpha: 0.12)
                            : _C.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isUsed
                            ? const Icon(
                                Iconsax.tick_circle,
                                size: 20,
                                color: _C.success,
                              )
                            : isValidated
                            ? Icon(
                                Iconsax.shield_tick,
                                size: 20,
                                color: _C.info,
                              )
                            : Text(
                                booking.userName.isNotEmpty
                                    ? booking.userName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
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
                            booking.userName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: nameColor,
                              decoration: nameDecoration,
                              decorationColor: _C.success.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Kode: ${booking.bookingCode}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _C.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Route row (Premium boarding pass style with High Contrast Connector) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? _C.success.withValues(alpha: 0.04)
                        : isValidated
                        ? _C.info.withValues(alpha: 0.04)
                        : _C.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASAL',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _C.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.origin,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isUsed ? _C.textSecondary : _C.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Neutral High Contrast gray arrow connector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _C.textTertiary,
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 1,
                              color: _C.border,
                            ),
                            const Icon(
                              Iconsax.arrow_right_1,
                              size: 14,
                              color: _C.textSecondary,
                            ),
                            Container(
                              width: 20,
                              height: 1,
                              color: _C.border,
                            ),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TUJUAN',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _C.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.destination,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isUsed ? _C.textSecondary : _C.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Bottom: Seat + Date + Price ──
                Row(
                  children: [
                    _InfoChip(
                      icon: Iconsax.ticket,
                      label: seatLabel,
                      color: isUsed
                          ? _C.success
                          : isValidated
                          ? _C.info
                          : _C.primary,
                    ),
                    if (isUsed || isValidated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? _C.success.withValues(alpha: 0.12)
                              : _C.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isUsed
                                ? _C.success.withValues(alpha: 0.25)
                                : _C.info.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.verify,
                              size: 10,
                              color: isUsed ? _C.success : _C.info,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terisi',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isUsed ? _C.success : _C.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Iconsax.calendar_1,
                      label: booking.departureDate,
                      color: _C.textSecondary,
                    ),
                    const Spacer(),
                    Text(
                      fmtPrice(booking.totalPrice),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isUsed
                            ? _C.success
                            : isValidated
                            ? _C.info
                            : _C.primary,
                      ),
                    ),
                  ],
                ),

                // ── Pickup Address Card (Clean, Premium, High Contrast Alert Box) ──
                if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Iconsax.location, size: 16, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALAMAT PENJEMPUTAN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _C.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.pickupAddress!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: _C.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Google Maps Directions Button ──
                const Divider(height: 24, color: _C.borderLight),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _openGoogleMaps(context, booking),
                          icon: const Icon(Iconsax.map_1, size: 16, color: Colors.white),
                          label: Text(
                            'Buka Rute Navigasi (Google Maps)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (80 + index * 60).ms, duration: 400.ms)
        .slideY(
          begin: 0.05,
          delay: (80 + index * 60).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── Info Chip ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Stat Item ──
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}
