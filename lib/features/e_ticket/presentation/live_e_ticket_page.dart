// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/pdf_ticket_service.dart';
import '../../../core/services/whatsapp_ticket_service.dart';
import '../../navigation/presentation/main_navigation_screen.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Clean Slate / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
}

// ═══════════════════════════════════════════════════════════
//  LIVE E-TICKET PAGE — Real-time booking status via Stream
//
//  SINKRONISASI 2 (dampak di User):
//  StreamBuilder on single booking document listens for status changes.
//  When sopir scans QR → status changes 'paid' → 'completed' →
//  QR Code section animates into "TIKET TELAH DIGUNAKAN" stamp.
//
//  This page works with a bookingId from Firestore.
// ═══════════════════════════════════════════════════════════
class LiveETicketPage extends StatelessWidget {
  /// Firestore booking document ID.
  final String bookingId;

  const LiveETicketPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: StreamBuilder<BookingModel?>(
                stream: BookingService.bookingStream(bookingId),
                builder: (context, snapshot) {
                  // ── Loading ──
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.primary),
                    );
                  }

                  // ── Not found ──
                  final booking = snapshot.data;
                  if (booking == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.ticket_expired,
                            size: 56,
                            color: _C.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tiket tidak ditemukan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ── Render ticket ──
                  final mq = MediaQuery.of(context);
                  final isSmall = mq.size.width < 360;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isSmall ? 16 : 22,
                      16,
                      isSmall ? 16 : 22,
                      mq.padding.bottom + 32,
                    ),
                    child: Column(
                      children: [
                        _LiveTicketCard(booking: booking, isSmall: isSmall),
                        // ═══ PDF ACTION BUTTONS ═══
                        if (booking.status == BookingStatus.paid ||
                            booking.status == BookingStatus.used ||
                            booking.status == BookingStatus.completed)
                          _PdfActionButtons(booking: booking),

                        // ═══ KIRIM KE WHATSAPP ═══
                        if (booking.status == BookingStatus.paid ||
                            booking.status == BookingStatus.used ||
                            booking.status == BookingStatus.completed)
                          _WhatsAppShareButton(booking: booking),

                        // ═══ KEMBALI KE BERANDA ═══
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const MainNavigationScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Iconsax.home_2, size: 20),
                            label: Text(
                              'Kembali ke Beranda',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 14),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'E-Ticket Saya',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  LIVE TICKET CARD — Status-Reactive
// ═══════════════════════════════════════════════════════════
class _LiveTicketCard extends StatelessWidget {
  final BookingModel booking;
  final bool isSmall;

  const _LiveTicketCard({required this.booking, required this.isSmall});

  String get _seatLabel => booking.seatNumbers.isNotEmpty
      ? booking.seatNumbers.map((s) => 'No. $s').join(', ')
      : 'Belum Dipilih';

  String get _price {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(booking.totalPrice)}';
  }

  bool get _isUsed => booking.status.isValidated;
  bool get _isCancelled => booking.status == BookingStatus.cancelled;

  // Status badge config
  _StatusBadge get _badge {
    switch (booking.status) {
      case BookingStatus.paid:
        return _StatusBadge(
          label: 'Lunas',
          icon: Iconsax.tick_circle,
          color: _C.success,
          bgColor: _C.successBg,
          borderColor: _C.success.withValues(alpha: 0.3),
        );
      case BookingStatus.validated:
        return _StatusBadge(
          label: 'Tervalidasi',
          icon: Iconsax.shield_tick,
          color: _C.info,
          bgColor: _C.infoBg,
          borderColor: _C.info.withValues(alpha: 0.3),
        );
      case BookingStatus.used:
        return _StatusBadge(
          label: 'Tervalidasi',
          icon: Iconsax.verify,
          color: _C.info,
          bgColor: _C.infoBg,
          borderColor: _C.info.withValues(alpha: 0.3),
        );
      case BookingStatus.completed:
        return _StatusBadge(
          label: 'Digunakan',
          icon: Iconsax.verify,
          color: _C.info,
          bgColor: _C.infoBg,
          borderColor: _C.info.withValues(alpha: 0.3),
        );
      case BookingStatus.cancelled:
        return _StatusBadge(
          label: 'Dibatalkan',
          icon: Iconsax.close_circle,
          color: _C.error,
          bgColor: _C.errorBg,
          borderColor: _C.error.withValues(alpha: 0.3),
        );
      case BookingStatus.pending:
        return _StatusBadge(
          label: 'Pending',
          icon: Iconsax.clock,
          color: _C.warning,
          bgColor: _C.warningBg,
          borderColor: _C.warning.withValues(alpha: 0.3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ═══ TOP HALF — Route & schedule info ═══
        Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 18 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: App name + status badge ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _C.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Iconsax.bus,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'E-Travel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _C.primary,
                              ),
                            ),
                          ],
                        ),
                        // ── REACTIVE STATUS BADGE ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey(booking.status),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _badge.bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _badge.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _badge.icon,
                                  size: 13,
                                  color: _badge.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _badge.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _badge.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Route ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dari',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.origin,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isSmall ? 17 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: _C.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _C.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.arrow_right_3,
                                  size: 18,
                                  color: _C.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tujuan',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.destination,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isSmall ? 17 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: _C.textPrimary,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Date row ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _C.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _C.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.calendar_1,
                            size: 16,
                            color: _C.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.departureDate.isNotEmpty
                                  ? booking.departureDate
                                  : '-',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .slideY(begin: 0.06, delay: 100.ms, duration: 500.ms),

        // ═══ PERFORATED LINE ═══
        SizedBox(
          width: double.infinity,
          height: 28,
          child: CustomPaint(
            painter: _PerforatedLinePainter(bgColor: _C.bg, cardColor: _C.card),
          ),
        ),

        // ═══ BOTTOM HALF — Passenger details & QR / STAMP ═══
        Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 18 : 22),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Iconsax.user,
                      label: 'Nama Penumpang',
                      value: booking.userName,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Iconsax.driver,
                      label: 'Nomor Kursi',
                      value: _seatLabel,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Iconsax.bus,
                      label: 'Armada',
                      value: booking.fleetName,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Iconsax.receipt_2,
                      label: 'Kode Booking',
                      value: booking.bookingCode,
                      isMono: true,
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Iconsax.money_send,
                      label: 'Total Dibayar',
                      value: _price,
                    ),

                    const SizedBox(height: 24),
                    Container(height: 1, color: _C.borderLight),
                    const SizedBox(height: 24),

                    // ═══ QR CODE or "USED" STAMP — Reactive ═══
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutBack,
                      child: _isUsed || _isCancelled
                          ? _buildUsedStamp()
                          : _buildQrCode(isSmall),
                    ),

                    const SizedBox(height: 16),

                    // ── Instruction ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: ValueKey(_isUsed),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (_isUsed
                                      ? _C.info
                                      : _isCancelled
                                      ? _C.error
                                      : _C.primary)
                                  .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              size: 16,
                              color:
                                  (_isUsed
                                          ? _C.info
                                          : _isCancelled
                                          ? _C.error
                                          : _C.primary)
                                      .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isUsed
                                    ? 'Tiket ini sudah digunakan. Selamat menikmati perjalanan!'
                                    : _isCancelled
                                    ? 'Tiket ini telah dibatalkan.'
                                    : 'Tunjukkan QR Code ini kepada sopir saat naik',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .slideY(begin: 0.06, delay: 300.ms, duration: 500.ms),
      ],
    );
  }

  // ── QR Code section ──
  // Uses unique Firestore document ID (booking.id) as QR data
  // for 100% uniqueness. bookingCode shown below for human reference.
  Widget _buildQrCode(bool isSmall) {
    // Use Firestore doc ID (guaranteed unique), fallback to bookingCode
    final qrData = booking.id ?? booking.bookingCode;

    return Container(
      key: const ValueKey('qr'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: isSmall ? 140 : 160,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _C.textPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _C.textPrimary,
            ),
            gapless: true,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 14),
          // Human-readable booking code
          Text(
            booking.bookingCode,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          // Unique document ID (small, as visual identity)
          Text(
            'ID: $qrData',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _C.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── "TIKET TELAH DIGUNAKAN" stamp ──
  Widget _buildUsedStamp() {
    final isCancel = _isCancelled;
    final stampColor = isCancel ? _C.error : _C.info;
    final stampText = isCancel ? 'TIKET\nDIBATALKAN' : 'TIKET TELAH\nDIGUNAKAN';

    return Container(
          key: const ValueKey('stamp'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: stampColor, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stampText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: stampColor,
                    letterSpacing: 3,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }
}

// ── Detail row ──
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;
  final bool isMono;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isHighlighted ? _C.primary.withValues(alpha: 0.1) : _C.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isHighlighted ? _C.primary : _C.textTertiary,
            ),
          ),
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
                  fontWeight: FontWeight.w500,
                  color: _C.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: isMono
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: isHighlighted ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                        letterSpacing: 1.5,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: isHighlighted ? 17 : 14,
                        fontWeight: isHighlighted
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isHighlighted ? _C.primary : _C.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PDF ACTION BUTTONS — Download & Share
// ═══════════════════════════════════════════════════════════
class _PdfActionButtons extends StatefulWidget {
  final BookingModel booking;
  const _PdfActionButtons({required this.booking});

  @override
  State<_PdfActionButtons> createState() => _PdfActionButtonsState();
}

class _PdfActionButtonsState extends State<_PdfActionButtons> {
  bool _isDownloading = false;
  bool _isSharing = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await PdfTicketService.generateTicketPdf(widget.booking);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'E-Ticket_${widget.booking.bookingCode}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan PDF: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    if (mounted) setState(() => _isDownloading = false);
  }

  Future<void> _sharePdf() async {
    setState(() => _isSharing = true);
    try {
      await PdfTicketService.sharePdf(widget.booking);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membagikan: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              // ── Download PDF ──
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadPdf,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _C.primary,
                            ),
                          )
                        : const Icon(Iconsax.document_download, size: 18),
                    label: Text(
                      'Download PDF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.primary,
                      side: BorderSide(
                        color: _C.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Share Ticket ──
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _sharePdf,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Iconsax.share, size: 18),
                    label: Text(
                      'Bagikan Tiket',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.06, delay: 500.ms, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  WHATSAPP SHARE BUTTON — Kirim E-Ticket ke WhatsApp
// ═══════════════════════════════════════════════════════════
class _WhatsAppShareButton extends StatefulWidget {
  final BookingModel booking;
  const _WhatsAppShareButton({required this.booking});

  @override
  State<_WhatsAppShareButton> createState() => _WhatsAppShareButtonState();
}

class _WhatsAppShareButtonState extends State<_WhatsAppShareButton> {
  bool _isSending = false;

  Future<void> _sendToWhatsApp() async {
    setState(() => _isSending = true);
    try {
      final route = '${widget.booking.origin} → ${widget.booking.destination}';
      final success = await WhatsAppTicketService.shareTicketToWhatsApp(
        bookingId: widget.booking.bookingCode,
        route: route,
        fleetName: widget.booking.fleetName,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstall.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: _C.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka WhatsApp: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendToWhatsApp,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat, size: 18),
              label: Text(
                'Kirim ke WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.06, delay: 600.ms, duration: 400.ms);
  }
}

// ── Status badge data class ──
class _StatusBadge {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });
}

// ── Perforated line painter (same as original e_ticket_page) ──
class _PerforatedLinePainter extends CustomPainter {
  final Color bgColor;
  final Color cardColor;
  _PerforatedLinePainter({required this.bgColor, required this.cardColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final radius = h / 2;

    final bgPaint = Paint()..color = cardColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final cutoutPaint = Paint()..color = bgColor;
    canvas.drawCircle(Offset(0, midY), radius, cutoutPaint);
    canvas.drawCircle(Offset(w, midY), radius, cutoutPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final startX = radius + 8;
    final endX = w - radius - 8;
    var x = startX;
    while (x < endX) {
      final drawEnd = (x + dashWidth).clamp(startX, endX);
      canvas.drawLine(Offset(x, midY), Offset(drawEnd, midY), dashPaint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforatedLinePainter old) =>
      bgColor != old.bgColor || cardColor != old.cardColor;
}
