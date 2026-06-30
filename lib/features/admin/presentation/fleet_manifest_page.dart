import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/models/lng_lat.dart';
import '../../../core/services/city_coordinates_seeder.dart';
import '../../../core/services/mapbox_directions_service.dart';
import '../../../core/services/driver_tracking_service.dart';
import 'ticket_scanner_page.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'passenger_detail_page.dart';
import '../../super_admin/presentation/surat_jalan_preview_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary    = Color(0xFF0F4C81);
  static const Color teal       = Color(0xFF0D9488);
  static const Color bg         = Color(0xFFF1F5F9);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE2E8F0);
  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF475569);
  static const Color textTertiary   = Color(0xFF94A3B8);
  static const Color success    = Color(0xFF059669);
  static const Color successBg  = Color(0xFFECFDF5);
  static const Color warning    = Color(0xFFD97706);
  static const Color warningBg  = Color(0xFFFFFBEB);
  static const Color info       = Color(0xFF0284C7);
  static const Color infoBg     = Color(0xFFF0F9FF);
  static const Color error      = Color(0xFFDC2626);
}

// ═══════════════════════════════════════════════════════════
//  FLEET MANIFEST PAGE — REDESIGNED
//
//  Sections:
//  1. Gradient header + AppBar
//  2. Stats row (Total, Lunas, Tervalidasi, Sudah Naik)
//  3. Surat Jalan card
//  4. Detail Kendaraan card
//  5. Peta / Navigasi card
//  6. Daftar Penumpang (compact cards) → tap → PassengerDetailPage
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

