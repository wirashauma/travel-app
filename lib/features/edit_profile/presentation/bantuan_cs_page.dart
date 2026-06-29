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
  static const Color success = Color(0xFF059669);
}

class BantuanCsPage extends StatefulWidget {
  const BantuanCsPage({super.key});

  @override
  State<BantuanCsPage> createState() => _BantuanCsPageState();
}

class _BantuanCsPageState extends State<BantuanCsPage> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Bagaimana cara memesan tiket travel?',
      'answer': 'Masuk ke tab "Pesan Tiket" di beranda utama, pilih kota asal, kota tujuan, tanggal keberangkatan, lalu pilih armada travel yang tersedia dan kursi yang Anda inginkan.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana cara melakukan reschedule tiket?',
      'answer': 'Buka tab "Tiket Saya", pilih tiket aktif yang ingin diubah. Tekan tombol "Reschedule" lalu tentukan rute atau tanggal baru. Harap perhatikan biaya administrasi reschedule yang berlaku.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana cara melacak kiriman paket?',
      'answer': 'Buka menu Paket, pilih riwayat kiriman Anda dan ketuk pada nomor resi paket untuk melihat timeline pengiriman paket Anda secara real-time.',
      'expanded': false,
    },
    {
      'question': 'Bagaimana sistem pembayaran tiket/paket?',
      'answer': 'Kami mendukung berbagai metode pembayaran seperti Transfer Bank (VA) dan E-Wallet (QRIS). Pembayaran harus dilunasi sebelum masa kedaluwarsa tiket berakhir.',
      'expanded': false,
    },
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label berhasil disalin ke papan klip!',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildContactTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _C.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary.withValues(alpha: 0.08),
              foregroundColor: _C.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Salin',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          'Bantuan & CS',
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
            // Contact Title
            Text(
              'Hubungi Kami',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            _buildContactTile(
              title: 'WhatsApp Official Support',
              value: '+62 812-3456-7890',
              icon: Iconsax.message,
              color: Colors.green,
              onTap: () => _copyToClipboard('+6281234567890', 'Nomor WhatsApp'),
              delay: 100,
            ),
            const SizedBox(height: 12),

            _buildContactTile(
              title: 'Email Customer Service',
              value: 'support@minangtravel.com',
              icon: Iconsax.sms,
              color: Colors.orange,
              onTap: () => _copyToClipboard('support@minangtravel.com', 'Alamat Email'),
              delay: 180,
            ),
            const SizedBox(height: 12),

            _buildContactTile(
              title: 'Call Center 24 Jam',
              value: '021-987654',
              icon: Iconsax.call,
              color: _C.primary,
              onTap: () => _copyToClipboard('021987654', 'Nomor Call Center'),
              delay: 260,
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Pertanyaan Umum (FAQ)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 12),

            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              final isExpanded = faq['expanded'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.borderLight),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _faqs[index]['expanded'] = !isExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['question'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Iconsax.arrow_up_1
                                  : Iconsax.arrow_down_1,
                              size: 16,
                              color: _C.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: _C.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms),
                  ],
                ),
              ).animate().fadeIn(
                    delay: (300 + index * 80).ms,
                    duration: 400.ms,
                  );
            }),
          ],
        ),
      ),
    );
  }
}
