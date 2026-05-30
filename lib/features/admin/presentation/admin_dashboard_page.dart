import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import 'live_trip_manifest_page.dart';
import 'trip_manifest_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (consistent with app)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
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
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
}

// ─────────────────────────────────────────────────────────
//  TRIP STATUS
// ─────────────────────────────────────────────────────────
enum TripStatus { menunggu, berangkat, selesai, dibatalkan }

extension TripStatusExt on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.menunggu:
        return 'Menunggu';
      case TripStatus.berangkat:
        return 'Berangkat';
      case TripStatus.selesai:
        return 'Selesai';
      case TripStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case TripStatus.menunggu:
        return _C.warning;
      case TripStatus.berangkat:
        return _C.info;
      case TripStatus.selesai:
        return _C.success;
      case TripStatus.dibatalkan:
        return _C.error;
    }
  }

  Color get bgColor {
    switch (this) {
      case TripStatus.menunggu:
        return _C.warningBg;
      case TripStatus.berangkat:
        return _C.infoBg;
      case TripStatus.selesai:
        return _C.successBg;
      case TripStatus.dibatalkan:
        return _C.errorBg;
    }
  }

  IconData get icon {
    switch (this) {
      case TripStatus.menunggu:
        return Iconsax.clock;
      case TripStatus.berangkat:
        return Iconsax.send_2;
      case TripStatus.selesai:
        return Iconsax.tick_circle;
      case TripStatus.dibatalkan:
        return Iconsax.close_circle;
    }
  }
}

// ─────────────────────────────────────────────────────────
//  TRIP DATA MODEL
// ─────────────────────────────────────────────────────────
class TripData {
  final String id;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final String vehiclePlate;
  final String vehicleName;
  final int totalSeats;
  final int bookedSeats;
  final TripStatus status;
  final List<PassengerData> passengers;

  const TripData({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.vehiclePlate,
    required this.vehicleName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.status,
    required this.passengers,
  });
}

class PassengerData {
  final String name;
  final int seatNumber;
  final bool isValidated;
  final String ticketCode;

  const PassengerData({
    required this.name,
    required this.seatNumber,
    this.isValidated = false,
    required this.ticketCode,
  });
}

