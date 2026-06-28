// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/logout_dialog.dart';
import '../../edit_profile/presentation/edit_profile_page.dart';
import '../../package/presentation/driver_package_confirmation_page.dart';
import 'driver_trip_page.dart';
import 'fleet_manifest_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / Enterprise / No Purple
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
//  DRIVER DASHBOARD PAGE — Multi-Fleet Assignment List
//
//  Flow:
//  1. StreamBuilder: `fleets` where `driverId == currentUid`
//     → JIKA kosong → Ilustrasi "Belum ada penugasan"
//     → JIKA ada → ListView.builder card armada
//  2. Klik card → Navigasi ke FleetManifestPage(fleetId)
// ═══════════════════════════════════════════════════════════
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  String _driverName = 'Sopir';
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _driverName = doc.data()?['namaLengkap'] as String? ?? 'Sopir';
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final isSmall = mq.size.width < 360;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fleets')
            .where('driverId', isEqualTo: uid)
            .snapshots(),
        builder: (context, fleetSnap) {
          if (fleetSnap.connectionState == ConnectionState.waiting &&
              !_profileLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: _C.primary),
            );
          }

          final fleetDocs = fleetSnap.data?.docs ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HEADER ──
              SliverToBoxAdapter(child: _buildHeader(topPad, isSmall)),

              // ── SECTION TITLE ──
              SliverToBoxAdapter(child: _buildSectionTitle(fleetDocs.length)),

              // ── PAKET BUTTON ──
              SliverToBoxAdapter(child: _buildPackageCard()),

              // ── EMPTY STATE ──
              if (fleetDocs.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              // ── FLEET LIST ──
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = fleetDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _FleetCard(
                        fleetId: doc.id,
                        data: data,
                        index: index,
                        onTap: () =>
                            _navigateToManifest(fleetId: doc.id, data: data),
                      );
                    }, childCount: fleetDocs.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  NAVIGATE TO FLEET MANIFEST
  // ─────────────────────────────────────────────────────
  void _navigateToManifest({
    required String fleetId,
    required Map<String, dynamic> data,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FleetManifestPage(
          fleetId: fleetId,
          fleetName: data['name'] as String? ?? '',
          vehicleType: data['vehicleType'] as String? ?? '',
          origin: data['origin'] as String? ?? '',
          destination: data['destination'] as String? ?? '',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HEADER — Greeting + driver name + settings
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(double topPad, bool isSmall) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat Pagi'
        : now.hour < 17
        ? 'Selamat Siang'
        : 'Selamat Malam';
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Container(
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 12, 24),
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
              Row(
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
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 11 : 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Settings menu ──
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Iconsax.setting_2,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: _C.card,
                    onSelected: (value) {
                      if (value == 'logout') {
                        AuthUtils.showLogoutConfirmation(context);
                      }
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.user_edit,
                              color: _C.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Edit Profil',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.logout,
                              color: _C.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.error,
                              ),
                            ),
                          ],
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
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.06, duration: 500.ms, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────
  //  PAKET CARD — Konfirmasi Paket
  // ─────────────────────────────────────────────────────
  Widget _buildPackageCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPackageConfirmationPage())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.box_2, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Konfirmasi Paket', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Kelola & konfirmasi pengiriman paket', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_1, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SECTION TITLE
  // ─────────────────────────────────────────────────────
  Widget _buildSectionTitle(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            'Armada Anda',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count armada',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  EMPTY STATE — No fleet assigned
  // ─────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _C.warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.car, size: 56, color: _C.warning),
                ),
                const SizedBox(height: 24),
                Text(
                  'Belum Ada Penugasan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada penugasan armada untuk Anda hari ini.\nHubungi Super Admin untuk informasi lebih lanjut.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _C.textTertiary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          delay: 300.ms,
          duration: 500.ms,
        );
  }
}

// ═══════════════════════════════════════════════════════════
//  FLEET CARD — Single Armada Assignment Card
//
//  Displays: fleet name, vehicle type, route
//  Real-time sub-stream counts bookings for this fleet
//  Tappable → navigates to FleetManifestPage
// ═══════════════════════════════════════════════════════════
class _FleetCard extends StatelessWidget {
  final String fleetId;
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onTap;

  const _FleetCard({
    required this.fleetId,
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fleetName = data['name'] as String? ?? 'Armada';
    final vehicleType = data['vehicleType'] as String? ?? '';
    final origin = data['origin'] as String? ?? '';
    final destination = data['destination'] as String? ?? '';
    final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
    final availableSeats = (data['availableSeats'] as num?)?.toInt() ?? 0;
    final bookedSeats = totalSeats - availableSeats;
    final route = (origin.isNotEmpty && destination.isNotEmpty)
        ? '$origin → $destination'
        : '';

    return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.border.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top: Icon + Name + Arrow ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _C.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.car,
                          size: 22,
                          color: _C.success,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fleetName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _C.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (vehicleType.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                vehicleType,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
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

                  const SizedBox(height: 14),

                  // ── Route ──
                  if (route.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _C.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _C.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.route_square,
                            size: 16,
                            color: _C.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              route,
                              style: GoogleFonts.inter(
                                fontSize: 13,
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

                  // ── Bottom: Seat count + View button ──
                  Row(
                    children: [
                      Flexible(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .where('fleetId', isEqualTo: fleetId)
                              .where(
                                'status',
                                whereIn: ['paid', 'validated', 'used'],
                              )
                              .snapshots(),
                          builder: (context, snap) {
                            final ticketCount =
                                snap.data?.docs.length ?? 0;
                            return Row(
                              children: [
                                Flexible(
                                  flex: 0,
                                  child: Icon(
                                    Iconsax.people,
                                    size: 14,
                                    color: _C.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '$ticketCount penumpang',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _C.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  flex: 0,
                                  child: Icon(
                                    Iconsax.driver,
                                    size: 14,
                                    color: _C.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '$bookedSeats/$totalSeats kursi',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _C.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Manifest',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Iconsax.arrow_right_3,
                            size: 16,
                            color: _C.primary,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Mulai Perjalanan ──
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverTripPage(
                              fleetId: fleetId,
                              fleetName: fleetName,
                              origin: origin,
                              destination: destination,
                              vehicleType: vehicleType,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.routing_2, size: 18),
                      label: Text(
                        'Atur Perjalanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: _C.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 + index * 80).ms, duration: 400.ms)
        .slideY(
          begin: 0.06,
          delay: (100 + index * 80).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
