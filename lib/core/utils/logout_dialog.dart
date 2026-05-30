import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../features/auth/presentation/login_page.dart';

// ═══════════════════════════════════════════════════════════
//  AUTH UTILS — Reusable Logout Confirmation Dialog
//
//  Digunakan di SEMUA role (User, Admin/Sopir, Super Admin)
//  agar UI dan logika logout konsisten & premium.
//
//  Penggunaan:
//    AuthUtils.showLogoutConfirmation(context);
//
//  ARSITEKTUR:
//  Sign-out + navigasi dilakukan LANGSUNG di dalam widget
//  dialog (_LogoutDialog) menggunakan context dialog sendiri.
//  Ini menghindari bug "dead outer context" yang terjadi
//  ketika pemanggil (misal Drawer) sudah di-dispose sebelum
//  dialog ditutup.
// ═══════════════════════════════════════════════════════════
class AuthUtils {
  AuthUtils._(); // prevent instantiation

  /// Menampilkan dialog konfirmasi logout premium.
  ///
  /// Seluruh logika (signOut → navigate) berjalan di dalam
  /// dialog widget menggunakan context-nya sendiri yang
  /// dijamin masih mounted saat tombol ditekan.
  static Future<void> showLogoutConfirmation(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'logout_dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, a1, a2, child) {
        final curved = CurvedAnimation(parent: a1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => const _LogoutDialog(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PRIVATE — Premium Logout Dialog Widget
//
//  Semua logika sign-out & navigasi ada DI SINI,
//  menggunakan dialog's own context yang selalu mounted.
// ═══════════════════════════════════════════════════════════
class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog();

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _isLoading = false;

  // ── Colors ──
  static const _red = Color(0xFFDC2626);
  static const _redLight = Color(0xFFFEF2F2);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF475569);
  static const _border = Color(0xFFE2E8F0);
  static const _primaryBlue = Color(0xFF0F4C81);

  // ─────────────────────────────────────────────────
  //  LOGOUT HANDLER — Eksekusi berurutan yang aman
  // ─────────────────────────────────────────────────
  Future<void> _performLogout() async {
    setState(() => _isLoading = true);

    try {
      // 1. Sign out dari Firebase
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 2. Tutup dialog + bersihkan seluruh stack → LoginPage
      //    pushAndRemoveUntil dengan rootNavigator: true
      //    otomatis menutup dialog (karena dialog juga ada di
      //    root overlay) dan membersihkan semua route sekaligus.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Tutup dialog dulu, lalu tampilkan snackbar error
      Navigator.of(context, rootNavigator: true).pop();

      // Cari ScaffoldMessenger terdekat dari root
      ScaffoldMessenger.maybeOf(context)
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal logout: $e',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 8,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _redLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _red.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Iconsax.logout, size: 30, color: _red),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Title ──
                Text(
                  'Keluar dari E-Travel?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // ── Description ──
                Text(
                  'Apakah Anda yakin ingin keluar?\nAnda harus login kembali untuk masuk.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: _textSecondary,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // ── Buttons ──
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context, rootNavigator: true).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryBlue,
                            side: BorderSide(
                              color: _border,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Confirm — langsung sign out + navigate di sini
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _performLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.redAccent.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Ya, Keluar',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}
