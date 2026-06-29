import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore_for_file: unused_field, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/logout_dialog.dart';
import '../../edit_profile/presentation/edit_profile_page.dart';
import 'manage_driver_assignments_page.dart';
import 'manage_fleet_page.dart';
import 'manage_promo_page.dart';
import 'manage_routes_page.dart';
import 'manage_users_page.dart';
import 'transaction_report_page.dart';
import 'manage_packages_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (shared with Super Admin)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color info = Color(0xFF0284C7);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
}

// ─────────────────────────────────────────────────────────
//  MENU INDEX — for `selected` state tracking
// ─────────────────────────────────────────────────────────
enum SuperAdminMenu {
  dashboard,
  fleet,
  driverAssignment,
  routes,
  promo,
  users,
  report,
  packages,
}

// ═══════════════════════════════════════════════════════════
//  SUPER ADMIN DRAWER — Sidebar navigation for Owner role
//
//  • Custom header with avatar, name, email from Firestore
//  • 6 main menu items with selected highlight
//  • Footer: Pengaturan / Logout
//  • Callback `onMenuSelected` agar parent bisa menutup drawer
//    dan menavigasi sesuai menu yang dipilih
// ═══════════════════════════════════════════════════════════
class SuperAdminDrawer extends StatelessWidget {
  final SuperAdminMenu currentMenu;
  final void Function(SuperAdminMenu menu)? onMenuSelected;

  const SuperAdminDrawer({
    super.key,
    this.currentMenu = SuperAdminMenu.dashboard,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _C.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Custom Drawer Header ──
          _buildHeader(context),

          // ── Section label ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // ── Main menu items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              physics: const BouncingScrollPhysics(),
              children: [
                _DrawerMenuItem(
                  icon: Iconsax.category_2,
                  activeIcon: Iconsax.category5,
                  label: 'Dashboard',
                  isSelected: currentMenu == SuperAdminMenu.dashboard,
                  onTap: () => _handleTap(context, SuperAdminMenu.dashboard),
                  index: 0,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.car,
                  activeIcon: Iconsax.car,
                  label: 'Manajemen Armada',
                  isSelected: currentMenu == SuperAdminMenu.fleet,
                  onTap: () => _handleTap(context, SuperAdminMenu.fleet),
                  index: 1,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.user_tag,
                  activeIcon: Iconsax.user_tag,
                  label: 'Penugasan Supir',
                  subtitle: 'Assign driver ke armada',
                  isSelected: currentMenu == SuperAdminMenu.driverAssignment,
                  onTap: () =>
                      _handleTap(context, SuperAdminMenu.driverAssignment),
                  index: 2,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.map,
                  activeIcon: Iconsax.map5,
                  label: 'Manajemen Rute',
                  subtitle: 'Dijkstra Algorithm',
                  isSelected: currentMenu == SuperAdminMenu.routes,
                  onTap: () => _handleTap(context, SuperAdminMenu.routes),
                  index: 3,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.ticket_discount,
                  activeIcon: Iconsax.ticket_discount,
                  label: 'Manajemen Promo',
                  isSelected: currentMenu == SuperAdminMenu.promo,
                  onTap: () => _handleTap(context, SuperAdminMenu.promo),
                  index: 4,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.people,
                  activeIcon: Iconsax.people5,
                  label: 'Manajemen User',
                  isSelected: currentMenu == SuperAdminMenu.users,
                  onTap: () => _handleTap(context, SuperAdminMenu.users),
                  index: 5,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.chart_square,
                  activeIcon: Iconsax.chart_square,
                  label: 'Laporan Transaksi',
                  isSelected: currentMenu == SuperAdminMenu.report,
                  onTap: () => _handleTap(context, SuperAdminMenu.report),
                  index: 6,
                ),
                _DrawerMenuItem(
                  icon: Iconsax.box,
                  activeIcon: Iconsax.box,
                  label: 'Manajemen Paket',
                  isSelected: currentMenu == SuperAdminMenu.packages,
                  onTap: () => _handleTap(context, SuperAdminMenu.packages),
                  index: 7,
                ),
              ],
            ),
          ),

          // ── FOOTER ──
          const _DrawerDivider(),

          // Pengaturan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _DrawerMenuItem(
              icon: Iconsax.setting_2,
              activeIcon: Iconsax.setting_25,
              label: 'Pengaturan',
              isSelected: false,
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
              index: 7,
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: _DrawerMenuItem(
              icon: Iconsax.logout,
              activeIcon: Iconsax.logout,
              label: 'Logout',
              isSelected: false,
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop(); // close drawer first
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (context.mounted) {
                    AuthUtils.showLogoutConfirmation(context);
                  }
                });
              },
              index: 8,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ─── Handle menu tap ───
  void _handleTap(BuildContext context, SuperAdminMenu menu) {
    Navigator.pop(context); // close drawer first

    if (menu == currentMenu) return; // already on this page

    if (onMenuSelected != null) {
      onMenuSelected!(menu);
      return;
    }

    // Default: navigate using push
    Widget? page;
    switch (menu) {
      case SuperAdminMenu.dashboard:
        return; // already on dashboard, nothing to push
      case SuperAdminMenu.fleet:
        page = const ManageFleetPage();
      case SuperAdminMenu.driverAssignment:
        page = const ManageDriverAssignmentsPage();
      case SuperAdminMenu.routes:
        page = const ManageRoutesPage();
      case SuperAdminMenu.promo:
        page = const ManagePromoPage();
      case SuperAdminMenu.users:
        page = const ManageUsersPage();
       case SuperAdminMenu.report:
        page = const TransactionReportPage();
      case SuperAdminMenu.packages:
        page = const ManagePackagesPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  // ─── Custom Drawer Header ───
  Widget _buildHeader(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2540), Color(0xFF0F4C81), Color(0xFF1A6BB5)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: uid == null
            ? _buildHeaderContent(
                name: 'Super Admin',
                email: '-',
                photoUrl: null,
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (ctx, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                  final name =
                      (data['namaLengkap'] as String?) ?? 'Super Admin';
                  final email = (data['email'] as String?) ?? '-';
                  final photoUrl = data['profileImageUrl'] as String?;

                  return _buildHeaderContent(
                    name: name,
                    email: email,
                    photoUrl: photoUrl,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeaderContent({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : 'SA';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // ── Name ──
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // ── Email ──
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // ── Role badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.teal.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.teal.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.shield_tick5,
                  size: 12,
                  color: const Color(0xFF5EEAD4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Super Admin',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5EEAD4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────
//  DRAWER MENU ITEM — with selected highlight
// ─────────────────────────────────────────────────────────
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;
  final int index;

  const _DrawerMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    this.isDestructive = false,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isDestructive
        ? _C.error
        : isSelected
        ? _C.primary
        : _C.textSecondary;

    final Color bgColor = isSelected
        ? _C.primary.withValues(alpha: 0.06)
        : Colors.transparent;

    return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: _C.primary.withValues(alpha: 0.08),
              highlightColor: _C.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // ── Icon ──
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _C.primary.withValues(alpha: 0.10)
                            : isDestructive
                            ? _C.error.withValues(alpha: 0.06)
                            : _C.borderLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        size: 18,
                        color: itemColor,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ── Label ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: itemColor,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Selected indicator ──
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _C.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * index),
          duration: 300.ms,
        )
        .slideX(
          begin: -0.05,
          delay: Duration(milliseconds: 40 * index),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────────────────────────────────────
//  DRAWER DIVIDER — styled separator
// ─────────────────────────────────────────────────────────
class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: _C.border.withValues(alpha: 0.6),
      ),
    );
  }
}
