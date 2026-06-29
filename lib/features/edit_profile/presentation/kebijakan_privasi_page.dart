import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color primary = Color(0xFF0F4C81);
}

class KebijakanPrivasiPage extends StatelessWidget {
  const KebijakanPrivasiPage({super.key});

  Widget _buildSection({
    required String title,
    required String content,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(
          delay: delay.ms,
          duration: 400.ms,
        ).slideY(
          begin: 0.04,
          delay: delay.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Kebijakan Privasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _C.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _C.white),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Kebijakan Privasi Data Pengguna',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.primary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 4),
            Text(
              'Terakhir diperbarui: Juni 2026',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _C.textSecondary.withValues(alpha: 0.7),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Pengumpulan Informasi',
              content: 'Kami mengumpulkan informasi pribadi yang Anda berikan langsung saat mendaftar, seperti nama lengkap, alamat email, nomor telepon, foto profil, dan data pemesanan atau pengiriman paket Anda.',
              delay: 100,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '2. Penggunaan Informasi',
              content: 'Informasi yang kami kumpulkan digunakan untuk memproses pesanan tiket, memfasilitasi pelacakan paket, mengirimkan pemberitahuan status perjalanan, meningkatkan layanan aplikasi, serta untuk tujuan keamanan akun Anda.',
              delay: 180,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '3. Data Lokasi Pengguna',
              content: 'Aplikasi ini menggunakan izin akses lokasi di latar belakang (background location) untuk menampilkan rute peta real-time kepada supir dan penumpang serta memperkirakan waktu ketibaan armada di titik penjemputan.',
              delay: 260,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '4. Perlindungan Data',
              content: 'Kami menggunakan langkah-langkah keamanan teknis yang ketat untuk melindungi data pribadi Anda dari akses tidak sah, pengubahan, pengungkapan, atau penghancuran tanpa izin.',
              delay: 340,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '5. Hak Pengguna',
              content: 'Anda berhak untuk mengakses, mengubah, memperbarui, atau mengajukan penghapusan akun serta seluruh data pribadi Anda yang tersimpan di dalam sistem database kami kapan saja melalui CS resmi.',
              delay: 420,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
