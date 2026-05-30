import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Light status bar for white background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
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
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        await AuthService.logout();
        return;
      }

      // All roles go through the centralized navigation wrapper
      // MainNavigationScreen reads the role from Firestore and renders
      // the appropriate shell (user BottomNav / admin FAB / super admin dashboard)
      const destination = MainNavigationScreen();

      setState(() => _isLoading = false);

      // Restore dark status bar for main app
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ));

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
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────
  //  GOOGLE SIGN-IN
  // ─────────────────────────────────────────────────────
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      // 1. Trigger the Google Sign-In flow
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      // 2. Obtain auth details from the request
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase with Google credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Login gagal — user null');
      }

      // 4. Check / create Firestore user document
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // First-time Google login → create Firestore profile with role 'user'
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
        // Existing user → check if suspended
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
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          await AuthService.logout();
          await GoogleSignIn().signOut();
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      // 5. Navigate to main app
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ));

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
        return; // user cancelled, no error message
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
              borderRadius: BorderRadius.circular(10)),
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
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
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
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AuthScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight -
                  MediaQuery.of(context).padding.top -
                  bottomPadding,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.08),

                    // ── Header ────────────────────────────
                    const AuthHeader(
                      title: 'Selamat Datang\nKembali!',
                      subtitle:
                          'Masuk ke akun Anda untuk memesan\nperjalanan nyaman ke seluruh Jawa.',
                    ),

                    SizedBox(height: screenHeight * 0.045),

                    // ── Email Field ───────────────────────
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'contoh@email.com',
                      labelText: 'Alamat Email',
                      prefixIcon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 450.ms)
                        .slideY(
                          begin: 0.1,
                          delay: 400.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 20),

                    // ── Password Field ────────────────────
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
                            () => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Icon(
                            _obscurePassword
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
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
                    )
                        .animate()
                        .fadeIn(delay: 550.ms, duration: 450.ms)
                        .slideY(
                          begin: 0.1,
                          delay: 550.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 14),

                    // ── Forgot Password Link ──────────────
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
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 450.ms),

                    const SizedBox(height: 32),

                    // ── Login Button ──────────────────────
                    AuthPrimaryButton(
                      text: 'Login',
                      isLoading: _isLoading,
                      onTap: _handleLogin,
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 450.ms)
                        .slideY(
                          begin: 0.1,
                          delay: 800.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 28),

                    // ── Divider ───────────────────────────
                    const AuthDivider(text: 'atau masuk dengan')
                        .animate()
                        .fadeIn(delay: 950.ms, duration: 450.ms),

                    const SizedBox(height: 20),

                    // ── Google Button ─────────────────────
                    GoogleLoginButton(onTap: _handleGoogleSignIn)
                        .animate()
                        .fadeIn(delay: 1050.ms, duration: 450.ms)
                        .slideY(
                          begin: 0.08,
                          delay: 1050.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 36),

                    // ── Register link ─────────────────────
                    Center(
                      child: AuthLinkText(
                        prefix: 'Belum punya akun?',
                        actionText: 'Daftar',
                        onTap: _navigateToRegister,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 450.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
