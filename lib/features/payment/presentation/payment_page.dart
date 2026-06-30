import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/midtrans_service.dart';
import '../../e_ticket/presentation/live_e_ticket_page.dart';
import 'midtrans_webview_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────
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

// ═══════════════════════════════════════════════════════════
//  PAYMENT PAGE — Midtrans Snap Integration (Sandbox)
//
//  Countdown timer: 15 minutes
//  "Bayar dengan Midtrans" button →
//    MidtransService.generateSnapToken() →
//    MidtransWebviewPage (WebView Snap) →
//    BookingService.confirmPayment() →
//    Navigate to LiveETicketPage
// ═══════════════════════════════════════════════════════════
class PaymentPage extends StatefulWidget {
  final String bookingId;
  final String bookingCode;
  final int totalAmount;
  final String origin;
  final String destination;
  final String fleetName;
  final int passengers;
  final String departureDate;
  final String departureTime;
  final DateTime expiryDate;

  /// Custom order ID for Midtrans (defaults to [bookingId]).
  /// Used for reschedule admin fee to avoid duplicate order_id error.
  final String? customMidtransOrderId;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    required this.totalAmount,
    required this.origin,
    required this.destination,
    required this.fleetName,
    required this.passengers,
    required this.departureDate,
    required this.departureTime,
    required this.expiryDate,
    this.customMidtransOrderId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // ── Countdown (from expiryDate) ──
  late Timer _timer;
  late int _remainingSeconds;

  // ── Processing state ──
  bool _isProcessing = false;
  bool _paymentDone = false;

  // ── Booking status stream ──
  StreamSubscription<BookingModel?>? _bookingSub;
  BookingStatus? _initialStatus;

