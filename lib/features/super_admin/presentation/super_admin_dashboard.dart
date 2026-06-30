import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'manage_fleet_page.dart';
import 'manage_routes_page.dart';
import 'manage_promo_page.dart';
import 'manage_users_page.dart';
import 'transaction_report_page.dart';
import 'manage_packages_page.dart';
import 'super_admin_drawer.dart';
import 'widgets/menu_card_widget.dart';
import 'widgets/stat_card_widget.dart';

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
//  SUPER ADMIN DASHBOARD — Owner / Central Management
// ═══════════════════════════════════════════════════════════
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  // ── Firestore streams ──
  Stream<QuerySnapshot> get _bookingsStream => FirebaseFirestore.instance
      .collection('bookings')
      .where('status', whereIn: ['paid', 'used', 'completed'])
      .snapshots();

  Stream<QuerySnapshot> get _fleetsStream =>
      FirebaseFirestore.instance.collection('fleets').snapshots();

  Stream<QuerySnapshot> get _routesStream =>
      FirebaseFirestore.instance.collection('routes').snapshots();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final w = mq.size.width;
    final isSmall = w < 360;

    return Scaffold(
      backgroundColor: _C.bg,
      drawer: const SuperAdminDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──────────────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (scaffoldCtx) =>
                  _buildHeader(scaffoldCtx, topPad, isSmall),
            ),
          ),

          // ── REAL-TIME STATS ROW ────────────────
          SliverToBoxAdapter(
            child: _buildRealtimeStatsRow(
              isSmall,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ),

          // ── SECTION LABEL ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
              child: Text(
                'Menu Utama',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
          ),

          // ── MENU GRID ─────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, bottomPad + 32),
            sliver: _buildMenuGrid(context, isSmall),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HEADER (with PopupMenuButton logout)
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double topPad, bool isSmall) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Container(
          padding: EdgeInsets.fromLTRB(22, topPad + 20, 10, 24),
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
                children: [
                  // ── Hamburger menu to open drawer ──
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Iconsax.menu_1,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Owner',
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
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Notification bell (optional placeholder) ──
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 18),
              // Quick summary
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.chart_2, size: 18, color: _C.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Semua layanan beroperasi normal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Online',
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
        .slideY(begin: -0.06, duration: 500.ms, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────
  //  LOGOUT — delegated to AuthUtils (reusable dialog)
  // ─────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────
  //  REAL-TIME STATS (StreamBuilder)
  // ─────────────────────────────────────────────────────
  Widget _buildRealtimeStatsRow(bool isSmall) {
    final currencyFmt = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        // ── Parse data with error handling ──
        String revenueStr = 'Rp 0';
        String ticketStr = '0';
        bool isLoading = false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          isLoading = true;
        } else if (snapshot.hasError) {
          revenueStr = 'Error';
          ticketStr = 'Error';
        } else if (snapshot.hasData) {
          try {
            final docs = snapshot.data!.docs;
            ticketStr = NumberFormat('#,###', 'id_ID').format(docs.length);

            double totalRevenue = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null && data.containsKey('totalPrice')) {
                totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0;
              }
            }
            revenueStr = currencyFmt.format(totalRevenue);
          } catch (e) {
            revenueStr = 'Error';
            ticketStr = 'Error';
          }
        }

        final stats = [
          StatCardData(
            icon: Iconsax.money_recive,
            label: 'Pendapatan Bulan Ini',
            value: revenueStr,
            color: _C.primary,
            bgColor: _C.primary.withValues(alpha: 0.08),
            isLoading: isLoading,
          ),
          StatCardData(
            icon: Iconsax.ticket_2,
            label: 'Tiket Terjual',
            value: ticketStr,
            color: _C.teal,
            bgColor: _C.teal.withValues(alpha: 0.08),
            isLoading: isLoading,
          ),
          StatCardData(
            icon: Iconsax.car,
            label: 'Armada Aktif',
            value: '...',
            color: _C.info,
            bgColor: _C.infoBg,
            isLoading: true,
          ),
          StatCardData(
            icon: Iconsax.route_square,
            label: 'Total Rute',
            value: '...',
            color: _C.warning,
            bgColor: _C.warningBg,
            isLoading: true,
          ),
        ];

        // Wrap fleet + route stats with their own StreamBuilders
        return SizedBox(
          height: isSmall ? 120 : 130,
          child: StreamBuilder<QuerySnapshot>(
            stream: _fleetsStream,
            builder: (ctx, fleetSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: _routesStream,
                builder: (ctx, routeSnap) {
                  // Fleet count
                  if (fleetSnap.hasData) {
                    final count = fleetSnap.data!.docs.length;
                    stats[2] = StatCardData(
                      icon: Iconsax.car,
                      label: 'Armada Aktif',
                      value: NumberFormat('#,###', 'id_ID').format(count),
                      color: _C.info,
                      bgColor: _C.infoBg,
                    );
                  }
                  // Route count
                  if (routeSnap.hasData) {
                    final count = routeSnap.data!.docs.length;
                    stats[3] = StatCardData(
                      icon: Iconsax.route_square,
                      label: 'Total Rute',
                      value: NumberFormat('#,###', 'id_ID').format(count),
                      color: _C.warning,
                      bgColor: _C.warningBg,
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                    itemCount: stats.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        right: i < stats.length - 1 ? 12 : 0,
                      ),
                      child: StatCard(
                        data: stats[i],
                        index: i,
                        isSmall: isSmall,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  MENU GRID
  // ─────────────────────────────────────────────────────
  SliverGrid _buildMenuGrid(BuildContext context, bool isSmall) {
    final items = [
      MenuCardData(
        icon: Iconsax.map,
        label: 'Manajemen Rute\n(Dijkstra)',
        color: _C.primary,
        bgColor: _C.primary.withValues(alpha: 0.08),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageRoutesPage()),
        ),
      ),
      MenuCardData(
        icon: Iconsax.car,
        label: 'Manajemen\nArmada',
        color: _C.teal,
        bgColor: _C.teal.withValues(alpha: 0.08),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageFleetPage()),
        ),
      ),
      MenuCardData(
        icon: Iconsax.people,
        label: 'Manajemen\nUser',
        color: _C.info,
        bgColor: _C.infoBg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageUsersPage()),
        ),
      ),
      MenuCardData(
        icon: Iconsax.chart_square,
        label: 'Laporan\nTransaksi',
        color: _C.warning,
        bgColor: _C.warningBg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionReportPage()),
        ),
      ),
      MenuCardData(
        icon: Iconsax.ticket_discount,
        label: 'Manajemen\nKupon',
        color: _C.success,
        bgColor: _C.successBg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManagePromoPage()),
        ),
      ),
      MenuCardData(
        icon: Iconsax.box,
        label: 'Manajemen\nPaket',
        color: _C.primary,
        bgColor: _C.primary.withValues(alpha: 0.08),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManagePackagesPage()),
        ),
      ),
    ];

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isTablet ? 1.25 : (isSmall ? 1.05 : 1.15),
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => MenuCard(data: items[i], index: i),
        childCount: items.length,
      ),
    );
  }
}
