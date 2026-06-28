import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/services/auth_service.dart';
import 'widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda harus menyetujui Syarat & Ketentuan',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AuthColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        namaLengkap: _nameController.text.trim(),
        nomorHp: _phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Akun berhasil dibuat! Silakan masuk.',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AuthColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // Sign out so user must login explicitly after register
      await AuthService.logout();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = 'Terjadi kesalahan saat mendaftar';
      final err = e.toString();
      final type = e.runtimeType.toString();
      if (err.contains('email-already-in-use')) {
        message = 'Email sudah terdaftar, silakan gunakan email lain';
      } else if (err.contains('weak-password')) {
        message = 'Password terlalu lemah, minimal 6 karakter';
      } else if (err.contains('invalid-email')) {
        message = 'Format email tidak valid';
      } else if (err.contains('unauthorized-domain') ||
          err.contains('auth-domain-config-required') ||
          err.contains('origin_mismatch')) {
        message =
            'Domain web belum diizinkan di Firebase Auth. Tambahkan origin yang dipakai browser ini.';
      } else if (err.contains('operation-not-allowed')) {
        message = 'Email/password belum diaktifkan di Firebase Authentication.';
      } else if (err.contains('network-request-failed')) {
        message =
            'Tidak ada koneksi internet atau Firebase sedang tidak merespons.';
      } else if (err.contains('api-key-not-valid')) {
        message =
            'API key Firebase untuk web tidak valid / dibatasi. Cek API key di Google Cloud Console.';
      }

      debugPrint(
        'REGISTER ERROR | type=$type | runtime=$err\n'
        'name=${_nameController.text.trim()} | email=${_emailController.text.trim()} | phone=${_phoneController.text.trim()}\n'
        'agreeToTerms=$_agreeToTerms',
      );

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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AuthScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 28, 0),
              child: Row(
                children: [
                  _buildBackButton()
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: -0.15, duration: 350.ms),
                  const Spacer(),
                  Text(
                    'Langkah 1 dari 1',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AuthColors.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                ],
              ),
            ),

            // ── Scrollable Content ──────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // ── Header ────────────────────
                        const AuthHeader(
                          title: 'Buat Akun Baru',
                          subtitle:
                              'Bergabung dengan E-Travel dan nikmati\nperjalanan nyaman ke seluruh Sumatera Barat.',
                          showLogo: false,
                        ),

                        const SizedBox(height: 36),

                        // ── Name Field ────────────────
                        AuthTextField(
                              controller: _nameController,
                              hintText: 'Nama lengkap Anda',
                              labelText: 'Nama Lengkap',
                              prefixIcon: Iconsax.user,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                if (value.trim().length < 3) {
                                  return 'Nama minimal 3 karakter';
                                }
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(delay: 250.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.1,
                              delay: 250.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 20),

                        // ── Phone Field ───────────────
                        AuthTextField(
                              controller: _phoneController,
                              hintText: '08xxxxxxxxxx',
                              labelText: 'Nomor HP',
                              prefixIcon: Iconsax.call,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor HP tidak boleh kosong';
                                }
                                if (value.trim().length < 10) {
                                  return 'Nomor HP minimal 10 digit';
                                }
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(delay: 325.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.1,
                              delay: 325.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 20),

                        // ── Email Field ───────────────
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
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value.trim())) {
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

                        // ── Password Field ────────────
                        AuthTextField(
                              controller: _passwordController,
                              hintText: 'Minimal 6 karakter',
                              labelText: 'Password',
                              prefixIcon: Iconsax.lock,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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

                        const SizedBox(height: 20),

                        // ── Confirm Password ──────────
                        AuthTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Ulangi password Anda',
                              labelText: 'Konfirmasi Password',
                              prefixIcon: Iconsax.lock_1,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleRegister(),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Icon(
                                    _obscureConfirm
                                        ? Iconsax.eye_slash
                                        : Iconsax.eye,
                                    color: AuthColors.textTertiary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password tidak boleh kosong';
                                }
                                if (value != _passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.1,
                              delay: 700.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 24),

                        // ── Terms Checkbox ────────────
                        _buildTermsCheckbox().animate().fadeIn(
                          delay: 775.ms,
                          duration: 450.ms,
                        ),

                        const SizedBox(height: 28),

                        // ── Register Button ───────────
                        AuthPrimaryButton(
                              text: 'Buat Akun',
                              isLoading: _isLoading,
                              onTap: _handleRegister,
                            )
                            .animate()
                            .fadeIn(delay: 850.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.1,
                              delay: 850.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 28),

                        // ── Login link ────────────────
                        Center(
                          child: AuthLinkText(
                            prefix: 'Sudah punya akun?',
                            actionText: 'Masuk',
                            onTap: () => Navigator.pop(context),
                          ),
                        ).animate().fadeIn(delay: 950.ms, duration: 450.ms),

                        SizedBox(height: bottomPadding + 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _agreeToTerms ? AuthColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: _agreeToTerms
                  ? null
                  : Border.all(color: AuthColors.border, width: 1.5),
            ),
            child: _agreeToTerms
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AuthColors.textTertiary,
                  height: 1.55,
                ),
                children: [
                  const TextSpan(text: 'Saya menyetujui '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AuthColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const TextSpan(text: ' serta '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: GoogleFonts.plusJakartaSans(
                      color: AuthColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const TextSpan(text: ' E-Travel.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
