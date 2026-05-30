import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/email_ticket_service.dart';
import '../../e_ticket/presentation/live_e_ticket_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
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
//  PAYMENT PAGE — Simulated Payment Gateway (Midtrans-like)
//
//  Accordion: Virtual Account / E-Wallet / QRIS
//  Countdown timer: 15 minutes
//  "Simulasikan Pembayaran Berhasil" button →
//    BookingService.confirmPayment(bookingId) →
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
  final DateTime expiryDate;

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
    required this.expiryDate,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // ── Payment method selection ──
  int _selectedMethodGroup = 0; // 0=VA, 1=E-Wallet, 2=QRIS
  int _selectedSubMethod = 0; // index within group

  // ── Countdown (from expiryDate) ──
  late Timer _timer;
  late int _remainingSeconds;

  // ── Processing state ──
  bool _isProcessing = false;
  bool _paymentDone = false;

  // ── Dummy VA numbers per bank ──
  final List<String> _vaNumbers = [];

  // ── Payment method groups ──
  static const _vaOptions = [
    {'name': 'BCA Virtual Account', 'icon': 'BCA'},
    {'name': 'Mandiri Virtual Account', 'icon': 'MDR'},
    {'name': 'BRI Virtual Account', 'icon': 'BRI'},
    {'name': 'BNI Virtual Account', 'icon': 'BNI'},
  ];

  static const _ewalletOptions = [
    {'name': 'GoPay', 'icon': 'GP'},
    {'name': 'OVO', 'icon': 'OVO'},
    {'name': 'DANA', 'icon': 'DNA'},
    {'name': 'ShopeePay', 'icon': 'SPY'},
  ];

  @override
  void initState() {
    super.initState();

    // Generate random VA numbers
    final rng = Random();
    for (int i = 0; i < 4; i++) {
      final prefix = ['8800', '8900', '1020', '8800'][i];
      final rest =
          List.generate(12, (_) => rng.nextInt(10).toString()).join();
      _vaNumbers.add('$prefix $rest');
    }

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
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
  //  SIMULATE PAYMENT — confirm in Firestore
  // ─────────────────────────────────────────────────
  Future<void> _simulatePayment() async {
    if (_isProcessing || _paymentDone) return;
    setState(() => _isProcessing = true);

    // Cancel countdown immediately to prevent race condition
    // where timer expires during payment processing
    _timer.cancel();

    try {
      // Simulate gateway processing delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Confirm in Firestore: status 'pending' → 'paid'
      await BookingService.confirmPayment(widget.bookingId);

      // ── Kirim E-Ticket ke email (fire-and-forget, tidak blocking) ──
      _sendEmailTicketInBackground();

      if (!mounted) return;
      setState(() {
        _paymentDone = true;
        _isProcessing = false;
      });

      // Brief success animation, then navigate
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveETicketPage(bookingId: widget.bookingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
                    'Gagal memproses pembayaran: $e',
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

  // ─────────────────────────────────────────────────
  //  SEND E-TICKET EMAIL — fire-and-forget via EmailJS
  // ─────────────────────────────────────────────────
  void _sendEmailTicketInBackground() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final route = '${widget.origin} → ${widget.destination}';

    // Tidak perlu await — berjalan di background agar tidak delay UX.
    EmailTicketService.sendEmailTicket(
      userEmail: user.email!,
      userName: user.displayName ?? 'Pengguna E-Travel',
      bookingId: widget.bookingCode,
      route: route,
      fleetName: widget.fleetName,
    );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Amount & Countdown ──
                          _buildAmountCard(),
                          const SizedBox(height: 20),

                          // ── Booking Summary ──
                          _buildBookingSummary(),
                          const SizedBox(height: 20),

                          // ── Payment Methods ──
                          _sectionTitle('Pilih Metode Pembayaran'),
                          const SizedBox(height: 10),
                          _buildMethodTabs(),
                          const SizedBox(height: 12),
                          _buildMethodDetail(),
                          const SizedBox(height: 24),
                        ],
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
                              // ── Cancel booking in Firestore ──
                              try {
                                await BookingService.cancelBooking(
                                    widget.bookingId);
                              } catch (_) {}
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

  // ── Amount Card ───────────────────────────────────
  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF0D7377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Total Pembayaran',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmtPrice(widget.totalAmount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Kode: ${widget.bookingCode}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.clock, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Bayar sebelum ${_fmtCountdown()}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  // ── Booking Summary ───────────────────────────────
  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pemesanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(Iconsax.routing_2,
              '${widget.origin} → ${widget.destination}'),
          const SizedBox(height: 8),
          _summaryRow(Iconsax.bus, widget.fleetName),
          const SizedBox(height: 8),
          _summaryRow(
              Iconsax.calendar_1, widget.departureDate),
          const SizedBox(height: 8),
          _summaryRow(Iconsax.people, '${widget.passengers} penumpang'),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _C.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _C.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  // ── Method Tabs ───────────────────────────────────
  Widget _buildMethodTabs() {
    final tabs = [
      {'icon': Iconsax.bank, 'label': 'Virtual Account'},
      {'icon': Iconsax.wallet_2, 'label': 'E-Wallet'},
      {'icon': Iconsax.scan_barcode, 'label': 'QRIS'},
    ];
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _selectedMethodGroup == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMethodGroup = i;
                _selectedSubMethod = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? _C.primary.withValues(alpha: 0.06)
                    : _C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _C.primary : _C.borderLight,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    tabs[i]['icon'] as IconData,
                    size: 20,
                    color: selected ? _C.primary : _C.textTertiary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tabs[i]['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _C.primary : _C.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    )
        .animate()
        .fadeIn(delay: 250.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ── Method Detail ─────────────────────────────────
  Widget _buildMethodDetail() {
    if (_selectedMethodGroup == 0) return _buildVASection();
    if (_selectedMethodGroup == 1) return _buildEWalletSection();
    return _buildQRISSection();
  }

  // ── Virtual Account ───────────────────────────────
  Widget _buildVASection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_vaOptions.length, (i) {
              final selected = _selectedSubMethod == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubMethod = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _C.primary.withValues(alpha: 0.06)
                        : _C.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _C.primary : _C.borderLight,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _vaOptions[i]['icon']!,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _C.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _vaOptions[i]['name']!.replaceAll(' Virtual Account', ''),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _C.primary : _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _C.borderLight),
          const SizedBox(height: 16),
          // VA Number
          Text(
            'Nomor Virtual Account',
            style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _vaNumbers[_selectedSubMethod],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                      text: _vaNumbers[_selectedSubMethod]
                          .replaceAll(' ', ''),
                    ));
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(
                          'Nomor VA disalin',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Iconsax.copy, size: 16, color: _C.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Instructions
          _instructionItem('1', 'Buka aplikasi m-Banking atau ATM'),
          _instructionItem('2', 'Pilih menu "Transfer" → "Virtual Account"'),
          _instructionItem('3', 'Masukkan nomor VA di atas'),
          _instructionItem('4', 'Konfirmasi dan selesaikan pembayaran'),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── E-Wallet ──────────────────────────────────────
  Widget _buildEWalletSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_ewalletOptions.length, (i) {
              final selected = _selectedSubMethod == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubMethod = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _C.teal.withValues(alpha: 0.06)
                        : _C.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _C.teal : _C.borderLight,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _ewalletOptions[i]['icon']!,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _C.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ewalletOptions[i]['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _C.teal : _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _C.borderLight),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _C.teal.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Iconsax.mobile, size: 28, color: _C.teal),
                ),
                const SizedBox(height: 12),
                Text(
                  'Anda akan diarahkan ke ${_ewalletOptions[_selectedSubMethod]['name']}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _C.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tekan tombol di bawah untuk simulasi pembayaran',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _C.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── QRIS ──────────────────────────────────────────
  Widget _buildQRISSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          // Simulated QR placeholder
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.borderLight),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Iconsax.scan_barcode, size: 80, color: _C.borderLight),
                // Fake QR pattern
                GridView.count(
                  crossAxisCount: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  children: List.generate(100, (i) {
                    final show = (i * 7 + i ~/ 10 * 3) % 3 != 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: show
                            ? _C.textPrimary.withValues(alpha: 0.7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan QR Code untuk membayar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gunakan aplikasi e-wallet atau mobile banking\nyang mendukung QRIS',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _C.textTertiary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── Instruction Item ──────────────────────────────
  Widget _instructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _C.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _simulatePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.success,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Memproses...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.tick_circle, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Simulasikan Pembayaran Berhasil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