class _FleetManifestPageState extends State<FleetManifestPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _headerAnim;
  bool _tripProcessing = false;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isSmall   = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('fleetId', isEqualTo: widget.fleetId)
            .where('status', whereIn: ['paid', 'validated', 'used', 'completed', 'no_show'])
            .snapshots(),
        builder: (context, snapshot) {
          final bookingDocs = snapshot.data?.docs ?? [];
          final todayStr    = DateFormat('dd MMM yyyy').format(DateTime.now());
          final bookings    = bookingDocs
              .map((d) => BookingModel.fromFirestore(d))
              .where((b) =>
                  b.origin == widget.origin &&
                  b.destination == widget.destination &&
                  b.departureDate == todayStr)
              .toList();

          final paidCount      = bookings.where((b) => b.status == BookingStatus.paid).length;
          final validatedCount = bookings.where((b) => b.status == BookingStatus.validated).length;
          final completedCount = bookings.where((b) => b.status == BookingStatus.used || b.status == BookingStatus.completed).length;

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── HEADER ──
                  SliverToBoxAdapter(
                    child: _buildHeader(context, topPad, bookings.length),
                  ),

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



                  // ── DETAIL KENDARAAN ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildVehicleCard(context),
                    ),
                  ),

                  // ── PETA / NAVIGASI ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildMapCard(context),
                    ),
                  ),

                  // ── PASSENGER SECTION HEADER ──
                  SliverToBoxAdapter(
                    child: _buildPassengerHeader(bookings.length),
                  ),

                  // ── PASSENGER LIST ──
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      bookings.isEmpty)
                    SliverFillRemaining(
                      child: SkeletonLoader.list(itemCount: 4),
                    )
                  else if (bookings.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _CompactPassengerCard(
                            booking: bookings[i],
                            index: i,
                            onTap: () => Navigator.push(
                              context,
                              _pageRoute(
                                PassengerDetailPage(booking: bookings[i]),
                              ),
                            ),
                          ),
                          childCount: bookings.length,
                        ),
                      ),
                    ),
                ],
              ),

              // ── BOTTOM ACTION BAR ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(context, bottomPad, bookings),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double topPad, int passengerCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3660), Color(0xFF0F4C81), Color(0xFF1565A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.arrow_left, size: 22, color: Colors.white),
                splashRadius: 22,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Manifest Penumpang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              // Passenger count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.people, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '$passengerCount orang',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route pill
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                _headerInfoCol(
                  label: 'Dari',
                  value: widget.origin.isEmpty ? '-' : widget.origin,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.departureTime ?? '-',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _headerInfoCol(
                  label: 'Tujuan',
                  value: widget.destination.isEmpty ? '-' : widget.destination,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _headerInfoCol({
    required String label,
    required String value,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: crossAxisAlignment == CrossAxisAlignment.end
                ? TextAlign.end
                : TextAlign.start,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  STATS ROW
  // ─────────────────────────────────────────────────────
  Widget _buildStatsRow(
    bool isSmall, {
    required int total,
    required int paid,
    required int validated,
    required int completed,
  }) {
    final stats = [
      _StatItem(icon: Iconsax.people,      label: 'Total',      value: '$total',     color: _C.primary, bg: _C.primary.withValues(alpha: 0.1)),
      _StatItem(icon: Iconsax.ticket_2,    label: 'Lunas',      value: '$paid',      color: _C.warning, bg: _C.warningBg),
      _StatItem(icon: Iconsax.shield_tick, label: 'Validasi',   value: '$validated', color: _C.info,    bg: _C.infoBg),
      _StatItem(icon: Iconsax.tick_circle, label: 'Sudah Naik', value: '$completed', color: _C.success, bg: _C.successBg),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: stats.asMap().entries.map((e) {
              final i    = e.key;
              final stat = e.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: stat.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(stat.icon, size: 15, color: stat.color),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stat.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isSmall ? 15 : 18,
                              fontWeight: FontWeight.w800,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat.label,
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 9.5 : 11,
                              fontWeight: FontWeight.w500,
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
                        height: 32,
                        color: _C.border.withValues(alpha: 0.6),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.06, delay: 150.ms);
  }



  // ─────────────────────────────────────────────────────
  //  DETAIL KENDARAAN CARD
  // ─────────────────────────────────────────────────────
  Widget _buildVehicleCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fleets')
          .doc(widget.fleetId)
          .snapshots(),
      builder: (context, snap) {
        final data        = snap.data?.data() as Map<String, dynamic>?;
        final imageUrl    = data?['imageUrl'] as String?;
        final totalSeats  = (data?['totalSeats'] as num?)?.toInt() ?? 0;
        final availSeats  = (data?['availableSeats'] as num?)?.toInt() ?? 0;
        final bookedSeats = totalSeats - availSeats;

        final driverName = data?['driverName'] as String? ?? '';
        final licensePlate = data?['name'] as String? ?? '';
        final vehicleType = data?['vehicleType'] as String? ?? '';

        return _ManifestSectionCard(
          title: 'Detail Kendaraan',
          icon: Iconsax.car,
          delay: 300,
          trailing: driverName.isNotEmpty
              ? TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuratJalanPreviewPage(
                          driverName: driverName,
                          licensePlate: licensePlate,
                          vehicleType: vehicleType.isNotEmpty ? vehicleType : 'Minibus',
                          origin: widget.origin,
                          destination: widget.destination,
                          departureTime: widget.departureTime ?? '10:00 WIB',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.document_text, size: 14, color: _C.teal),
                  label: Text(
                    'Surat Jalan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _C.teal,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const ui.Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 100,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _vehiclePlaceholder(),
                      )
                    : _vehiclePlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fleetName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _C.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.vehicleType.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.vehicleType,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _C.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Seat capacity bar
                    _SeatCapacityBar(
                      booked: bookedSeats,
                      total: totalSeats,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vehiclePlaceholder() {
    return Container(
      width: 100,
      height: 76,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: const Icon(Iconsax.car, size: 32, color: _C.textTertiary),
    );
  }

  // ─────────────────────────────────────────────────────
  //  PETA / NAVIGASI CARD  — Real Mapbox Route Map
  // ─────────────────────────────────────────────────────
  Widget _buildMapCard(BuildContext context) {
    return _ManifestSectionCard(
      title: 'Peta & Navigasi',
      icon: Iconsax.map_1,
      delay: 400,
      child: Column(
        children: [
          // ── Real Mapbox embedded map ──
          _EmbeddedRouteMap(
            fleetId: widget.fleetId,
            origin: widget.origin,
            destination: widget.destination,
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(BuildContext context, List<BookingModel> bookings) async {
    if (_tripProcessing) return;
    setState(() => _tripProcessing = true);
    try {
      final pendingPickups = bookings.where((b) => 
        b.status != BookingStatus.used && 
        b.status != BookingStatus.validated &&
        b.status != BookingStatus.noShow
      ).toList();

      if (pendingPickups.isNotEmpty) {
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.warning_2,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jemputan Belum Selesai',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Ada ${pendingPickups.length} penumpang yang belum selesai dijemput. Silakan selesaikan semua penjemputan di manifest terlebih dahulu sebelum memulai perjalanan.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
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

      await DriverTrackingService.startTracking(fleetId: widget.fleetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perjalanan dimulai!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _C.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memulai: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tripProcessing = false);
    }
  }

  Future<void> _endTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Akhiri Perjalanan?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        content: Text('Pastikan semua penumpang sudah turun.', style: GoogleFonts.inter(fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(color: _C.textTertiary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Akhiri', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (_tripProcessing) return;
    setState(() => _tripProcessing = true);
    try {
      await DriverTrackingService.stopTracking(widget.fleetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perjalanan telah berakhir.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _C.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengakhiri: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tripProcessing = false);
    }
  }

  Future<void> _resetTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mulai Perjalanan Baru?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        content: Text('Status armada ini akan diatur ulang ke \'Menunggu\' untuk perjalanan selanjutnya.', style: GoogleFonts.inter(fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(color: _C.textTertiary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _C.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Atur Ulang', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (_tripProcessing) return;
    setState(() => _tripProcessing = true);
    try {
      final fleetSnap = await FirebaseFirestore.instance.collection('fleets').doc(widget.fleetId).get();
      final totalSeats = (fleetSnap.data()?['totalSeats'] as num?)?.toInt() ?? 7;

      await FirebaseFirestore.instance.collection('fleets').doc(widget.fleetId).update({
        'tripStatus': 'menunggu',
        'availableSeats': totalSeats,
        'tripStartedAt': null,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Armada siap untuk perjalanan baru.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _C.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengatur ulang: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tripProcessing = false);
    }
  }

  // ─────────────────────────────────────────────────────
  //  PASSENGER SECTION HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildPassengerHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.people, size: 16, color: _C.primary),
          ),
          const SizedBox(width: 10),
          Text(
            'Daftar Penumpang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
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
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.people, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Penumpang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tiket yang sudah dibayar\nakan muncul di sini',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _C.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  BOTTOM BAR
  // ─────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, double bottomPad, List<BookingModel> bookings) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fleets')
          .doc(widget.fleetId)
          .snapshots(),
      builder: (context, snap) {
        final data       = snap.data?.data() as Map<String, dynamic>?;
        final tripStatus = data?['tripStatus'] as String? ?? 'menunggu';
        final isWaiting  = tripStatus == 'menunggu';
        final isActive   = tripStatus == 'berangkat';

        final Color btnColor;
        final IconData btnIcon;
        final String btnLabel;
        final VoidCallback? btnAction;

        if (isWaiting) {
          btnColor = _C.primary;
          btnIcon  = Iconsax.routing_2;
          btnLabel = _tripProcessing ? 'Memproses...' : 'Mulai Perjalanan';
          btnAction = _tripProcessing ? null : () => _startTrip(context, bookings);
        } else if (isActive) {
          btnColor = const Color(0xFFDC2626);
          btnIcon  = Iconsax.close_circle;
          btnLabel = _tripProcessing ? 'Memproses...' : 'Akhiri Perjalanan';
          btnAction = _tripProcessing ? null : () => _endTrip(context);
        } else {
          btnColor = _C.teal;
          btnIcon  = Iconsax.refresh_2;
          btnLabel = _tripProcessing ? 'Memproses...' : 'Mulai Perjalanan Baru';
          btnAction = _tripProcessing ? null : () => _resetTrip(context);
        }

        return Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Scan ticket (Square Outlined Button)
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    _pageRoute(const TicketScannerPage()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.teal,
                    side: const BorderSide(color: _C.teal, width: 1.5),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Iconsax.scan_barcode, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Dynamic Action Button (Primary)
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: btnAction,
                    icon: Icon(btnIcon, size: 18, color: Colors.white),
                    label: Text(
                      btnLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      elevation: btnAction == null ? 0 : 3,
                      shadowColor: btnColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  PAGE ROUTE HELPER
// ─────────────────────────────────────────────────────
PageRoute<T> _pageRoute<T>(Widget page) {
  return MaterialPageRoute<T>(builder: (_) => page);
}

// ═══════════════════════════════════════════════════════════
//  EMBEDDED ROUTE MAP — Real Mapbox with Directions API Route
//
//  Features:
//  • Fetches real driving route via Mapbox Directions API
//  • Draws polyline with gradient color on the map
//  • Shows origin pin (green) + destination pin (red)
//  • Live driver marker from Firestore driver_locations
//  • LIVE badge when driver is active
//  • Expand button → DriverTripPage
//  • Loading shimmer & error fallback
// ═══════════════════════════════════════════════════════════
class _EmbeddedRouteMap extends StatefulWidget {
  final String fleetId;
  final String origin;
  final String destination;

  const _EmbeddedRouteMap({
    required this.fleetId,
    required this.origin,
    required this.destination,
  });

  @override
  State<_EmbeddedRouteMap> createState() => _EmbeddedRouteMapState();
}

class _EmbeddedRouteMapState extends State<_EmbeddedRouteMap> {
  // Map controllers
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointMgr;
  PolylineAnnotationManager? _polyMgr;

  // Route state
  List<LngLat> _routePoints = [];
  bool _routeLoaded = false;
  bool _routeError  = false;
  bool _mapReady    = false;

  // Driver tracking
  LngLat? _driverPos;
  PointAnnotation? _driverAnnotation;
  bool _isDriverActive = false;

  // Pre-rendered icon bytes
  Uint8List? _originIconBytes;
  Uint8List? _destIconBytes;
  Uint8List? _driverIconBytes;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _renderIcons();
    _listenDriverLocation();
  }

  // ── Load route from Mapbox Directions API ──
  Future<void> _loadRoute() async {
    try {
      final oCoords = CityCoordinatesSeeder.getCoordinates(widget.origin);
      final dCoords = CityCoordinatesSeeder.getCoordinates(widget.destination);
      if (oCoords == null || dCoords == null) {
        if (mounted) setState(() => _routeError = true);
        return;
      }
      final waypoints = [
        LngLat(oCoords['lng']!, oCoords['lat']!),
        LngLat(dCoords['lng']!, dCoords['lat']!),
      ];
      final route = await MapboxDirectionsService.instance.getRoute(waypoints);
      if (!mounted) return;
      setState(() {
        _routePoints = route.isNotEmpty ? route : waypoints;
        _routeLoaded = true;
      });
      if (_mapReady) _drawRoute();
    } catch (_) {
      if (mounted) setState(() => _routeError = true);
    }
  }

  // ── Pre-render custom marker icons ──
  Future<void> _renderIcons() async {
    _originIconBytes = await _renderPin(const Color(0xFF059669));
    _destIconBytes   = await _renderPin(const Color(0xFFEF4444));
    _driverIconBytes = await _renderDriverIcon();
    if (mounted) setState(() {});
  }

  Future<Uint8List> _renderPin(Color color, {double size = 64}) async {
    final r = size * 0.38;
    final cx = size / 2;
    final cy = r;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    final shadow = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, cy + 2), r * 1.05, shadow);

    // Pin circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // Pin tail
    final path = Path()
      ..moveTo(cx, size * 0.82)
      ..lineTo(cx - r * 0.42, cy + r * 0.72)
      ..lineTo(cx + r * 0.42, cy + r * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // White inner dot
    canvas.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = Colors.white);

    final img  = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _renderDriverIcon({double size = 52}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cx = size / 2;
    final cy = size / 2;

    // Outer pulse ring
    canvas.drawCircle(
      Offset(cx, cy),
      size / 2,
      Paint()..color = const Color(0xFF0F4C81).withOpacity(0.18),
    );
    // Main circle
    canvas.drawCircle(
      Offset(cx, cy),
      size * 0.38,
      Paint()..color = const Color(0xFF0F4C81),
    );
    // Border
    canvas.drawCircle(
      Offset(cx, cy),
      size * 0.38,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final img  = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  // ── Listen to driver location from Firestore ──
  void _listenDriverLocation() {
    FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(widget.fleetId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final d   = doc.data();
      if (d == null) return;
      final lat = (d['latitude']  as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      setState(() {
        _driverPos      = LngLat(lng, lat);
        _isDriverActive = true;
      });
      _updateDriverMarker();
    });
  }

  // ── Map callbacks ──
  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    // Enable gestures — interactive map
    await map.gestures.updateSettings(GesturesSettings(
      scrollEnabled: true,
      rotateEnabled: true,
      pinchToZoomEnabled: true,
      pitchEnabled: true,
      doubleTapToZoomInEnabled: true,
      doubleTouchToZoomOutEnabled: true,
    ));

    _pointMgr = await map.annotations.createPointAnnotationManager();
    _polyMgr  = await map.annotations.createPolylineAnnotationManager();
    _mapReady  = true;
    if (_routeLoaded) _drawRoute();
  }

  // ── Draw route polyline + pins ──
  Future<void> _drawRoute() async {
    if (_polyMgr == null || _pointMgr == null) return;
    if (_routePoints.isEmpty) return;
    if (_originIconBytes == null || _destIconBytes == null) return;

    // Casing outline (drawn first = behind)
    await _polyMgr!.create(PolylineAnnotationOptions(
      lineColor: const Color(0xFF1A6BB5).withOpacity(0.25).toARGB32(),
      lineWidth: 9.0,
      geometry: LineString(
        coordinates: _routePoints
            .map((p) => Position(p.lng, p.lat))
            .toList(),
      ),
    ));

    // Main blue route polyline
    await _polyMgr!.create(PolylineAnnotationOptions(
      lineColor: const Color(0xFF0F4C81).toARGB32(),
      lineWidth: 4.5,
      geometry: LineString(
        coordinates: _routePoints
            .map((p) => Position(p.lng, p.lat))
            .toList(),
      ),
    ));

    // Origin marker (green pin)
    final origin = _routePoints.first;
    await _pointMgr!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(origin.lng, origin.lat)),
      image: _originIconBytes,
      iconSize: 0.45,
    ));

    // Destination marker (red pin)
    final dest = _routePoints.last;
    await _pointMgr!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(dest.lng, dest.lat)),
      image: _destIconBytes,
      iconSize: 0.45,
    ));

    // Driver marker
    if (_driverPos != null && _driverIconBytes != null) {
      _driverAnnotation = await _pointMgr!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(_driverPos!.lng, _driverPos!.lat)),
        image: _driverIconBytes,
        iconSize: 0.5,
      ));
    }

    // ━━ Fit camera so BOTH endpoints are always visible ━━
    await _fitCameraToBounds();
  }

  // ── Camera fit — guarantees both pins are visible with padding ──
  Future<void> _fitCameraToBounds() async {
    if (_mapboxMap == null || _routePoints.isEmpty) return;

    // Compute bounding box from ALL route points
    double minLng = _routePoints.first.lng;
    double maxLng = _routePoints.first.lng;
    double minLat = _routePoints.first.lat;
    double maxLat = _routePoints.first.lat;

    for (final p in _routePoints) {
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
    }

    // Expand bbox by ~10% so pins don't sit on the edge
    final lngPad = (maxLng - minLng) * 0.18;
    final latPad = (maxLat - minLat) * 0.22;

    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;

    // Calculate zoom from bbox size
    final lngSpan = (maxLng - minLng) + lngPad * 2;
    final latSpan = (maxLat - minLat) + latPad * 2;
    final maxSpan = lngSpan > latSpan ? lngSpan : latSpan;

    final zoom = _zoomForSpan(maxSpan);

    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: zoom,
          bearing: 0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 600, startDelay: 0),
      );
    } catch (_) {}
  }

  double _zoomForSpan(double span) {
    if (span < 0.08) { return 11.5; }
    if (span < 0.20) { return 10.0; }
    if (span < 0.50) { return 9.0; }
    if (span < 1.00) { return 7.8; }
    if (span < 2.00) { return 6.8; }
    if (span < 4.00) { return 6.0; }
    if (span < 8.00) { return 5.2; }
    return 4.2;
  }

  // ── Update driver marker live ──
  Future<void> _updateDriverMarker() async {
    if (_driverPos == null || _pointMgr == null || !_mapReady) return;
    final pos = _driverPos!;
    try {
      if (_driverAnnotation != null) {
        _driverAnnotation!.geometry =
            Point(coordinates: Position(pos.lng, pos.lat));
        await _pointMgr!.update(_driverAnnotation!);
      } else if (_driverIconBytes != null) {
        _driverAnnotation = await _pointMgr!.create(PointAnnotationOptions(
          geometry: Point(coordinates: Position(pos.lng, pos.lat)),
          image: _driverIconBytes,
          iconSize: 0.5,
        ));
      }
    } catch (_) {}
  }

  // ── Initial camera center (before flyTo) ──
  Position get _initialCenter {
    final oC = CityCoordinatesSeeder.getCoordinates(widget.origin);
    final dC = CityCoordinatesSeeder.getCoordinates(widget.destination);
    if (oC != null && dC != null) {
      return Position(
        (oC['lng']! + dC['lng']!) / 2,
        (oC['lat']! + dC['lat']!) / 2,
      );
    }
    return Position(100.35, -0.9);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Stack(
          children: [
            // ── Mapbox Map ──
            MapWidget(
              key: ValueKey('manifest_map_${widget.fleetId}'),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              mapOptions: MapOptions(
                pixelRatio: MediaQuery.of(context).devicePixelRatio,
                constrainMode: ConstrainMode.HEIGHT_ONLY,
                orientation: NorthOrientation.UPWARDS,
              ),
              viewport: CameraViewportState(
                center: Point(coordinates: _initialCenter),
                zoom: 7.5,
              ),
              styleUri: 'mapbox://styles/mapbox/streets-v12',
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: (_) {
                if (_routeLoaded) _drawRoute();
              },
            ),

            // ── Loading overlay ──
            if (!_routeLoaded && !_routeError)
              Container(
                color: Colors.white.withOpacity(0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Memuat rute...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Error fallback ──
            if (_routeError)
              Container(
                color: _C.bg,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.map,
                        size: 36,
                        color: Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rute tidak ditemukan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _C.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Route label overlay (top-left) ──
            if (_routeLoaded)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.origin,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        widget.destination,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── LIVE badge (top-right) ──
            if (_isDriverActive)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  COMPACT PASSENGER CARD
// ═══════════════════════════════════════════════════════════
class _CompactPassengerCard extends StatelessWidget {
  final BookingModel booking;
  final int index;
  final VoidCallback onTap;

  const _CompactPassengerCard({
    required this.booking,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUsed      = booking.status == BookingStatus.used;
    final isNoShow    = booking.status == BookingStatus.noShow;
    final isValidated = booking.status == BookingStatus.validated;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (isUsed) {
      statusColor = _C.success;
      statusIcon  = Iconsax.tick_circle;
      statusLabel = 'Sudah Naik';
    } else if (isNoShow) {
      statusColor = _C.error;
      statusIcon  = Iconsax.user_remove;
      statusLabel = 'Tidak Datang';
    } else if (isValidated) {
      statusColor = _C.info;
      statusIcon  = Iconsax.shield_tick;
      statusLabel = 'Tervalidasi';
    } else {
      statusColor = _C.warning;
      statusIcon  = Iconsax.clock;
      statusLabel = 'Belum Check-in';
    }

    final seatLabel = booking.seatNumbers.isNotEmpty
        ? booking.seatNumbers.map((s) => '$s').join(', ')
        : '-';

    final initial = booking.userName.isNotEmpty
        ? booking.userName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUsed
                ? _C.success.withValues(alpha: 0.25)
                : isValidated
                    ? _C.info.withValues(alpha: 0.25)
                    : _C.border,
            width: (isUsed || isValidated) ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(booking.userId)
                  .snapshots(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final profileImageUrl = userData?['profileImageUrl'] as String?;

                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUsed
                        ? _C.success.withValues(alpha: 0.12)
                        : isValidated
                            ? _C.info.withValues(alpha: 0.12)
                            : _C.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    image: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? Center(
                          child: isUsed
                              ? const Icon(Iconsax.tick_circle, size: 18, color: _C.success)
                              : isValidated
                                  ? const Icon(Iconsax.shield_tick, size: 18, color: _C.info)
                                  : Text(
                                      initial,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: _C.primary,
                                      ),
                                    ),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 12),

            // ── Name & Code ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                      decoration: isUsed ? TextDecoration.lineThrough : null,
                      decorationColor: _C.success.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.ticket, size: 11, color: _C.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Kursi $seatLabel',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _C.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status + Chevron ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 14,
                  color: _C.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (80 + index * 50).ms, duration: 350.ms)
        .slideX(begin: 0.03, delay: (80 + index * 50).ms, duration: 350.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  REUSABLE SECTION CARD
// ═══════════════════════════════════════════════════════════
class _ManifestSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final int delay;
  final Widget? trailing;

  const _ManifestSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.delay = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: _C.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.06, delay: delay.ms, duration: 400.ms);
  }
}



// ─────────────────────────────────────────────────────
//  SEAT CAPACITY BAR
// ─────────────────────────────────────────────────────
class _SeatCapacityBar extends StatelessWidget {
  final int booked;
  final int total;

  const _SeatCapacityBar({required this.booked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (booked / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kapasitas',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _C.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              '$booked / $total kursi',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: _C.bg,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 0.9 ? _C.error : pct >= 0.7 ? _C.warning : _C.success,
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────
//  STAT ITEM DATA
// ─────────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });
}
