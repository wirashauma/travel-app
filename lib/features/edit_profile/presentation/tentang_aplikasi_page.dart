import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
}

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Brand Logo
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
              const SizedBox(height: 24),

              // App Name & Tagline
              Text(
                'Minang Travel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _C.textPrimary,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 4),
              Text(
                'Perjalanan Nyaman, Harga Teman',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _C.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),

              // Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Minang Travel adalah aplikasi booking tiket travel dan pengiriman paket antar kota di Sumatera Barat berbasis Android dan iOS. Kami menghubungkan Anda dengan armada travel terbaik untuk memastikan perjalanan Anda aman, nyaman, dan tepat waktu.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _C.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: 40),

              // App details
              Column(
                children: [
                  _buildDetailRow('Versi Aplikasi', '1.0.0', 360),
                  const Divider(color: _C.borderLight),
                  _buildDetailRow('Nomor Build', '2026.06.29', 420),
                  const Divider(color: _C.borderLight),
                  _buildDetailRow('Developer', 'Minang Tech Team', 480),
                  const Divider(color: _C.borderLight),
                  _buildDetailRow('Lisensi', 'Commercial Proprietary', 540),
                ],
              ),
              const SizedBox(height: 40),

              // Copyright
              Text(
                '© 2026 Minang Travel. Hak cipta dilindungi.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _C.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms);
  }
}
