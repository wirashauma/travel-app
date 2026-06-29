import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
}

class NotifikasiSettingsPage extends StatefulWidget {
  const NotifikasiSettingsPage({super.key});

  @override
  State<NotifikasiSettingsPage> createState() => _NotifikasiSettingsPageState();
}

class _NotifikasiSettingsPageState extends State<NotifikasiSettingsPage> {
  bool _ticketNotif = true;
  bool _promoNotif = false;
  bool _packageNotif = true;
  bool _appUpdateNotif = true;
  bool _paymentNotif = true;

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _C.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _C.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: _C.primary,
            onChanged: onChanged,
          ),
        ],
      ),
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
          'Pengaturan Notifikasi',
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
              'Pemberitahuan Push',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'Tiket & Keberangkatan',
              subtitle: 'Pengingat perjalanan, perubahan jadwal, dan informasi tiket.',
              icon: Iconsax.ticket_2,
              value: _ticketNotif,
              onChanged: (v) => setState(() => _ticketNotif = v),
              delay: 100,
            ),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'Status Pengiriman Paket',
              subtitle: 'Notifikasi real-time untuk pelacakan kiriman paket Anda.',
              icon: Iconsax.box_2,
              value: _packageNotif,
              onChanged: (v) => setState(() => _packageNotif = v),
              delay: 180,
            ),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'Transaksi & Pembayaran',
              subtitle: 'Status pembayaran, invoice, dan informasi refund tiket.',
              icon: Iconsax.card_send,
              value: _paymentNotif,
              onChanged: (v) => setState(() => _paymentNotif = v),
              delay: 260,
            ),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'Promo & Diskon khusus',
              subtitle: 'Penawaran tiket murah, voucher potongan harga, dan info event.',
              icon: Iconsax.discount_shape,
              value: _promoNotif,
              onChanged: (v) => setState(() => _promoNotif = v),
              delay: 340,
            ),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'Pembaruan Aplikasi',
              subtitle: 'Pemberitahuan fitur baru dan info pemeliharaan sistem.',
              icon: Iconsax.document_download,
              value: _appUpdateNotif,
              onChanged: (v) => setState(() => _appUpdateNotif = v),
              delay: 420,
            ),
          ],
        ),
      ),
    );
  }
}