  @override
  void initState() {
    super.initState();

    // Compute remaining seconds from expiryDate
    final diff = widget.expiryDate.difference(DateTime.now()).inSeconds;
    _remainingSeconds = diff > 0 ? diff : 0;

    // Start countdown
    if (_remainingSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds > 0 && !_paymentDone) {
          setState(() => _remainingSeconds--);
        } else if (_remainingSeconds <= 0 && !_paymentDone) {
          _timer.cancel();
          _handleExpired();
        }
      });
    } else {
      _timer = Timer(Duration.zero, () {});
      // Already expired on entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_paymentDone) _handleExpired();
      });
    }

    // Listen for booking status changes (e.g. paid by webhook)
    _bookingSub = BookingService.bookingStream(widget.bookingId).listen(_onBookingChanged);
  }

  @override
  void dispose() {
    _timer.cancel();
    _bookingSub?.cancel();
    super.dispose();
  }

  /// Handle real-time booking status changes.
  void _onBookingChanged(BookingModel? booking) {
    if (!mounted || booking == null || _isProcessing) return;

    // Skip auto-redirect if booking was already paid when page opened
    // (e.g. reschedule admin fee payment where booking stays paid)
    _initialStatus ??= booking.status;
    if (_initialStatus == BookingStatus.paid && booking.status == BookingStatus.paid) return;

    switch (booking.status) {
      case BookingStatus.paid:
      case BookingStatus.validated:
      case BookingStatus.used:
      case BookingStatus.completed:
        _paymentDone = true;
        _timer.cancel();
        _bookingSub?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveETicketPage(bookingId: widget.bookingId),
            ),
          );
        }
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        _timer.cancel();
        _bookingSub?.cancel();
        if (mounted) {
          _showCancelledDialog();
        }
      case BookingStatus.pending:
        // Normal — continue showing payment page
        break;
    }
  }

  void _showCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.close_circle, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(
              'Pesanan Dibatalkan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Pesanan ini telah dibatalkan.\n\nSilakan lakukan pemesanan ulang.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F4C81),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _fmtCountdown() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _countdownColor {
    if (_remainingSeconds <= 60) return _C.danger;
    if (_remainingSeconds <= 180) return _C.warning;
    return _C.primary;
  }

  Future<void> _handleExpired() async {
    if (!mounted || _isProcessing || _paymentDone) return;

    _bookingSub?.cancel();

    // ── Auto-cancel the booking in Firestore ──
    try {
      await BookingService.cancelBooking(widget.bookingId);
    } catch (_) {
      // Silent — best-effort cancel on expiry
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.clock, color: _C.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              'Waktu Habis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Batas waktu pembayaran telah habis.\n\n'
          'Pesanan Anda telah dibatalkan secara otomatis. '
          'Kursi kembali tersedia untuk penumpang lain.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Kembali',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  PAY WITH MIDTRANS — generate Snap token → WebView
  // ─────────────────────────────────────────────────
  Future<void> _payWithMidtrans() async {
    if (_isProcessing || _paymentDone) return;
    setState(() => _isProcessing = true);

    _timer.cancel();

    // Cancel booking stream while in WebView to avoid double-redirect
    _bookingSub?.cancel();
    _bookingSub = null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final tokenResult = await MidtransService.generateSnapToken(
        orderId: widget.customMidtransOrderId ?? widget.bookingId,
        grossAmount: widget.totalAmount,
        customerName: user?.displayName,
        customerEmail: user?.email,
        itemName: '${widget.origin} → ${widget.destination}',
        itemQuantity: widget.passengers,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Navigate to Midtrans WebView for payment
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransWebviewPage(
            bookingId: widget.bookingId,
            bookingCode: widget.bookingCode,
            snapUrl: tokenResult.redirectUrl,
          ),
        ),
      );

      // After returning from WebView, check if payment was done
      if (!mounted) return;

      if (result == true) {
        // Payment was completed in WebView → redirect to e-tiket
        _paymentDone = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveETicketPage(bookingId: widget.bookingId),
          ),
        );
        return;
      }

      // Re-check booking status (may have been paid via webhook)
      _bookingSub = BookingService.bookingStream(widget.bookingId).listen(_onBookingChanged);

      // Restart countdown if not expired
      final diff = widget.expiryDate.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        _remainingSeconds = diff;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_remainingSeconds > 0 && !_paymentDone) {
            setState(() => _remainingSeconds--);
          } else if (_remainingSeconds <= 0 && !_paymentDone) {
            _timer.cancel();
            _handleExpired();
          }
        });
      } else {
        _handleExpired();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _paymentDone = false;
      });

      // Re-subscribe to booking stream
      _bookingSub?.cancel();
      _bookingSub = BookingService.bookingStream(widget.bookingId).listen(_onBookingChanged);

      // Restart countdown if not expired
      final diff = widget.expiryDate.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        _remainingSeconds = diff;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_remainingSeconds > 0 && !_paymentDone) {
            setState(() => _remainingSeconds--);
          } else if (_remainingSeconds <= 0 && !_paymentDone) {
            _timer.cancel();
            _handleExpired();
          }
        });
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.close_circle,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gagal memproses: ${e.toString().replaceFirst('Exception: ', '')}',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildAppBar(topPadding),
            Expanded(
              child: _paymentDone
                  ? _buildSuccessOverlay()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // ── Cashier Receipt (Integrated Amount & Summary) ──
                          _buildCashierReceipt(),
                          const SizedBox(height: 20),

                          // ── Payment Methods (Midtrans Snap) ──
                          _sectionTitle('Metode Pembayaran'),
                          const SizedBox(height: 10),
                          _buildMidtransInfo(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
            ),
            if (!_paymentDone) _buildBottomCTA(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────
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
            onPressed: _isProcessing
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          'Batalkan Pembayaran?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Kursi yang sudah dilock akan dilepas kembali.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: _C.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Tetap Bayar',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _C.textTertiary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              _bookingSub?.cancel();
                              // ── Cancel only reschedule, not original booking ──
                              if (widget.customMidtransOrderId == null) {
                                try {
                                  await BookingService.cancelBooking(
                                      widget.bookingId);
                                } catch (_) {}
                              }
                              if (mounted) Navigator.pop(context);
                            },
                            child: Text(
                              'Batalkan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _C.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Text(
            'Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          // Countdown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _countdownColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.clock, size: 13, color: _countdownColor),
                const SizedBox(width: 4),
                Text(
                  _fmtCountdown(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _countdownColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ── Cashier Receipt (Integrated Amount & Summary) ──
  Widget _buildCashierReceipt() {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Receipt Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Store Info)
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.ticket_discount,
                          size: 24,
                          color: _C.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TIKET ELEKTRONIK TRAVEL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sumatera Barat Express Delivery',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _C.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dashed line 1 (Top portion cut)
                _buildDottedLine(),
                const SizedBox(height: 20),

                // Booking Code and Barcode Simulator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KODE BOOKING',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _C.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bookingCode,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    // Barcode design
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(12, (index) {
                              final widths = [2.0, 4.0, 1.0, 3.0, 2.0, 5.0, 1.0, 3.0, 2.0, 1.0, 4.0, 2.0];
                              return Container(
                                width: widths[index % widths.length],
                                height: double.infinity,
                                color: _C.textPrimary.withValues(alpha: 0.8),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SANDBOX',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _C.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Expiry timer row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _countdownColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.clock, size: 16, color: _countdownColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _C.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Bayar sebelum '),
                              TextSpan(
                                text: _fmtCountdown(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.w800,
                                  color: _countdownColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dashed line 2 (Middle portion cut)
                _buildDottedLine(),
                const SizedBox(height: 20),

                // Trip Details Section
                Text(
                  'DETAIL PERJALANAN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _C.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),

                // Receipt Row: Route
                _receiptDetailRow('Rute', '${widget.origin} → ${widget.destination}'),
                const SizedBox(height: 10),

                // Receipt Row: Fleet
                _receiptDetailRow('Armada', widget.fleetName),
                const SizedBox(height: 10),

                // Receipt Row: Date & Time
                _receiptDetailRow('Jadwal', '${widget.departureDate} (${widget.departureTime})'),
                const SizedBox(height: 10),

                // Receipt Row: Passengers
                _receiptDetailRow('Penumpang', '${widget.passengers} Pax'),
                const SizedBox(height: 24),

                // Dashed line 3 (Total cut)
                _buildDottedLine(),
                const SizedBox(height: 20),

                // Payment amount section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL BAYAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      _fmtPrice(widget.totalAmount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _C.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Left Circular Cutout
          Positioned(
            left: -10,
            top: 250, // aligns close to second dotted line
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: _C.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Right Circular Cutout
          Positioned(
            right: -10,
            top: 250, // aligns close to second dotted line
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: _C.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (index) {
            return SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _C.borderLight.withValues(alpha: 0.8),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _receiptDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ── Section Title ─────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _C.textPrimary,
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ── Midtrans Info ──────────────────────────────────
  Widget _buildMidtransInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Iconsax.card, size: 32, color: _C.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Bayar dengan Midtrans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Virtual Account • E-Wallet • QRIS •\n'
            'dan metode pembayaran lainnya',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _C.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _C.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.shield_tick, size: 14, color: _C.success),
              const SizedBox(width: 8),
              Text(
                'Pembayaran aman & terenkripsi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _C.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── Success Overlay ───────────────────────────────
  Widget _buildSuccessOverlay() {
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
            child: const Icon(
              Iconsax.tick_circle,
              size: 48,
              color: _C.success,
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut),
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
            'Mengarahkan ke e-tiket...',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textTertiary,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  // ── Bottom CTA ────────────────────────────────────
  Widget _buildBottomCTA(double bottomPadding) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    Widget ctaContent = SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _payWithMidtrans,
          icon: _isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Iconsax.card, size: 18),
          label: Text(
            _isProcessing ? 'Memproses...' : 'Bayar dengan Midtrans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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
      );

    if (isTablet) {
      ctaContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ctaContent,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 16),
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border(
          top: BorderSide(color: _C.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ctaContent,
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