// ═══════════════════════════════════════════════════════════
//  ADMIN DASHBOARD PAGE — Driver / Branch Operator Home
// ═══════════════════════════════════════════════════════════
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── User profile (loaded from Firestore) ──
  String _driverName = '';
  String _assignedFleetId = '';
  String _fleetName = '';
  int _totalSeats = 8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load admin profile + fleet details from Firestore.
  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) return;

      final d = userDoc.data()!;
      final fleetId = d['assignedFleetId'] as String? ?? '';

      String fName = '';
      int seats = 8;
      if (fleetId.isNotEmpty) {
        final fleetDoc = await FirebaseFirestore.instance
            .collection('fleets')
            .doc(fleetId)
            .get();
        if (fleetDoc.exists) {
          fName = fleetDoc.data()?['name'] as String? ?? '';
          seats = (fleetDoc.data()?['totalSeats'] as num?)?.toInt() ?? 8;
        }
      }

      if (mounted) {
        setState(() {
          _driverName = d['namaLengkap'] as String? ?? 'Admin';
          _assignedFleetId = fleetId;
          _fleetName = fName;
          _totalSeats = seats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Convert flat bookings list into grouped TripData ──
  List<TripData> _bookingsToTrips(List<BookingModel> bookings) {
    // Group by departureDate|origin|destination
    final Map<String, List<BookingModel>> grouped = {};
    for (final b in bookings) {
      final key = '${b.departureDate}|${b.origin}|${b.destination}';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    return grouped.entries.map((entry) {
      final parts = entry.key.split('|');
      final bList = entry.value;
      final first = bList.first;

      // Derive trip status from individual booking statuses
      final statusSet = bList.map((b) => b.status).toSet();
      TripStatus tripStatus;
      if (statusSet.every((s) => s == BookingStatus.completed || s == BookingStatus.used)) {
        tripStatus = TripStatus.selesai;
      } else if (statusSet.every((s) => s == BookingStatus.cancelled)) {
        tripStatus = TripStatus.dibatalkan;
      } else {
        tripStatus = TripStatus.menunggu;
      }

      // Convert each booking to PassengerData entries
      final passengers = <PassengerData>[];
      for (final b in bList) {
        if (b.seatNumbers.isNotEmpty) {
          for (final seat in b.seatNumbers) {
            passengers.add(PassengerData(
              name: b.userName,
              seatNumber: seat,
              isValidated: b.status.isValidated,
              ticketCode: b.bookingCode,
            ));
          }
        } else {
          passengers.add(PassengerData(
            name: b.userName,
            seatNumber: 0,
            isValidated: b.status.isValidated,
            ticketCode: b.bookingCode,
          ));
        }
      }

      passengers.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

      return TripData(
        id: first.id ?? 'TRP-${entry.key.hashCode.abs()}',
        origin: parts.length > 1 ? parts[1] : first.origin,
        destination: parts.length > 2 ? parts[2] : first.destination,
        departureTime: first.createdAt ?? DateTime.now(),
        vehiclePlate: '',
        vehicleName: _fleetName.isNotEmpty ? _fleetName : first.fleetName,
        totalSeats: _totalSeats,
        bookedSeats: passengers.length,
        status: tripStatus,
        passengers: passengers,
      );
    }).toList()
      ..sort((a, b) => b.departureTime.compareTo(a.departureTime));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final w = mq.size.width;
    final isSmall = w < 360;

    // ── Loading state while fetching user profile ──
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _C.primary),
              const SizedBox(height: 16),
              Text(
                'Memuat data...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _C.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── No fleet assigned fallback ──
    if (_assignedFleetId.isEmpty) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.bus, size: 56, color: _C.textHint),
                const SizedBox(height: 16),
                Text(
                  'Belum ada armada ditugaskan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hubungi Super Admin untuk penugasan armada',
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
      );
    }

    // ── Main content with real-time stream ──
    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<List<BookingModel>>(
        stream: BookingService.allFleetBookingsStream(_assignedFleetId),
        builder: (context, snapshot) {
          final bookings = snapshot.data ?? [];
          final allTrips = _bookingsToTrips(bookings);

          final upcomingTrips =
              allTrips.where((t) => t.status == TripStatus.menunggu).toList();
          final activeTrips =
              allTrips.where((t) => t.status == TripStatus.berangkat).toList();
          final completedTrips = allTrips
              .where((t) =>
                  t.status == TripStatus.selesai ||
                  t.status == TripStatus.dibatalkan)
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HEADER ──
              SliverToBoxAdapter(
                child: _buildHeader(topPad, isSmall, allTrips),
              ),
              // ── STATS ROW ──
              SliverToBoxAdapter(
                child: _buildStatsRow(isSmall, allTrips),
              ),
              // ── TAB BAR ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  tabController: _tabController,
                  onChanged: () => setState(() {}),
                ),
              ),
              // ── TRIP LIST ──
              SliverFillRemaining(
                child: snapshot.connectionState == ConnectionState.waiting &&
                        bookings.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _C.primary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTripList(
                              upcomingTrips, 'Belum ada perjalanan terjadwal'),
                          _buildTripList(
                              activeTrips, 'Tidak ada perjalanan aktif'),
                          _buildTripList(completedTrips,
                              'Belum ada riwayat perjalanan'),
                        ],
                      ),
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
  Widget _buildHeader(double topPad, bool isSmall, List<TripData> allTrips) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat Pagi'
        : now.hour < 17
            ? 'Selamat Siang'
            : 'Selamat Malam';
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: greeting + notification bell ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: GoogleFonts.inter(
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _driverName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isSmall ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: isSmall ? 11 : 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    const Icon(Iconsax.notification, color: Colors.white, size: 22),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _C.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Quick summary card ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Iconsax.route_square, size: 18, color: _C.tealLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${allTrips.where((t) => t.status == TripStatus.menunggu || t.status == TripStatus.berangkat).length} perjalanan hari ini',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.08, duration: 500.ms, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────
  //  STATS ROW
  // ─────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isSmall, List<TripData> allTrips) {
    final totalPassengers = allTrips.fold<int>(0, (acc, t) => acc + t.bookedSeats);
    final validatedCount = allTrips.fold<int>(
        0, (acc, t) => acc + t.passengers.where((p) => p.isValidated).length);

    final stats = [
      _StatItem(
        icon: Iconsax.bus,
        label: 'Total Trip',
        value: '${allTrips.length}',
        color: _C.primary,
        bgColor: _C.primary.withValues(alpha: 0.08),
      ),
      _StatItem(
        icon: Iconsax.people,
        label: 'Penumpang',
        value: '$totalPassengers',
        color: _C.teal,
        bgColor: _C.teal.withValues(alpha: 0.08),
      ),
      _StatItem(
        icon: Iconsax.scan_barcode,
        label: 'Tervalidasi',
        value: '$validatedCount',
        color: _C.success,
        bgColor: _C.successBg,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 6,
                right: i == stats.length - 1 ? 0 : 6,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: isSmall ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stat.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stat.icon, size: 18, color: stat.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSmall ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      color: _C.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (200 + i * 100).ms, duration: 400.ms)
                .slideY(begin: 0.15, delay: (200 + i * 100).ms, duration: 400.ms),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  TRIP LIST
  // ─────────────────────────────────────────────────────
  Widget _buildTripList(List<TripData> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.bus, size: 56, color: _C.textHint),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _C.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(trips[index], index);
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  TRIP CARD
  // ─────────────────────────────────────────────────────
  Widget _buildTripCard(TripData trip, int index) {
    final time = DateFormat('HH:mm').format(trip.departureTime);
    final isUpcoming = trip.departureTime.isAfter(DateTime.now());
    final timeUntil = trip.departureTime.difference(DateTime.now());

    String countdownText = '';
    if (isUpcoming && trip.status == TripStatus.menunggu) {
      if (timeUntil.inHours > 0) {
        countdownText = '${timeUntil.inHours}j ${timeUntil.inMinutes % 60}m lagi';
      } else {
        countdownText = '${timeUntil.inMinutes}m lagi';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Navigate to live manifest (Firestore-backed) if fleet assigned,
            // otherwise fall back to static TripManifestPage
            if (_assignedFleetId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveTripManifestPage(
                    fleetId: _assignedFleetId,
                    departureDate: DateFormat('dd MMM yyyy').format(trip.departureTime),
                    origin: trip.origin,
                    destination: trip.destination,
                    fleetName: _fleetName.isNotEmpty ? _fleetName : trip.vehicleName,
                    totalSeats: _totalSeats,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripManifestPage(trip: trip),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Top: Status + Time ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: trip.status.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trip.status.icon, size: 13, color: trip.status.color),
                          const SizedBox(width: 5),
                          Text(
                            trip.status.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: trip.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown
                    if (countdownText.isNotEmpty)
                      Text(
                        countdownText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.primary,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Route ──
                Row(
                  children: [
                    // Dot-Line-Dot route indicator
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _C.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: _C.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1.5,
                          height: 26,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.border,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _C.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: _C.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _C.teal.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.origin,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            trip.destination,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Iconsax.clock, size: 14, color: _C.textTertiary),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Bottom: Vehicle + Passengers ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.bus, size: 15, color: _C.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${trip.vehicleName} • ${trip.vehiclePlate}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Iconsax.people, size: 15, color: _C.textTertiary),
                      const SizedBox(width: 5),
                      Text(
                        '${trip.bookedSeats}/${trip.totalSeats}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 + index * 80).ms, duration: 400.ms)
        .slideX(begin: 0.06, delay: (100 + index * 80).ms, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────
//  STAT ITEM MODEL
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
//  STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final VoidCallback onChanged;

  const _StickyTabBarDelegate({
    required this.tabController,
    required this.onChanged,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        color: _C.bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          height: 44,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border.withValues(alpha: 0.6)),
        ),
        child: TabBar(
          controller: tabController,
          onTap: (_) => onChanged(),
          indicator: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: _C.textTertiary,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.all(3),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Terjadwal'),
            Tab(text: 'Aktif'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController;
}
