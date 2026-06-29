import 'dart:convert';

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/logout_dialog.dart';
import '../../super_admin/presentation/super_admin_dashboard.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Clean Slate / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
}

// ═══════════════════════════════════════════════════════════
//  EDIT PROFILE PAGE
// ═══════════════════════════════════════════════════════════
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ── Cloudinary profile image state ──
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  final _picker = ImagePicker();

  // ── Loading state for Firestore fetch ──
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _fetchProfile();
  }

  /// Fetch current user profile from Firestore and populate controllers
  Future<void> _fetchProfile() async {
    try {
      final data = await AuthService.fetchCurrentUserProfile();
      if (!mounted) return;

      if (data != null) {
        _nameCtrl.text = data['namaLengkap'] ?? '';
        _phoneCtrl.text = data['nomorHp'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
      } else {
        // Fallback: use FirebaseAuth data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _nameCtrl.text = user.displayName ?? '';
          _emailCtrl.text = user.email ?? '';
        }
      }

      setState(() {
        _isLoadingProfile = false;
        _fetchError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _fetchError = 'Gagal memuat profil: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  //  PICK & UPLOAD IMAGE TO CLOUDINARY
  // ─────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    // 1. Pick image from gallery
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // 2. Build multipart request (unsigned upload)
      const cloudName = 'dr5lqvvhy';
      const uploadPreset = 'etravel_preset';
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));

      // 3. Send request
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String;

        setState(() => _profileImageUrl = secureUrl);
        _showSnack('Foto profil berhasil diperbarui', isError: false);
      } else {
        _showSnack(
          'Gagal mengunggah foto (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ── Reusable snackbar helper ──
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Sesi login tidak ditemukan', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    AuthService.updateProfile(
          uid: user.uid,
          namaLengkap: _nameCtrl.text.trim(),
          nomorHp: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        )
        .then((_) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          _showSnack('Profil berhasil diperbarui');

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) Navigator.pop(context);
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          _showSnack('Gagal menyimpan: $e', isError: true);
        });
  }

  // ─────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ═══ APP BAR ═══
            _buildAppBar(),

            // ═══ LOADING / ERROR / CONTENT ═══
            if (_isLoadingProfile)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _C.primary),
                ),
              )
            else if (_fetchError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: _C.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fetchError!,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: _C.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoadingProfile = true;
                              _fetchError = null;
                            });
                            _fetchProfile();
                          },
                          icon: const Icon(Iconsax.refresh, size: 18),
                          label: Text(
                            'Coba Lagi',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // ═══ SCROLLABLE CONTENT ═══
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    // Avatar section
                    _buildAvatarSection(),
                    const SizedBox(height: 32),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Nama Lengkap',
                            controller: _nameCtrl,
                            icon: Iconsax.user,
                            hint: 'Masukkan nama lengkap',
                            delay: 200,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Nomor HP',
                            controller: _phoneCtrl,
                            icon: Iconsax.call,
                            hint: '08xxxxxxxxxx',
                            keyboardType: TextInputType.phone,
                            delay: 280,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nomor HP tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Email',
                            controller: _emailCtrl,
                            icon: Iconsax.sms,
                            hint: 'contoh@email.com',
                            keyboardType: TextInputType.emailAddress,
                            delay: 360,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!v.contains('@')) return 'Format email salah';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── LOG OUT BUTTON ──
                      if (!canGoBack) ...[
                        _buildLogoutButton(),
                        const SizedBox(height: 24),
                      ],

                      // ── APP VERSION (secret backdoor trigger) ──
                      _buildVersionLabel(),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ═══ STICKY BOTTOM BUTTON ═══
        bottomNavigationBar: _isLoadingProfile ? null : _buildBottomButton(),
      );
    }


  // ─────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────
  Widget _buildAppBar() {
    final canGoBack = Navigator.of(context).canPop();

    return Container(
      padding: EdgeInsets.fromLTRB(canGoBack ? 6 : 20, 4, 20, 14),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          // ── Tombol Kembali — only when pushed (not root tab) ──
          if (canGoBack) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: _C.textPrimary,
                size: 20,
              ),
              splashRadius: 22,
              tooltip: 'Kembali',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              canGoBack ? 'Edit Profil' : 'Profil Saya',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─────────────────────────────────────────────────
  //  AVATAR SECTION — Cloudinary-enabled
  // ─────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    final hasImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    final initial = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : 'U';

    return Center(
          child: GestureDetector(
            onTap: _isUploadingImage ? null : _pickAndUploadImage,
            child: Stack(
              children: [
                // ── Main avatar ──
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: _C.primary.withValues(alpha: 0.08),
                    backgroundImage: hasImage
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: hasImage
                        ? null
                        : Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                  ),
                ),

                // ── Upload loading overlay ──
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Camera badge — bottom-right ──
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _C.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.camera,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 450.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          delay: 100.ms,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─────────────────────────────────────────────────
  //  FORM FIELD
  // ─────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required int delay,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _C.textPrimary,
              ),
              cursorColor: _C.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 14, color: _C.textHint),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(icon, size: 18, color: _C.textTertiary),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: _C.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(
          begin: 0.04,
          delay: delay.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─────────────────────────────────────────────────
  //  VERSION LABEL (Developer Backdoor Trigger)
  // ─────────────────────────────────────────────────
  Widget _buildVersionLabel() {
    return Center(
      child: GestureDetector(
        onLongPress: _showDevOverrideDialog,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'App Version 1.0.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _C.textTertiary,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 400.ms);
  }

  // ─────────────────────────────────────────────────
  //  DEVELOPER OVERRIDE DIALOG
  // ─────────────────────────────────────────────────
  void _showDevOverrideDialog() {
    final keyCtrl = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _C.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.shield_tick,
                      size: 26,
                      color: _C.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Developer Override',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan secret key untuk melanjutkan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _C.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Secret key input
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  enabled: !isProcessing,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                    letterSpacing: 1.2,
                  ),
                  cursorColor: _C.primary,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '• • • • • • • •',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: _C.textHint,
                    ),
                    filled: true,
                    fillColor: _C.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _C.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                if (isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: _C.primary),
                  )
                else
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              keyCtrl.dispose();
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _C.textSecondary,
                              side: BorderSide(color: _C.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Submit
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              final key = keyCtrl.text.trim();
                              if (key != 'ENN-SUPER-2026') {
                                keyCtrl.dispose();
                                Navigator.pop(ctx);
                                _showSnack('Invalid Key', isError: true);
                                return;
                              }

                              // Valid key — show loading
                              setDialogState(() => isProcessing = true);

                              try {
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) throw 'User not found';

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({'role': 'super_admin'});

                                keyCtrl.dispose();
                                if (!context.mounted) return;
                                Navigator.pop(ctx); // close dialog

                                _showSnack(
                                  'Akses Super Admin Terbuka!',
                                  isError: false,
                                );

                                // Navigate to Super Admin Dashboard
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SuperAdminDashboard(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                setDialogState(() => isProcessing = false);
                                if (!context.mounted) return;
                                keyCtrl.dispose();
                                Navigator.pop(ctx);
                                _showSnack('Gagal: $e', isError: true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
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

  // ─────────────────────────────────────────────────
  //  LOG OUT BUTTON
  // ─────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => AuthUtils.showLogoutConfirmation(context),
            icon: const Icon(Iconsax.logout, size: 18),
            label: Text(
              'Keluar dari Akun',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC4A4A),
              side: const BorderSide(color: Color(0xFFDC4A4A), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 450.ms, duration: 400.ms)
        .slideY(
          begin: 0.04,
          delay: 450.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─────────────────────────────────────────────────
  //  LOG OUT — delegated to AuthUtils (reusable dialog)
  // ─────────────────────────────────────────────────

  // ─────────────────────────────────────────────────
  //  STICKY BOTTOM BUTTON
  // ─────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
            decoration: BoxDecoration(
              color: _C.white,
              border: const Border(
                top: BorderSide(color: _C.borderLight, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F4C81).withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _C.primary.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: _C.primary.withValues(alpha: 0.6),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 450.ms, duration: 400.ms)
        .slideY(begin: 0.08, delay: 450.ms, duration: 400.ms);
  }
}
