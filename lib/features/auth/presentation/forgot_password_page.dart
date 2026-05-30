import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak permintaan. Coba lagi nanti.';
          break;
        default:
          message = e.message ?? 'Gagal mengirim email reset.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Terjadi kesalahan. Coba lagi.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 28, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AuthColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AuthColors.border),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left,
                        color: AuthColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: -0.15, duration: 350.ms),
                ],
              ),
            ),

            // ── Content ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _emailSent
                      ? _buildSuccessState()
                      : _buildFormState(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),

          // ── Icon ────────────────────────────────
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuthColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Iconsax.lock_1,
                size: 32,
                color: AuthColors.primary.withValues(alpha: 0.85),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 28),

          // ── Header ──────────────────────────────
          const AuthHeader(
            title: 'Lupa Password?',
            subtitle:
                'Tenang saja! Masukkan email yang terdaftar\ndan kami akan mengirimkan instruksi untuk\nmengatur ulang password Anda.',
            showLogo: false,
            centerAlign: true,
          ),

          const SizedBox(height: 40),

          // ── Email Field ─────────────────────────
          AuthTextField(
            controller: _emailController,
            hintText: 'contoh@email.com',
            labelText: 'Alamat Email',
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendReset(),
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
              .fadeIn(delay: 350.ms, duration: 450.ms)
              .slideY(
                begin: 0.1,
                delay: 350.ms,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 32),

          // ── Send Button ─────────────────────────
          AuthPrimaryButton(
            text: 'Kirim Link Reset',
            isLoading: _isLoading,
            onTap: _handleSendReset,
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 450.ms)
              .slideY(
                begin: 0.1,
                delay: 500.ms,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 32),

          // ── Back to login ───────────────────────
          Center(
            child: AuthLinkText(
              prefix: 'Ingat password Anda?',
              actionText: 'Kembali ke Login',
              onTap: () => Navigator.pop(context),
            ),
          ).animate().fadeIn(delay: 650.ms, duration: 450.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),

        // ── Success Icon ──────────────────────────
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AuthColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.tick_circle,
            size: 42,
            color: AuthColors.success.withValues(alpha: 0.85),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 350.ms),

        const SizedBox(height: 28),

        // ── Success Title ─────────────────────────
        Text(
          'Email Terkirim!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AuthColors.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 250.ms, duration: 450.ms)
            .slideY(begin: 0.12, delay: 250.ms, duration: 450.ms),

        const SizedBox(height: 12),

        // ── Success desc ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AuthColors.textTertiary,
                height: 1.6,
              ),
              children: [
                const TextSpan(
                    text: 'Kami telah mengirimkan instruksi reset\npassword ke '),
                TextSpan(
                  text: _emailController.text,
                  style: GoogleFonts.plusJakartaSans(
                    color: AuthColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                    text: '.\nSilakan cek inbox atau folder spam Anda.'),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 450.ms)
            .slideY(begin: 0.08, delay: 400.ms, duration: 450.ms),

        const SizedBox(height: 24),

        // ── Info card ─────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuthColors.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AuthColors.info.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.info_circle,
                color: AuthColors.info.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Link reset berlaku selama 30 menit.\nPeriksa email Anda segera.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AuthColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 450.ms)
            .slideY(begin: 0.08, delay: 600.ms, duration: 450.ms),

        const SizedBox(height: 32),

        // ── Back to login button ──────────────────
        AuthPrimaryButton(
          text: 'Kembali ke Login',
          onTap: () => Navigator.pop(context),
        )
            .animate()
            .fadeIn(delay: 750.ms, duration: 450.ms)
            .slideY(begin: 0.1, delay: 750.ms, duration: 450.ms),

        const SizedBox(height: 16),

        // ── Resend link ───────────────────────────
        GestureDetector(
          onTap: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            'Kirim ulang email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AuthColors.primary,
            ),
          ),
        ).animate().fadeIn(delay: 900.ms, duration: 450.ms),
      ],
    );
  }
}
