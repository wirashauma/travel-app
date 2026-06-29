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
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFEF4444);
}

class SesiLoginPage extends StatefulWidget {
  const SesiLoginPage({super.key});

  @override
  State<SesiLoginPage> createState() => _SesiLoginPageState();
}

class _SesiLoginPageState extends State<SesiLoginPage> {
  bool _isRevoking = false;
  List<Map<String, dynamic>> _devices = [
    {
      'id': '1',
      'device': 'Xiaomi Redmi Note 12 Pro',
      'os': 'Android 13 • Aplikasi Minang Travel v1.0.0',
      'location': 'Padang, Sumatera Barat',
      'ip': '182.2.148.90',
      'isCurrent': true,
      'time': 'Aktif sekarang',
    },
    {
      'id': '2',
      'device': 'Google Chrome di Windows',
      'os': 'Windows 11 • Web Browser',
      'location': 'Bukittinggi, Sumatera Barat',
      'ip': '114.124.200.12',
      'isCurrent': false,
      'time': 'Aktif 3 jam yang lalu',
    },
    {
      'id': '3',
      'device': 'Apple iPhone 14 Pro Max',
      'os': 'iOS 16.5 • Web Browser',
      'location': 'Pariaman, Sumatera Barat',
      'ip': '103.111.23.45',
      'isCurrent': false,
      'time': 'Aktif 2 hari yang lalu',
    },
  ];

  void _revokeSession(String id) {
    setState(() {
      _devices.removeWhere((device) => device['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sesi berhasil dihentikan.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _revokeAllSessions() async {
    setState(() => _isRevoking = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _devices.removeWhere((device) => !device['isCurrent']);
      _isRevoking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua sesi perangkat lain berhasil dihentikan.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Sesi Login',
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
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.shield_security, size: 22, color: _C.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keamanan Akun',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Berikut adalah daftar perangkat yang saat ini masuk ke akun Anda. Anda dapat menghentikan sesi apa pun jika mencurigai adanya aktivitas mencurigakan.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: _C.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),

            // Devices Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perangkat Aktif (${_devices.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                if (_devices.any((d) => !d['isCurrent']))
                  _isRevoking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _C.primary,
                          ),
                        )
                      : TextButton(
                          onPressed: _revokeAllSessions,
                          style: TextButton.styleFrom(
                            foregroundColor: _C.danger,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Keluarkan Semua',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),

            // Devices List
            ...List.generate(_devices.length, (index) {
              final d = _devices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon based on type
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: d['isCurrent']
                            ? _C.successBg
                            : _C.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        d['device'].contains('iPhone') ||
                                d['device'].contains('Redmi')
                            ? Iconsax.mobile
                            : Iconsax.monitor,
                        size: 20,
                        color: d['isCurrent'] ? _C.success : _C.primary,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d['device'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (d['isCurrent'])
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.successBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Ini',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _C.success,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['os'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _C.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                size: 12,
                                color: _C.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d['location'],
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: _C.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.info_circle,
                                size: 12,
                                color: _C.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${d['ip']} • ${d['time']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: _C.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions for non-current
                    if (!d['isCurrent']) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Iconsax.logout_1,
                          color: _C.danger,
                          size: 18,
                        ),
                        onPressed: () => _revokeSession(d['id']),
                        tooltip: 'Putuskan Sesi',
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(
                    delay: (200 + index * 80).ms,
                    duration: 400.ms,
                  );
            }),
          ],
        ),
      ),
    );
  }
}
