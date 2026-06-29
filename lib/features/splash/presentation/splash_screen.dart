import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../auth/presentation/login_page.dart';
import '../../navigation/presentation/main_navigation_screen.dart';

// ─────────────────────────────────────────────────────────
//  SPLASH SCREEN — Responsive Trust Blue branded launch
//
//  Layout 100% responsif:
//  • Background: LinearGradient memenuhi seluruh layar
//  • Logo: max 40% lebar layar via MediaQuery (tidak overflow)
//  • Animasi: FadeTransition + ScaleTransition via AnimationController
//  • Footer: Align(bottomCenter) + SafeArea + CircularProgressIndicator
//  • 2s delay → pushReplacement ke MainNav / Login
// ─────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _particleCtrl;
  late final AnimationController _contentCtrl;

  // ── Staggered content animations ──
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    // ── Immersive system chrome ──
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF081F36),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // ── Particle animation (infinite loop) ──
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // ── Content stagger (2.4s total) ──
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Logo: 0% → 45% (fade + scale)
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

    // App name: 20% → 55%
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

    // Tagline: 40% → 70%
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
      ),
    );

    // Bottom (spinner + version): 55% → 85%
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
            opacity:
                CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ─────────────── BUILD ───────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final isSmall = w < 360;

    // Responsive sizes — scales with screen
    final logoSize = (w * 0.24).clamp(72.0, 110.0);
    final logoRadius = (logoSize * 0.28).clamp(20.0, 32.0);
    final iconSize = (logoSize * 0.44).clamp(30.0, 48.0);
    final titleSize = (w * 0.085).clamp(26.0, 40.0);
    final taglineSize = (w * 0.035).clamp(12.0, 16.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Full-screen gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2540),
                  Color(0xFF0F4C81),
                  Color(0xFF1565A8),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── 2. Floating bokeh particles ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _BokehParticlePainter(
                  progress: _particleCtrl.value,
                ),
              ),
            ),
          ),

          // ── 3. Subtle radial glow behind logo ──
          Center(
            child: AnimatedBuilder(
              animation: _logoOpacity,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value * 0.25,
                child: Container(
                  width: w * 0.55,
                  height: w * 0.55,
                  constraints: const BoxConstraints(
                    maxWidth: 280,
                    maxHeight: 280,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Main content — centered, flex layout ──
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
                      child: _buildLogo(
                        logoSize: logoSize,
                        logoRadius: logoRadius,
                        iconSize: iconSize,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.028),

                // ─── App Name ───
                AnimatedBuilder(
                  animation: _contentCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _nameOpacity,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: Text(
                        'Minang Travel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.01),

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

          // ── 5. Footer: spinner + version (always at bottom) ──
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

  // ─── Logo container — responsive ───
  Widget _buildLogo({
    required double logoSize,
    required double logoRadius,
    required double iconSize,
  }) {
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(logoRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F4C81).withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Iconsax.car,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BOKEH PARTICLE PAINTER — Floating soft circles
// ─────────────────────────────────────────────────────────
class _BokehParticlePainter extends CustomPainter {
  final double progress;

  _BokehParticlePainter({required this.progress});

  static final List<_Particle> _particles = List.generate(18, (i) {
    final rng = Random(i * 42 + 7);
    return _Particle(
      baseX: rng.nextDouble(),
      baseY: rng.nextDouble(),
      radius: 2.0 + rng.nextDouble() * 6.0,
      opacity: 0.04 + rng.nextDouble() * 0.10,
      speedX: 0.3 + rng.nextDouble() * 0.5,
      speedY: 0.2 + rng.nextDouble() * 0.4,
      phase: rng.nextDouble() * 2 * pi,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = (p.baseX + sin(progress * 2 * pi * p.speedX + p.phase) * 0.06)
              * size.width;
      final y = (p.baseY + cos(progress * 2 * pi * p.speedY + p.phase) * 0.05)
              * size.height;

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: p.opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BokehParticlePainter old) =>
      progress != old.progress;
}

class _Particle {
  final double baseX, baseY, radius, opacity, speedX, speedY, phase;

  const _Particle({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });
}
