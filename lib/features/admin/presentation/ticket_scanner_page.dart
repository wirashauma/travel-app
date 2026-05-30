import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (consistent with app)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color scanLine = Color(0xFF14B8A6);
}

// ═══════════════════════════════════════════════════════════
//  TICKET SCANNER PAGE — Full-screen QR Code Scanner
//
//  Uses `mobile_scanner` package.
//  Flow: Scan → Pause → Validate Firestore → AlertDialog → Resume
//
//  3-Phase Time-Based Validation:
//  1. Tidak ditemukan   → AlertDialog merah "Tiket Tidak Valid"
//  2. status 'pending'  → AlertDialog kuning "Tiket Belum Dibayar"
//  3. status 'cancelled'→ AlertDialog merah "Dibatalkan"
//  4. status 'expired'  → AlertDialog merah "Kadaluarsa"
//  5. status 'used'     → AlertDialog abu "Double Entry"
//  6. FASE 1: today > departureDate → update 'expired', merah
//  7. FASE 2: today < departureDate → update 'validated', biru
//  8. FASE 3: today == departureDate → update 'used', hijau "Valid!"
// ═══════════════════════════════════════════════════════════
class TicketScannerPage extends StatefulWidget {
  const TicketScannerPage({super.key});

  @override
  State<TicketScannerPage> createState() => _TicketScannerPageState();
}

