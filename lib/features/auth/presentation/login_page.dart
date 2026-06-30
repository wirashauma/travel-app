import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/services/auth_service.dart';
import '../../navigation/presentation/main_navigation_screen.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  GoogleSignIn? _googleSignIn;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }
    // Light status bar icons for blue background header
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Check if account is suspended
      final isSuspended = userData['isSuspended'] == true;
      if (isSuspended) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun Anda telah di-suspend. Hubungi admin.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AuthColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        await AuthService.logout();
        return;
      }

      const destination = MainNavigationScreen();

      setState(() => _isLoading = false);

      // Restore status bar settings
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0F0F1A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = 'Terjadi kesalahan saat login';
      final err = e.toString();
      if (err.contains('user-not-found') ||
          err.contains('invalid-credential')) {
        message = 'Email atau password salah';
      } else if (err.contains('wrong-password')) {
        message = 'Password salah, coba lagi';
      } else if (err.contains('too-many-requests')) {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
      } else if (err.contains('invalid-email')) {
        message = 'Format email tidak valid';
      } else if (err.contains('network-request-failed')) {
        message = 'Tidak ada koneksi internet';
      } else if (err.contains('unauthorized-domain') ||
          err.contains('auth-domain-config-required') ||
          err.contains('origin_mismatch')) {
        message =
            'Domain/origin web belum diizinkan di Firebase Auth atau Google Cloud.';
      } else if (err.contains('operation-not-allowed')) {
        message =
            'Login email/password belum diaktifkan di Firebase Authentication.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AuthColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Login gagal — user null');
      }

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'namaLengkap': user.displayName ?? '',
          'nomorHp': user.phoneNumber ?? '',
          'role': 'user',
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = userDoc.data()!;
        if (data['isSuspended'] == true) {
          if (mounted) {
            setState(() => _isGoogleLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Akun Anda telah di-suspend. Hubungi admin.',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: AuthColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          await AuthService.logout();
          await _googleSignIn?.signOut();
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0F0F1A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      String message = 'Login Google gagal';
      final err = e.toString();
      if (err.contains('network_error') ||
          err.contains('network-request-failed')) {
        message = 'Tidak ada koneksi internet';
      } else if (err.contains('sign_in_cancelled')) {
        return;
      } else if (err.contains('origin_mismatch') ||
          err.contains('unauthorized_domain')) {
        message =
            'Origin web belum diizinkan di Google Cloud/Firebase Auth. Tambahkan origin yang dipakai browser ini.';
      } else if (err.contains('popup_closed')) {
        message =
            'Popup login Google ditutup sebelum selesai. Coba klik lagi dan jangan tutup jendelanya.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AuthColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegisterPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeOut).animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ForgotPasswordPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeOut).animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _quickLoginButton({
    required String label,
    required String email,
    required Color color,
  }) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: _isLoading || _isGoogleLoading
            ? null
            : () {
                _emailController.text = email;
                _passwordController.text = '12345678';
                _handleLogin();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AuthColors.primary,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AuthColors.primary, AuthColors.primaryDark],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Upper section: Blue Header + Logo + Text ────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 32, 28, 40),
                child: Column(
                  children: [
                    // Circular App Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(duration: 350.ms),
                    const SizedBox(height: 18),
                    Text(
                      'Selamat Datang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk ke akun Anda',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
                  ],
                ),
              ),

              // ── Lower section: White Form Card ──────────────────────────────────
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isTablet ? 520 : double.infinity),
                  margin: isTablet ? const EdgeInsets.symmetric(vertical: 24, horizontal: 28) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isTablet 
                        ? BorderRadius.circular(24) 
                        : const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: isTablet ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ] : null,
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Akun',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AuthColors.textPrimary,
                        ),
                      ).animate().fadeIn(duration: 350.ms),
                      const SizedBox(height: 24),

                      // Email Field
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'Masukkan no. hp atau email',
                        labelText: 'No. HP / Email',
                        prefixIcon: Iconsax.user,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No. HP / Email tidak boleh kosong';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 150.ms, duration: 450.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                      const SizedBox(height: 20),

                      // Password Field
                      AuthTextField(
                        controller: _passwordController,
                        hintText: 'Masukkan password',
                        labelText: 'Password',
                        prefixIcon: Iconsax.lock,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                              color: AuthColors.textTertiary,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 250.ms, duration: 450.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                      const SizedBox(height: 12),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _navigateToForgotPassword,
                          child: Text(
                            'Lupa Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AuthColors.primary,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 450.ms),

                      const SizedBox(height: 28),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Masuk',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 450.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                      const SizedBox(height: 24),

                      // Divider
                      const AuthDivider(
                        text: 'atau masuk dengan',
                      ).animate().fadeIn(delay: 550.ms, duration: 450.ms),

                      const SizedBox(height: 20),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AuthColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://developers.google.com/identity/images/g-logo.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Lanjutkan dengan Google',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AuthColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 650.ms, duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),

                      const SizedBox(height: 28),

                      // Quick Login Section
                      Center(
                        child: Text(
                          'Quick Login (Demo)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AuthColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _quickLoginButton(
                            label: 'Super Admin',
                            email: 'superadmin@gmail.com',
                            color: const Color(0xFFDC2626),
                          ),
                          _quickLoginButton(
                            label: 'Sopir',
                            email: 'supir@gmail.com',
                            color: const Color(0xFFD97706),
                          ),
                          _quickLoginButton(
                            label: 'User',
                            email: 'user@gmail.com',
                            color: const Color(0xFF0D9488),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms, duration: 450.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),

                      const SizedBox(height: 36),

                      // Footer Link: Register Account
                      Center(
                        child: AuthLinkText(
                          prefix: 'Belum punya akun?',
                          actionText: 'Daftar Sekarang',
                          onTap: _navigateToRegister,
                        ),
                      ).animate().fadeIn(delay: 900.ms, duration: 450.ms),

                      if (!isTablet)
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
