import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../admin/presentation/driver_dashboard_page.dart';
import '../../admin/presentation/ticket_scanner_page.dart';
import '../../booking_history/presentation/booking_history_page.dart';
import '../../edit_profile/presentation/edit_profile_page.dart';
import '../../home/presentation/home_search_page.dart';
import '../../package/presentation/package_delivery_page.dart';
import '../../super_admin/presentation/super_admin_dashboard.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color navInactive = Color(0xFF94A3B8);
}

// ═══════════════════════════════════════════════════════════
//  MAIN NAVIGATION SCREEN — Dynamic Role-Based Wrapper
//
//  Flow:
//  1. Ambil UID dari FirebaseAuth.instance.currentUser
//  2. StreamBuilder → stream doc users/{uid}
//  3. Selama loading → Splash/Spinner mulus
//  4. Berdasarkan `role`:
//     • 'user'        → _UserNavShell  (BottomNavigationBar 4 tab)
//     • 'admin'       → _AdminNavShell (BottomAppBar + FAB scanner)
//     • 'super_admin' → SuperAdminDashboard (standalone)
// ═══════════════════════════════════════════════════════════
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ── Safety: Not authenticated → should not happen, but guard ──
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sesi expired. Silakan login kembali.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // ── Loading state — elegant splash ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSplash();
        }

        // ── Error or no data ──
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _ErrorScreen(
            message: snapshot.hasError
                ? 'Gagal memuat profil: ${snapshot.error}'
                : 'Profil pengguna tidak ditemukan.',
            onRetry: () {
              // Force rebuild by navigating to self
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MainNavigationScreen(),
                ),
              );
            },
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final role = data['role'] as String? ?? 'user';

        // ── Check suspended ──
        final isSuspended = data['isSuspended'] == true;
        if (isSuspended) {
          return const _SuspendedScreen();
        }

        // ── Route by role ──
        switch (role) {
          case 'super_admin':
            return const SuperAdminDashboard();
          case 'admin':
            return const _AdminNavShell();
          default:
            return const _UserNavShell();
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LOADING SPLASH — Mulus, clean, branded
// ═══════════════════════════════════════════════════════════
class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F4C81),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F4C81), Color(0xFF0A3A64)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Iconsax.car,
                size: 38,
                color: Colors.white,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: 1800.ms,
                    color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 28),
            Text(
              'E-Travel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mempersiapkan dashboard...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ERROR SCREEN
// ═══════════════════════════════════════════════════════════
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.15)),
                ),
                child: const Icon(Iconsax.warning_2,
                    size: 36, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 20),
              Text(
                'Oops!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: _C.textTertiary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Iconsax.refresh, size: 18),
                label: Text('Coba Lagi',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: _C.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SUSPENDED SCREEN — Account blocked
// ═══════════════════════════════════════════════════════════
class _SuspendedScreen extends StatelessWidget {
  const _SuspendedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                ),
                child: const Icon(Iconsax.shield_cross,
                    size: 36, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 20),
              Text(
                'Akun Di-suspend',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akun Anda telah di-suspend oleh admin.\nSilakan hubungi customer support.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: _C.textTertiary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                icon: const Icon(Iconsax.logout, size: 18),
                label: Text('Keluar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: _C.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  USER NAV SHELL — Modern BottomNavigationBar (4 Tabs)
//
//  Tab 1: Tiket Saya → BookingHistoryPage
//  Tab 2: Pesan Tiket → HomeSearchPage
//  Tab 3: Paket      → PackageDeliveryPage
//  Tab 4: Profil     → EditProfilePage
// ═══════════════════════════════════════════════════════════
class _UserNavShell extends StatefulWidget {
  const _UserNavShell();

  @override
  State<_UserNavShell> createState() => _UserNavShellState();
}

class _UserNavShellState extends State<_UserNavShell> {
  int _currentIndex = 0;

  // ── Pages - cached, not recreated on tab switch ──
  static const List<Widget> _pages = [
    BookingHistoryPage(),
    HomeSearchPage(),
    PackageDeliveryPage(),
    EditProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  // ── Exit confirmation dialog ──
  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _C.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.logout, size: 20, color: _C.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keluar Aplikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari E-Travel?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: _C.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: _C.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text('Ya, Keluar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: _C.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.03),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (index == _currentIndex) return;
                        setState(() => _currentIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: 250.ms,
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active indicator dot (always takes space)
                            Container(
                              height: 3,
                              width: 20,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _C.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Icon
                            Icon(
                              _navIcons[index],
                              size: 22,
                              color: isActive
                                  ? _C.primary
                                  : _C.navInactive,
                            ),
                            const SizedBox(height: 4),
                            // Label
                            Text(
                              _navLabels[index],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? _C.primary
                                    : _C.navInactive,
                                letterSpacing: isActive ? 0.2 : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _navLabels = [
    'Tiket Saya',
    'Pesan Tiket',
    'Paket',
    'Profil',
  ];

  static const _navIcons = <IconData>[
    Iconsax.receipt_1,
    Iconsax.search_normal_1,
    Iconsax.box_2,
    Iconsax.profile_circle,
  ];
}

// ═══════════════════════════════════════════════════════════
//  ADMIN NAV SHELL — Flat Bottom Nav (3 tabs)
//
//  Left:   Manifest → DriverDashboardPage
//  Center: SCAN (elevated, biru) → TicketScannerPage
//  Right:  Profil   → EditProfilePage
// ═══════════════════════════════════════════════════════════
class _AdminNavShell extends StatefulWidget {
  const _AdminNavShell();

  @override
  State<_AdminNavShell> createState() => _AdminNavShellState();
}

class _AdminNavShellState extends State<_AdminNavShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DriverDashboardPage(),
    TicketScannerPage(),
    EditProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _onTabTap(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const TicketScannerPage(),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  // ── Exit confirmation dialog ──
  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _C.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.logout, size: 20, color: _C.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keluar Aplikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari E-Travel?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: _C.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: _C.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text('Ya, Keluar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: _C.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  // ── Manifest ──
                  Expanded(
                    child: _AdminNavTab(
                      icon: Iconsax.clipboard_text,
                      activeIcon: Iconsax.clipboard_text5,
                      label: 'Manifest',
                      isActive: _currentIndex == 0,
                      onTap: () => _onTabTap(0),
                    ),
                  ),

                  // ── SCAN (elevated) ──
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTap(1),
                      child: Transform.translate(
                        offset: const Offset(0, -12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _C.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Iconsax.scan_barcode,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'SCAN',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _C.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Profil ──
                  Expanded(
                    child: _AdminNavTab(
                      icon: Iconsax.profile_circle,
                      activeIcon: Iconsax.profile_circle5,
                      label: 'Profil',
                      isActive: _currentIndex == 2,
                      onTap: () => _onTabTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ADMIN NAV TAB — Single bottom bar item (admin)
// ─────────────────────────────────────────────────────────
class _AdminNavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isActive ? 20 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _C.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? _C.primary : _C.navInactive,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _C.primary : _C.navInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
