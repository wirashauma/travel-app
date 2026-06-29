import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
}

class CancelBookingPage extends StatefulWidget {
  final BookingModel booking;

  const CancelBookingPage({super.key, required this.booking});

  @override
  State<CancelBookingPage> createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  bool _isProcessing = false;

  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  int get _penaltyAmount => widget.booking.status == BookingStatus.paid
      ? widget.booking.totalPrice
      : (widget.booking.totalPrice * 0.2).round();
  int get _refundAmount => widget.booking.status == BookingStatus.paid
      ? 0
      : widget.booking.totalPrice - _penaltyAmount;

  Future<void> _confirmCancel() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // ── Check if vehicle has already departed ──
      final fleetDoc = await FirebaseFirestore.instance
          .collection('fleets')
          .doc(widget.booking.fleetId)
          .get();
      if (fleetDoc.exists) {
        final tripStatus = fleetDoc.data()?['tripStatus'] as String? ?? 'menunggu';
        if (tripStatus == 'berangkat' || tripStatus == 'selesai') {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mobil sudah berangkat. Tiket tidak dapat dibatalkan.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: _C.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }
      }

      await BookingService.cancelBooking(widget.booking.id!);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pesanan ${widget.booking.bookingCode} berhasil dibatalkan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: _C.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gagal membatalkan: $e',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: _C.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(topPadding),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildIllustration(),
                      const SizedBox(height: 32),
                      _buildTextContent(),
                      const SizedBox(height: 32),
                      _buildBookingInfo(),
                      const SizedBox(height: 32),
                      _buildRefundSummary(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 4, 20, 16),
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
            'Cancel Booking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _C.dangerBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _C.danger.withValues(alpha: 0.15), width: 1.5),
      ),
      child: const Icon(
        Iconsax.close_circle,
        size: 52,
        color: _C.danger,
      ),
    )
        .animate()
        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut);
  }

  Widget _buildTextContent() {
    return Column(
      children: [
        Text(
          'Apakah Anda yakin ingin\nmembatalkan pemesanan ini?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
            height: 1.3,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 14),
        Text(
          widget.booking.status == BookingStatus.paid
              ? 'Sesuai dengan ketentuan pembatalan tiket yang telah dibayar, seluruh dana pembayaran tiket Anda akan hangus (tidak dikembalikan).'
              : 'Kursi yang sudah dipesan akan dikembalikan ke armada dan tersedia untuk penumpang lain.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textSecondary,
            height: 1.6,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Iconsax.receipt_1,
            label: 'Kode Booking',
            value: widget.booking.bookingCode,
            valueStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.primary,
              letterSpacing: 1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _C.borderLight),
          ),
          _infoRow(
            icon: Iconsax.routing_2,
            label: 'Rute',
            value: '${widget.booking.origin} → ${widget.booking.destination}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _C.borderLight),
          ),
          _infoRow(
            icon: Iconsax.calendar_1,
            label: 'Keberangkatan',
            value: widget.booking.departureDate,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _C.borderLight),
          ),
          _infoRow(
            icon: Iconsax.people,
            label: 'Penumpang',
            value: '${widget.booking.seatsBooked} orang',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _C.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _C.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildRefundSummary() {
    if (widget.booking.status != BookingStatus.paid) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _C.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.info_circle, size: 16, color: _C.warning),
              ),
              const SizedBox(width: 10),
              Text(
                'Rincian Pengembalian Dana',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _refundRow('Total Pembayaran', widget.booking.totalPrice, _C.textPrimary),
          const SizedBox(height: 10),
          _refundRow('Dana Hangus (100%)', _penaltyAmount, _C.danger),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: _C.borderLight),
          ),
          _refundRow('Dana Dikembalikan', _refundAmount, _C.textTertiary),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.dangerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.danger.withValues(alpha: 0.15)),
            ),
            child: Text(
              'PENTING: Dana yang sudah dibayarkan tidak dapat dikembalikan / 100% hangus.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _refundRow(String label, int amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textSecondary,
          ),
        ),
        Text(
          _fmtPrice(amount),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border(
          top: BorderSide(color: _C.borderLight, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirmCancel,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.close_circle, size: 18),
              label: Text(
                _isProcessing ? 'MEMPROSES...' : 'YA, BATALKAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
              icon: const Icon(Iconsax.arrow_left, size: 18),
              label: Text(
                'KEMBALI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.textPrimary,
                side: BorderSide(color: _C.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
