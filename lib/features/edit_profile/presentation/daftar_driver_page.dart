import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
}

class DaftarDriverPage extends StatefulWidget {
  const DaftarDriverPage({super.key});

  @override
  State<DaftarDriverPage> createState() => _DaftarDriverPageState();
}

class _DaftarDriverPageState extends State<DaftarDriverPage> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _formKey1 = GlobalKey<FormState>();
  final _ktpCtrl = TextEditingController();
  final _simCtrl = TextEditingController();

  final _formKey2 = GlobalKey<FormState>();
  String? _preferredCity = 'Padang';
  String? _preferredVehicle = 'Toyota Hiace';

  bool _ktpUploaded = false;
  bool _simUploaded = false;

  @override
  void dispose() {
    _ktpCtrl.dispose();
    _simCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_formKey1.currentState?.validate() ?? false)) return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  void _submitApplication() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _currentStep = 3; // Success screen
    });
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary),
            prefixIcon: Icon(icon, size: 18, color: _C.textTertiary),
            filled: true,
            fillColor: _C.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: _C.white,
      child: Row(
        children: List.generate(3, (index) {
          final isDone = _currentStep > index;
          final isActive = _currentStep == index;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? _C.teal
                        : isActive
                            ? _C.primary
                            : _C.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDone ? _C.teal : _C.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleLabel = _currentStep == 3 ? 'Pendaftaran Sukses' : 'Gabung Mitra Driver';

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          titleLabel,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.white,
        foregroundColor: _C.textPrimary,
        elevation: 0,
        leading: _currentStep == 3
            ? const SizedBox()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _C.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep < 3) _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return ListView(
          key: const ValueKey(0),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Langkah 1: Informasi Dokumen Diri',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Silakan lengkapi nomor KTP dan SIM aktif Anda.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey1,
              child: Column(
                children: [
                  _buildFormField(
                    label: 'Nomor NIK KTP',
                    controller: _ktpCtrl,
                    icon: Iconsax.personalcard,
                    hint: 'Masukkan 16 digit nomor KTP',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'KTP wajib diisi';
                      }
                      if (v.trim().length < 16) {
                        return 'Nomor KTP harus 16 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Nomor SIM A / B1',
                    controller: _simCtrl,
                    icon: Iconsax.driver,
                    hint: 'Masukkan nomor SIM Anda',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nomor SIM wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lanjutkan',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        return ListView(
          key: const ValueKey(1),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Langkah 2: Preferensi Kerja',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih kota asal operasional dan jenis kendaraan yang Anda inginkan.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kota Asal Operasional',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _preferredCity,
                    dropdownColor: _C.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _C.bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _C.border),
                      ),
                    ),
                    items: ['Padang', 'Bukittinggi', 'Payakumbuh', 'Solok']
                        .map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city, style: GoogleFonts.inter(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _preferredCity = v),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Jenis Kendaraan Utama',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _preferredVehicle,
                    dropdownColor: _C.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _C.bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _C.border),
                      ),
                    ),
                    items: ['Toyota Hiace', 'Innova Reborn', 'Isuzu Elf']
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, style: GoogleFonts.inter(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _preferredVehicle = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.textSecondary,
                        side: const BorderSide(color: _C.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Kembali', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Lanjutkan', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return ListView(
          key: const ValueKey(2),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Langkah 3: Unggah Berkas Dokumen',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unggah foto KTP dan SIM Anda untuk verifikasi administrasi.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // KTP Upload Card
            _buildUploadCard(
              title: 'Foto Dokumen KTP',
              subtitle: 'Pastikan seluruh tulisan KTP terlihat jelas dan terbaca',
              uploaded: _ktpUploaded,
              onTap: () => setState(() => _ktpUploaded = !_ktpUploaded),
            ),
            const SizedBox(height: 16),

            // SIM Upload Card
            _buildUploadCard(
              title: 'Foto Dokumen SIM A / B1',
              subtitle: 'Pastikan masa berlaku SIM masih aktif',
              uploaded: _simUploaded,
              onTap: () => setState(() => _simUploaded = !_simUploaded),
            ),

            const SizedBox(height: 40),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: _C.primary))
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.textSecondary,
                          side: const BorderSide(color: _C.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Kembali', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_ktpUploaded && _simUploaded)
                            ? _submitApplication: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _C.border,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Kirim Lamaran', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      case 3:
        return Center(
          key: const ValueKey(3),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: _C.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.shield_tick,
                    size: 64,
                    color: _C.success,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Pendaftaran Terkirim!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terima kasih telah mendaftar. Tim kami akan memverifikasi dokumen Anda dalam waktu maksimal 2x24 jam kerja.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _C.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Kembali ke Profil',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: uploaded ? _C.teal : _C.border,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: uploaded
                    ? _C.successBg
                    : _C.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                uploaded ? Iconsax.tick_circle : Iconsax.document_upload,
                size: 20,
                color: uploaded ? _C.success : _C.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    uploaded ? 'Dokumen siap diunggah' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: uploaded ? _C.success : _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!uploaded)
              const Icon(Icons.arrow_forward_ios, size: 14, color: _C.textTertiary),
          ],
        ),
      ),
    );
  }
}