class _TicketScannerPageState extends State<TicketScannerPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerCtrl;
  late final AnimationController _scanLineCtrl;

  bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  BARCODE DETECTION → Firestore Validation
  // ─────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrData = barcode.rawValue!.trim();
    if (qrData.isEmpty) return;

    setState(() => _isProcessing = true);

    // Pause scanner while processing
    _scannerCtrl.stop();

    _validateTicket(qrData);
  }

  // ─────────────────────────────────────────────────────
  //  VALIDATE TICKET — Full Firestore check + update
  // ─────────────────────────────────────────────────────
  Future<void> _validateTicket(String bookingId) async {
    try {
      // ── Try direct document lookup by bookingId first ──
      DocumentSnapshot? bookingDoc;
      Map<String, dynamic>? data;

      // Attempt 1: Direct document ID lookup
      final directDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (directDoc.exists) {
        bookingDoc = directDoc;
        data = directDoc.data() as Map<String, dynamic>?;
      } else {
        // Attempt 2: Query by bookingCode field
        final querySnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('bookingCode', isEqualTo: bookingId)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          bookingDoc = querySnap.docs.first;
          data = querySnap.docs.first.data();
        }
      }

      if (!mounted) return;

      // ── VALIDASI 1: Tidak ditemukan ──
      if (bookingDoc == null || data == null) {
        _showResultDialog(
          type: _ResultType.notFound,
          title: 'Tiket Tidak Valid',
          subtitle: 'QR Code tidak ditemukan dalam sistem.\nKemungkinan tiket palsu.',
          icon: Iconsax.close_circle,
          color: _C.error,
          bgColor: _C.errorBg,
        );
        return;
      }

      final status = data['status'] as String? ?? '';
      final passengerName = data['userName'] as String? ?? 'Penumpang';
      final bookingCode = data['bookingCode'] as String? ?? '-';
      final origin = data['origin'] as String? ?? '-';
      final destination = data['destination'] as String? ?? '-';
      final seatNumbers = (data['seatNumbers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [];
      final seatLabel = seatNumbers.isNotEmpty
          ? seatNumbers.map((s) => 'No. $s').join(', ')
          : '-';

      // ── Parse departure date (date-only comparison) ──
      DateTime? departureDate;
      final rawDate = data['departureDate'];
      if (rawDate is Timestamp) {
        final ts = rawDate.toDate();
        departureDate = DateTime(ts.year, ts.month, ts.day);
      } else if (rawDate is String && rawDate.isNotEmpty) {
        // Try multiple formats for robustness
        for (final locale in ['id_ID', null]) {
          try {
            final parsed = DateFormat('dd MMM yyyy', locale).parse(rawDate);
            departureDate = DateTime(parsed.year, parsed.month, parsed.day);
            break;
          } catch (_) {}
        }
        if (departureDate == null) {
          try {
            final parsed = DateTime.parse(rawDate);
            departureDate = DateTime(parsed.year, parsed.month, parsed.day);
          } catch (_) {}
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ── VALIDASI 2: Belum dibayar ──
      if (status == 'pending') {
        _showResultDialog(
          type: _ResultType.unpaid,
          title: 'Tiket Belum Dibayar',
          subtitle:
              'Penumpang belum menyelesaikan pembayaran.\nTidak dapat boarding.',
          icon: Iconsax.wallet_minus,
          color: _C.warning,
          bgColor: _C.warningBg,
          passengerName: passengerName,
          bookingCode: bookingCode,
        );
        return;
      }

      // ── VALIDASI 3: Dibatalkan ──
      if (status == 'cancelled') {
        _showResultDialog(
          type: _ResultType.cancelled,
          title: 'Tiket Dibatalkan',
          subtitle: 'Booking ini sudah dibatalkan oleh penumpang.',
          icon: Iconsax.close_square,
          color: _C.error,
          bgColor: _C.errorBg,
          passengerName: passengerName,
          bookingCode: bookingCode,
        );
        return;
      }

      // ── VALIDASI 4: Sudah expired (status set sebelumnya) ──
      if (status == 'expired') {
        _showResultDialog(
          type: _ResultType.expired,
          title: 'Tiket Kadaluarsa',
          subtitle: 'Tiket ini sudah melewati tanggal keberangkatan.',
          icon: Iconsax.calendar_remove,
          color: _C.error,
          bgColor: _C.errorBg,
          passengerName: passengerName,
          bookingCode: bookingCode,
          route: '$origin → $destination',
          seat: seatLabel,
        );
        return;
      }

      // ── VALIDASI 5: Double Entry — sudah digunakan ──
      if (status == 'used' || status == 'completed') {
        _showResultDialog(
          type: _ResultType.alreadyUsed,
          title: 'Tiket Sudah Digunakan',
          subtitle: 'Tiket ini sudah divalidasi sebelumnya.\nTidak dapat digunakan lagi (double entry).',
          icon: Iconsax.refresh_left_square,
          color: _C.textTertiary,
          bgColor: _C.border.withValues(alpha: 0.3),
          passengerName: passengerName,
          bookingCode: bookingCode,
          route: '$origin → $destination',
          seat: seatLabel,
        );
        return;
      }

      // ── Date-based validation (status 'paid' atau 'validated') ──
      if (status == 'paid' || status == 'validated') {
        // FASE 1: Sudah lewat tanggal → expired
        if (departureDate != null && today.isAfter(departureDate)) {
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingDoc.id)
              .update({
            'status': 'expired',
            'scannedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          _showResultDialog(
            type: _ResultType.expired,
            title: 'Tiket Telah Kadaluarsa!',
            subtitle: 'Tanggal keberangkatan sudah lewat.\nTiket tidak berlaku lagi.',
            icon: Iconsax.calendar_remove,
            color: _C.error,
            bgColor: _C.errorBg,
            passengerName: passengerName,
            bookingCode: bookingCode,
            route: '$origin → $destination',
            seat: seatLabel,
          );
          return;
        }

        // FASE 2: Belum hari-H → validasi awal
        if (departureDate != null && today.isBefore(departureDate)) {
          if (status == 'paid') {
            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingDoc.id)
                .update({
              'status': 'validated',
              'scannedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          if (!mounted) return;

          _showResultDialog(
            type: _ResultType.validated,
            title: 'Berhasil Divalidasi',
            subtitle: 'Tiket valid. Belum tanggal keberangkatan.\nSilakan datang pada hari-H.',
            icon: Iconsax.shield_tick,
            color: const Color(0xFF1D4ED8),
            bgColor: const Color(0xFFEFF6FF),
            passengerName: passengerName,
            bookingCode: bookingCode,
            route: '$origin → $destination',
            seat: seatLabel,
          );
          return;
        }

        // FASE 3: Hari-H → boarding (hari sama, atau tanggal null fallback)
        // Update HANYA field status → 'used'
        // StreamBuilder di Driver Dashboard akan otomatis menangkap perubahan ini
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingDoc.id)
            .update({'status': 'used'});

        if (!mounted) return;

        _showResultDialog(
          type: _ResultType.success,
          title: 'Tiket Valid!',
          subtitle: 'Penumpang diizinkan naik.\nSelamat jalan!',
          icon: Iconsax.tick_circle,
          color: _C.success,
          bgColor: _C.successBg,
          passengerName: passengerName,
          bookingCode: bookingCode,
          route: '$origin → $destination',
          seat: seatLabel,
          autoCloseOnSuccess: true,
        );
        return;
      }

      // ── Fallback: unknown status ──
      _showResultDialog(
        type: _ResultType.error,
        title: 'Status Tidak Dikenal',
        subtitle: 'Status tiket "$status" tidak dikenali oleh sistem.',
        icon: Iconsax.warning_2,
        color: _C.error,
        bgColor: _C.errorBg,
        passengerName: passengerName,
        bookingCode: bookingCode,
      );
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        type: _ResultType.error,
        title: 'Terjadi Kesalahan',
        subtitle: 'Gagal memvalidasi tiket.\n${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}',
        icon: Iconsax.warning_2,
        color: _C.error,
        bgColor: _C.errorBg,
      );
    }
  }

  // ─────────────────────────────────────────────────────
  //  RESULT ALERT DIALOG
  // ─────────────────────────────────────────────────────
  void _showResultDialog({
    required _ResultType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    String? passengerName,
    String? bookingCode,
    String? route,
    String? seat,
    bool autoCloseOnSuccess = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Auto-close setelah 2 detik → kembali ke dashboard
        if (autoCloseOnSuccess) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!ctx.mounted) return;
            Navigator.of(ctx, rootNavigator: true).pop(); // close dialog
            // ignore: use_build_context_synchronously
            if (!context.mounted) return;
            Navigator.of(context).pop(); // pop scanner page
          });
        }
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 400.ms,
                    curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            // ── Title ──
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Subtitle ──
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Passenger details (if available) ──
            if (passengerName != null || bookingCode != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    if (passengerName != null)
                      _DialogInfoRow(
                        icon: Iconsax.user,
                        label: 'Penumpang',
                        value: passengerName,
                      ),
                    if (bookingCode != null) ...[
                      if (passengerName != null)
                        Divider(
                            color: _C.border.withValues(alpha: 0.5),
                            height: 16),
                      _DialogInfoRow(
                        icon: Iconsax.receipt,
                        label: 'Kode Tiket',
                        value: bookingCode,
                        isMono: true,
                      ),
                    ],
                    if (route != null) ...[
                      Divider(
                          color: _C.border.withValues(alpha: 0.5),
                          height: 16),
                      _DialogInfoRow(
                        icon: Iconsax.route_square,
                        label: 'Rute',
                        value: route,
                      ),
                    ],
                    if (seat != null) ...[
                      Divider(
                          color: _C.border.withValues(alpha: 0.5),
                          height: 16),
                      _DialogInfoRow(
                        icon: Iconsax.driver,
                        label: 'Kursi',
                        value: seat,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Button: Scan Lagi ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
                  _resumeScanner();
                },
                icon: const Icon(Iconsax.scan_barcode, size: 18),
                label: Text(
                  'Scan Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: _C.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Button: Kembali ──
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop(); // close dialog
                  if (context.mounted) Navigator.of(context).pop(); // pop scanner page
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _C.border),
                  ),
                ),
                child: Text(
                  'Kembali ke Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textSecondary,
                  ),
                ),
              ),
            ),

            // Auto-close countdown hint
            if (autoCloseOnSuccess) ...[
              const SizedBox(height: 8),
              Text(
                'Otomatis kembali dalam 2 detik…',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _C.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
      },
    );
  }

  // ── Resume scanner ──
  void _resumeScanner() {
    setState(() => _isProcessing = false);
    _scannerCtrl.start();
  }

  // ── Toggle torch ──
  void _toggleTorch() {
    _scannerCtrl.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  // ─────────────────────────────────────────────────────
  //  BUILD — Full-screen camera with overlay
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final w = mq.size.width;
    final scanAreaSize = w * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerCtrl,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.camera_slash,
                          size: 56, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak dapat mengakses kamera',
                        style: GoogleFonts.inter(
                            fontSize: 15, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan izin kamera telah diberikan',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white38),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: _C.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Dark overlay with transparent cutout ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                scanAreaSize: scanAreaSize,
                borderRadius: 24,
              ),
            ),
          ),

          // ── Scan frame corners ──
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: CustomPaint(
                painter: _CornerPainter(
                  color: _C.scanLine,
                  borderRadius: 24,
                  cornerLength: 32,
                  strokeWidth: 4,
                ),
              ),
            ),
          ),

          // ── Animated scan line ──
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: AnimatedBuilder(
                animation: _scanLineCtrl,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(
                      0,
                      -1.0 + 2.0 * _scanLineCtrl.value,
                    ),
                    child: Container(
                      width: scanAreaSize - 40,
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.scanLine.withValues(alpha: 0.0),
                            _C.scanLine.withValues(alpha: 0.8),
                            _C.scanLine,
                            _C.scanLine.withValues(alpha: 0.8),
                            _C.scanLine.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: _C.scanLine.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Top bar: Back + Title + Torch ──
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(
                  icon: Iconsax.arrow_left,
                  onTap: () => Navigator.pop(context),
                ),
                Text(
                  'Scan Tiket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                _CircleButton(
                  icon:
                      _torchEnabled ? Iconsax.flash_15 : Iconsax.flash_slash,
                  onTap: _toggleTorch,
                  isActive: _torchEnabled,
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(
                  begin: -0.1,
                  duration: 400.ms,
                ),
          ),

          // ── Bottom instruction ──
          Positioned(
            bottom: bottomPad + 40,
            left: 32,
            right: 32,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.scan_barcode,
                          size: 20, color: _C.scanLine),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Arahkan kamera ke QR Code tiket penumpang',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Memvalidasi tiket…',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, delay: 300.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  RESULT TYPE ENUM
// ─────────────────────────────────────────────────────────
enum _ResultType { success, notFound, unpaid, alreadyUsed, cancelled, expired, validated, error }

// ─────────────────────────────────────────────────────────
//  DIALOG INFO ROW
// ─────────────────────────────────────────────────────────
class _DialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMono;

  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _C.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: _C.textTertiary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: isMono
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  CIRCLE BUTTON (Back / Torch)
// ─────────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? _C.teal.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? _C.teal.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SCAN OVERLAY PAINTER — Dark overlay with transparent cutout
// ─────────────────────────────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final double borderRadius;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));

    final combinedPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );

    canvas.drawPath(
      combinedPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      scanAreaSize != oldDelegate.scanAreaSize;
}

// ─────────────────────────────────────────────────────────
//  CORNER PAINTER — Scan frame corners
// ─────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double cornerLength;
  final double strokeWidth;

  _CornerPainter({
    required this.color,
    required this.borderRadius,
    required this.cornerLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final l = cornerLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(l, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, l),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - l)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(l, h),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w, h - l)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - l, h),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      color != oldDelegate.color ||
      cornerLength != oldDelegate.cornerLength ||
      strokeWidth != oldDelegate.strokeWidth;
}
