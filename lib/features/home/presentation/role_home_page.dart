import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';

class TabSwitchNotification extends Notification {
  final int tabIndex;
  const TabSwitchNotification(this.tabIndex);
}

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
}

// ═══════════════════════════════════════════════════════════
//  PASSENGER HOME SCREEN
// ═══════════════════════════════════════════════════════════
class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    TabSwitchNotification(tabIndex).dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Belum login')));

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['namaLengkap'] as String? ?? user.displayName ?? 'Pengguna';

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            color: _C.primary,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER BLOCK ──
                  _buildHeader(context, name),

                  const SizedBox(height: 56),

                  // ── UPCOMING TRIP SECTION ──
                  _buildUpcomingTripSection(context, user.uid),

                  const SizedBox(height: 28),

                  // ── PROMOTIONS CAROUSEL ──
                  _buildPromotions(context),

                  const SizedBox(height: 28),

                  // ── POPULAR RUTES ──
                  _buildPopularRoutes(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Blue Container containing header text and background circle
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 76),
          decoration: const BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              // Background subtle design circle
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $name 👋',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_greeting, mau bepergian ke mana hari ini?',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToTab(context, 4), // Profil
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white12,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
        // 2. Floating card positioned at the bottom boundary
        Positioned(
          left: 32,
          right: 32,
          bottom: -32,
          child: _buildLayananUtamaCard(context),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildLayananUtamaCard(BuildContext context) {
    final services = [
      ('Pesan Tiket', Iconsax.ticket, _C.primary, 2),
      ('Kirim Paket', Iconsax.box_2, _C.success, 1),
      ('Riwayat', Iconsax.receipt_2, _C.warning, 3),
      ('Bantuan CS', Iconsax.message_question, Colors.purple, -1),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: services.map((s) {
          final (label, icon, color, tabIdx) = s;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (tabIdx >= 0) {
                  _navigateToTab(context, tabIdx);
                } else {
                  // Navigate to Bantuan / CS
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Layanan Pelanggan WhatsApp: +62 812-3456-7890',
                          style: GoogleFonts.inter(fontSize: 13)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingTripSection(BuildContext context, String userId) {
    return StreamBuilder<List<BookingModel>>(
      stream: BookingService.userBookingsStream(userId),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        // Filter for upcoming booking: status pending/paid/validated and departure date is not past
        final upcoming = bookings.where((b) {
          return b.status == BookingStatus.paid || b.status == BookingStatus.validated;
        }).toList();

        if (upcoming.isEmpty) return const SizedBox.shrink();

        final ticket = upcoming.first;
        final formattedPrice = NumberFormat('#,###', 'id_ID').format(ticket.totalPrice);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Perjalanan Mendatang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToTab(context, 3), // Riwayat
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Header ticket
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: _C.primary.withValues(alpha: 0.03),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.bookingCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _C.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _C.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Sudah Bayar',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _C.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Details ticket
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kota Asal',
                                        style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text(ticket.origin,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
                                  ],
                                ),
                                const Icon(Iconsax.arrow_right_3, size: 16, color: _C.textTertiary),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Kota Tujuan',
                                        style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text(ticket.destination,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: _C.borderLight),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Iconsax.calendar, size: 14, color: _C.textTertiary),
                                    const SizedBox(width: 6),
                                    Text(
                                      ticket.departureDate,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _C.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rp $formattedPrice',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _C.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildPromotions(BuildContext context) {
    final promos = [
      ('Promo Lebaran', 'Diskon Mudik 20% ke semua rute Minang Travel', 'Diskon 20%', 'mudik_promo'),
      ('Kirim Paket Hemat', 'Ongkir hemat paket sedang cuma Rp 20.000', 'Hemat Ongkir', 'paket_promo'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Promo Spesial Untukmu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final (title, desc, badge, _) = promos[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.75,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: index == 0
                        ? [const Color(0xFF0F4C81), const Color(0xFF1E88E5)]
                        : [const Color(0xFF00796B), const Color(0xFF00BFA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildPopularRoutes(BuildContext context) {
    final routes = [
      ('Padang', 'Bukittinggi', 'Rp 45.000', '2 Jam'),
      ('Padang', 'Payakumbuh', 'Rp 55.000', '3 Jam'),
      ('Bukittinggi', 'Pekanbaru', 'Rp 120.000', '6 Jam'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Rute Populer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final (from, to, price, duration) = routes[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          from,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 10, color: _C.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            to,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  DRIVER HOME SCREEN
// ═══════════════════════════════════════════════════════════
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  void _navigateToTab(BuildContext context, int tabIndex) {
    TabSwitchNotification(tabIndex).dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Belum login')));

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = userData['namaLengkap'] as String? ?? user.displayName ?? 'Supir';

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            color: _C.primary,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER BLOCK ──
                  _buildDriverHeader(context, name),

                  const SizedBox(height: 24),

                  // ── TODAY STATS ROW ──
                  _buildTodayStatsGrid(),

                  const SizedBox(height: 28),

                  // ── QUICK ACTIONS ──
                  _buildDriverActionGrid(context),

                  const SizedBox(height: 28),

                  // ── ACTIVE ASSIGNED ROUTE Manifest ──
                  _buildDriverAssignmentCard(context, user.uid),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverHeader(BuildContext context, String name) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _C.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 16, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9 Driver',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selamat Bekerja,',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _navigateToTab(context, 3), // Profil
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white12,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildTodayStatsGrid() {
    final stats = [
      ('Pendapatan', 'Rp 450K', Iconsax.money_send, _C.success),
      ('Penumpang', '18 Orang', Iconsax.people, _C.primary),
      ('Jadwal Trip', '2 Rute', Iconsax.routing, _C.warning),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Hari Ini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: stats.map((st) {
              final (label, val, icon, color) = st;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(height: 12),
                      Text(
                        val,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildDriverActionGrid(BuildContext context) {
    final actions = [
      ('Scan Tiket', Iconsax.scan_barcode, _C.primary, 2),
      ('Manifest Trip', Iconsax.clipboard_text, _C.warning, 1),
      ('Pesan CS WhatsApp', Iconsax.call, _C.success, -1),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Kerja',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: actions.map((act) {
              final (label, icon, color, tabIdx) = act;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (tabIdx >= 0) {
                      _navigateToTab(context, tabIdx);
                    } else {
                      // WhatsApp support
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menghubungi Admin CS Minang Travel...',
                              style: GoogleFonts.inter(fontSize: 13)),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, size: 24, color: color),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildDriverAssignmentCard(BuildContext context, String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fleets')
          .where('driverId', isEqualTo: driverId)
          .snapshots(),
      builder: (context, snapshot) {
        final fleets = snapshot.data?.docs ?? [];
        if (fleets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.warningBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Iconsax.info_circle, color: _C.warning, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Belum Ada Penugasan Rute',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _C.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anda belum ditugaskan untuk mengendarai armada aktif saat ini.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _C.warning.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final fleetDoc = fleets.first;
        final fleet = fleetDoc.data() as Map<String, dynamic>;
        final fName = fleet['name'] as String? ?? 'Armada Travel';
        final fPlate = fleet['plateNumber'] as String? ?? '';
        final fOrigin = fleet['origin'] as String? ?? '';
        final fDest = fleet['destination'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tugas Rute Aktif',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: _C.primary.withValues(alpha: 0.03),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _C.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _C.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                fPlate,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _C.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Asal',
                                        style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text(fOrigin,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
                                  ],
                                ),
                                const Icon(Iconsax.arrow_right_3, size: 16, color: _C.textTertiary),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Tujuan',
                                        style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text(fDest,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: _C.borderLight),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToTab(context, 1), // Manifest
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                'Buka Manifest Penumpang',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
      },
    );
  }
}
