import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/ticket_scan_service.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue (consistent with app)
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color scanLine = Color(0xFF14B8A6);
}

// ═══════════════════════════════════════════════════════════
//  QR SCANNER PAGE — Full-screen camera with animated overlay
// ═══════════════════════════════════════════════════════════
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late AnimationController _scanLineController;
  bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ── Real Firestore scan handler ──
  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    final qrData = barcode.rawValue!.trim();

    // Use TicketScanService to validate & update Firestore
    TicketScanService.scanTicketAndUpdateStatus(
      bookingCode: qrData,
    ).then((result) {
      if (!mounted) return;

      if (result.success) {
        _showValidationResult(
          isValid: true,
          name: result.passengerName ?? 'Penumpang',
          seatNumber: result.seatNumbers?.first ?? 0,
          ticketCode: result.bookingCode ?? qrData,
        );
      } else {
        _showValidationResult(
          isValid: false,
          name: result.passengerName ?? result.message,
          seatNumber: 0,
          ticketCode: qrData,
          errorMessage: result.message,
        );
      }
    }).catchError((e) {
      if (!mounted) return;
      _showValidationResult(
        isValid: false,
        name: 'Error',
        seatNumber: 0,
        ticketCode: qrData,
        errorMessage: 'Gagal memvalidasi: $e',
      );
    });
  }

  void _showValidationResult({
    required bool isValid,
    required String name,
    required int seatNumber,
    required String ticketCode,
    String? errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ValidationSheet(
        isValid: isValid,
        name: name,
        seatNumber: seatNumber,
        ticketCode: ticketCode,
        errorMessage: errorMessage,
        onDone: () {
          Navigator.pop(ctx); // close sheet
          Navigator.pop(context, {
            'ticketCode': ticketCode,
            'name': name,
            'seatNumber': seatNumber,
          }); // pop scanner & return data
        },
        onScanAgain: () {
          Navigator.pop(ctx); // close sheet
          setState(() => _isProcessing = false);
        },
      ),
    );
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

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
              controller: _scannerController,
              onDetect: _handleBarcode,
            ),
          ),

          // ── Overlay with transparent cutout ──
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
                  cornerLength: 30,
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
                animation: _scanLineController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(
                      0,
                      -1.0 + 2.0 * _scanLineController.value,
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

          // ── Top bar ──
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _buildCircleButton(
                  icon: Iconsax.arrow_left,
                  onTap: () => Navigator.pop(context),
                ),
                // Title
                Text(
                  'Scan Tiket QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                // Torch toggle
                _buildCircleButton(
                  icon: _torchEnabled ? Iconsax.flash_15 : Iconsax.flash_slash,
                  onTap: _toggleTorch,
                  isActive: _torchEnabled,
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1, duration: 400.ms),
          ),

          // ── Bottom instruction ──
          Positioned(
            bottom: bottomPad + 40,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Instruction
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.scan_barcode,
                        size: 20,
                        color: _C.scanLine,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Arahkan kamera ke QR code pada tiket penumpang',
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
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

    // Full dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut out the scan area
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));

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

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(l, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, l),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, h - l)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(l, h),
      paint,
    );

    // Bottom-right corner
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

// ─────────────────────────────────────────────────────────
//  VALIDATION RESULT SHEET
// ─────────────────────────────────────────────────────────
class _ValidationSheet extends StatelessWidget {
  final bool isValid;
  final String name;
  final int seatNumber;
  final String ticketCode;
  final String? errorMessage;
  final VoidCallback onDone;
  final VoidCallback onScanAgain;

  const _ValidationSheet({
    required this.isValid,
    required this.name,
    required this.seatNumber,
    required this.ticketCode,
    this.errorMessage,
    required this.onDone,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Success/Error icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isValid ? _C.successBg : _C.errorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Iconsax.tick_circle : Iconsax.close_circle,
              size: 36,
              color: isValid ? _C.success : _C.error,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 18),

          // Title
          Text(
            isValid ? 'Tiket Valid!' : 'Tiket Tidak Valid',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isValid ? _C.success : _C.error,
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 300.ms),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            isValid
                ? 'Penumpang berhasil divalidasi'
                : (errorMessage ?? 'QR code tidak ditemukan dalam sistem'),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _C.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 300.ms),

          if (isValid) ...[
            const SizedBox(height: 20),

            // Passenger info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Iconsax.user, 'Penumpang', name),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildInfoRow(Iconsax.receipt, 'Kode Tiket', ticketCode),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildInfoRow(
                    Iconsax.driver,
                    'Nomor Kursi',
                    'Kursi $seatNumber',
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 250.ms, duration: 350.ms)
                .slideY(begin: 0.06, delay: 250.ms, duration: 350.ms),
          ],

          const SizedBox(height: 24),

          // Buttons row
          Row(
            children: [
              // Scan Again
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onScanAgain,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.primary, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.scan_barcode, size: 18, color: _C.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Scan Lagi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _C.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Done
              Expanded(
                child: Material(
                  color: _C.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onDone,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.tick_circle, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Selesai',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 300.ms),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _C.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _C.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
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
