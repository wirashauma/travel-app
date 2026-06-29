import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color primary = Color(0xFF0F4C81);
}

class SyaratKetentuanPage extends StatelessWidget {
  const SyaratKetentuanPage({super.key});

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
          'Syarat & Ketentuan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.white,
        foregroundColor: _C.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _C.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Syarat & Ketentuan Penggunaan',
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
              title: '1. Penerimaan Ketentuan',
              content: 'Dengan mengakses dan menggunakan aplikasi Minang Travel, Anda menyetujui untuk terikat oleh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui sebagian atau seluruh syarat ini, Anda tidak diperkenankan menggunakan layanan kami.',
              delay: 100,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '2. Pendaftaran Akun',
              content: 'Anda diwajibkan mendaftarkan akun dengan data yang benar, lengkap, dan terbaru. Anda bertanggung jawab penuh atas kerahasiaan informasi akun dan kata sandi Anda serta semua aktivitas yang dilakukan di bawah akun Anda.',
              delay: 180,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '3. Pemesanan Tiket & reschedule',
              content: 'Setiap pemesanan tiket travel bersifat mengikat. Layanan reschedule dapat diajukan selambat-lambatnya 6 jam sebelum keberangkatan rute dan mungkin dikenakan biaya administrasi tambahan sesuai ketentuan masing-masing armada.',
              delay: 260,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '4. Kebijakan Pengiriman Paket',
              content: 'Pengguna dilarang mengirimkan barang berbahaya, ilegal, mudah terbakar, hewan hidup, atau benda berharga tinggi tanpa asuransi. Minang Travel tidak bertanggung jawab atas isi paket yang tidak sesuai deklarasi.',
              delay: 340,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '5. Batasan Tanggung Jawab',
              content: 'Minang Travel berupaya memberikan layanan terbaik namun tidak bertanggung jawab atas kerugian tidak langsung yang disebabkan oleh keterlambatan akibat kemacetan, kendala cuaca ekstrem, atau kondisi kahar (force majeure) lainnya di jalan.',
              delay: 420,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
