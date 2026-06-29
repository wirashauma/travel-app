import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shipment_model.dart';
import '../../../core/services/midtrans_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../payment/presentation/midtrans_webview_page.dart';

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
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class ShipmentPaymentPage extends StatefulWidget {
  final ShipmentModel shipment;

  const ShipmentPaymentPage({super.key, required this.shipment});

  @override
  State<ShipmentPaymentPage> createState() => _ShipmentPaymentPageState();
}

class _ShipmentPaymentPageState extends State<ShipmentPaymentPage> {
  bool _isProcessing = false;
  bool _paymentDone = false;

  static const _expiryMinutes = 15;
  late int _remainingSeconds;
  Timer? _timer;

  ShipmentModel get s => widget.shipment;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _expiryMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    try {
      final tokenResult = await MidtransService.generateSnapToken(
        orderId: 'SHIP-${s.id}',
        grossAmount: s.packagePrice ?? 0,
        customerName: s.senderName,
        customerPhone: s.senderPhone,
        itemName: 'Paket ${s.packageSize ?? ''} - ${s.origin} → ${s.destination}',
        itemQuantity: 1,
      );

      if (!mounted) return;

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransWebviewPage(
            bookingId: s.id ?? '',
            bookingCode: 'SHIP-${s.id?.substring(0, 6).toUpperCase() ?? ''}',
            snapUrl: tokenResult.redirectUrl,
            onPaymentSuccess: () async {
              await ShipmentService.updatePaymentStatus(
                s.id!,
                paymentMethod: 'midtrans',
                paymentStatus: 'paid',
              );
            },
          ),
        ),
      );

      if (success == true && mounted) {
        setState(() => _paymentDone = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memproses pembayaran: $e',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: _paymentDone,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildAppBar(topPadding),
            Expanded(
              child: _paymentDone
                  ? _buildSuccessView()
                  : _buildPaymentContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 16),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Text(
            'Pembayaran Paket',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Countdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _C.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.clock, size: 22, color: _C.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selesaikan pembayaran dalam',
                    style: GoogleFonts.inter(fontSize: 12, color: _C.textSecondary),
                  ),
                ),
                Text(
                  _formattedTime,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _remainingSeconds < 120 ? _C.danger : _C.warning,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Receipt Card Container
          Material(
            elevation: 8,
            shadowColor: _C.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: ClipPath(
              clipper: ReceiptClipper(),
              child: Container(
                width: double.infinity,
                color: _C.white,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                child: Column(
                  children: [
                    // Brand / Logo Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.box_tick, size: 24, color: _C.primary),
                        const SizedBox(width: 8),
                        Text(
                          'MINANG TRAVEL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Struk Tagihan Pengiriman',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _C.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const DashedDivider(color: _C.borderLight),
                    const SizedBox(height: 18),
                    
                    // Transaction details
                    _receiptRow('No. Tagihan', 'SHIP-${s.id?.substring(0, 6).toUpperCase() ?? ''}'),
                    const SizedBox(height: 10),
                    _receiptRow('Layanan', 'Kirim Paket'),
                    const SizedBox(height: 10),
                    _receiptRow('Rute', '${s.origin} → ${s.destination}'),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Ukuran Paket',
                      s.packageSize == 'kecil'
                          ? 'Kecil'
                          : s.packageSize == 'sedang'
                              ? 'Sedang'
                              : 'Besar',
                    ),
                    const SizedBox(height: 18),
                    const DashedDivider(color: _C.borderLight),
                    const SizedBox(height: 18),

                    // Price details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL BAYAR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _C.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Rp${NumberFormat('#,###', 'id_ID').format(s.packagePrice ?? 0)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const DashedDivider(color: _C.borderLight),
                    const SizedBox(height: 20),

                    // Barcode section
                    _buildBarcode(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pay,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Iconsax.wallet, size: 20),
              label: Text(
                _isProcessing ? 'Memproses...' : 'Bayar dengan Midtrans',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _C.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.tick_circle, size: 48, color: _C.success),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          Text(
            'Pembayaran Berhasil!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.success,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Paket akan segera diproses...',
            style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _C.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcode() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(35, (index) {
            final isGap = index % 4 == 0;
            final width = (index % 5 == 0) ? 3.0 : ((index % 2 == 0) ? 1.0 : 2.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: isGap ? 0 : width,
              height: 28,
              color: _C.textPrimary.withValues(alpha: 0.85),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'SHIP-${s.id?.toUpperCase() ?? ''}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: _C.textTertiary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  RECEIPT STYLING UTILS — Clipper & Dashed Divider
// ─────────────────────────────────────────────────────────
class ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    
    // Bottom serrated edge
    double toothWidth = 8;
    double toothHeight = 4;
    int toothCount = (size.width / toothWidth).ceil();
    for (int i = 0; i < toothCount; i++) {
      double x = i * toothWidth;
      path.lineTo(x + toothWidth / 2, size.height - toothHeight);
      path.lineTo(x + toothWidth, size.height);
    }
    
    path.lineTo(size.width, 0);
    
    // Top serrated edge
    for (int i = toothCount - 1; i >= 0; i--) {
      double x = i * toothWidth;
      path.lineTo(x + toothWidth / 2, toothHeight);
      path.lineTo(x, 0);
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashGap;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 5,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
