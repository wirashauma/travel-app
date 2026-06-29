import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/login_page.dart';
import '../../navigation/presentation/main_navigation_screen.dart';

// ─────────────────────────────────────────────────────────
//  SPLASH SCREEN — Modernized Premium Trust Blue branded launch
// ─────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentCtrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F4C81),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );

    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
      ),
    );

    _bottomOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _contentCtrl.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final Widget destination = currentUser != null
        ? const MainNavigationScreen()
        : const LoginPage();

    final bool goingToLogin = currentUser == null;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          goingToLogin ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          goingToLogin ? Colors.white : const Color(0xFFFAFBFD),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final isSmall = w < 360;

    final logoSize = (w * 0.32).clamp(100.0, 140.0);
    final titleSize = (w * 0.085).clamp(26.0, 40.0);
    final taglineSize = (w * 0.035).clamp(12.0, 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F4C81),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main content — centered ──
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ─── Logo Icon ───
                AnimatedBuilder(
                  animation: _contentCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(logoSize: logoSize),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.035),

                // ─── Branded Rich Text App Title ───
                AnimatedBuilder(
                  animation: _contentCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _nameOpacity,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Minang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Travel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF38BDF8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.012),

                // ─── Tagline ───
                AnimatedBuilder(
                  animation: _taglineOpacity,
                  builder: (_, __) => FadeTransition(
                    opacity: _taglineOpacity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                      child: Text(
                        'Perjalanan Nyaman, Kapan Saja',
                        style: GoogleFonts.inter(
                          fontSize: taglineSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.65),
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),

          // ── Footer: spinner + version (always at bottom) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: AnimatedBuilder(
                  animation: _bottomOpacity,
                  builder: (_, __) => FadeTransition(
                    opacity: _bottomOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: isSmall ? 18 : 22,
                          height: isSmall ? 18 : 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Versi 1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({required double logoSize}) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
