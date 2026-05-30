import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/auth_service.dart';
import '../../payment/presentation/payment_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Navy / Teal / Clean Slate
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
}

// ═══════════════════════════════════════════════════════════
//  CHECKOUT PAGE — Review & create 'pending' booking
//
//  FLOW: SelectFleetPage → CheckoutPage → PaymentPage → LiveETicketPage
//
//  Uses FirebaseFirestore.runTransaction() to atomically:
//   1. Read fleet → check availableSeats
//   2. Deduct availableSeats
//   3. Create booking with status: 'pending'
// ═══════════════════════════════════════════════════════════
class CheckoutPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;
  final int routePrice;
  final String routeSummary;
  final double totalDistance;
  final int totalDurationMinutes;
  final String fleetId;
  final String fleetName;
  final int availableSeats;
  final List<String> selectedSeats;

  const CheckoutPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
    required this.routePrice,
    required this.routeSummary,
    required this.totalDistance,
    required this.totalDurationMinutes,
    required this.fleetId,
    required this.fleetName,
    required this.availableSeats,
    this.selectedSeats = const [],
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;

  // ── Coupon / Promo ──
  final _promoController = TextEditingController();
  int _discountAmount = 0;
  String? _appliedCode;
  bool _isApplyingPromo = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // ── Helpers ──
  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m menit';
    if (m == 0) return '$h jam';
    return '$h jam $m menit';
  }

  int get _subtotal => widget.routePrice * widget.passengers;
  int get _totalPrice => (_subtotal - _discountAmount).clamp(0, _subtotal);

  // ── Apply Promo Code (Firestore) ──
  Future<void> _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // Prevent duplicate apply
    if (_appliedCode != null) {
      _showSnack('Diskon sudah diterapkan. Hapus dulu untuk ganti kode.', isError: true);
      return;
    }
    if (_isApplyingPromo) return;

    setState(() => _isApplyingPromo = true);

    try {
      // Query Firestore for the promo code
      final snapshot = await FirebaseFirestore.instance
          .collection('promo_codes')
          .where('code', isEqualTo: code)
          .get();

      if (!mounted) return;

      // Validation 1: Not found
      if (snapshot.docs.isEmpty) {
        _showSnack('Kode Promo tidak ditemukan', isError: true);
        return;
      }

      final data = snapshot.docs.first.data();

      // Validation 2: Not active
      if (data['isActive'] != true) {
        _showSnack('Kode Promo sudah tidak aktif', isError: true);
        return;
      }

      // Validation 3: Expired
      final expiryDate = data['expiryDate'] as Timestamp?;
      if (expiryDate != null && expiryDate.toDate().isBefore(DateTime.now())) {
        _showSnack('Kode Promo sudah kedaluwarsa', isError: true);
        return;
      }

      // ── Calculate discount ──
      final discountType = data['discountType'] ?? 'percentage';
      final discountValue = (data['discountValue'] as num?)?.toDouble() ?? 0;
      int discount = 0;

      if (discountType == 'percentage') {
        discount = (_subtotal * (discountValue / 100)).round();
      } else {
        discount = discountValue.toInt();
        if (discount > _subtotal) discount = _subtotal;
      }

      setState(() {
        _discountAmount = discount;
        _appliedCode = code;
      });
      _showSnack('Kupon Berhasil Diterapkan! Hemat ${_fmtPrice(discount)}');
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal memvalidasi kode: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isApplyingPromo = false);
    }
  }

  void _removePromo() {
    setState(() {
      _discountAmount = 0;
      _appliedCode = null;
      _promoController.clear();
    });
  }

  // ─────────────────────────────────────────────────────
  //  CREATE PENDING BOOKING — Firestore Transaction
  // ─────────────────────────────────────────────────────
  Future<void> _proceedToPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Belum login');

      // Fetch user profile for name
      final profile = await AuthService.fetchCurrentUserProfile();
      final userName = profile?['namaLengkap'] ?? user.displayName ?? 'User';

      final dateStr = DateFormat('dd MMM yyyy').format(widget.date);

      // Parse actual seat numbers from selectedSeats labels
      final seatNumbers = widget.selectedSeats.isNotEmpty
          ? widget.selectedSeats
                .map((s) => int.tryParse(s) ?? 0)
                .where((n) => n > 0)
                .toList()
          : List.generate(widget.passengers, (i) => i + 1);

      final booking = BookingModel(
        userId: user.uid,
        userName: userName,
        fleetId: widget.fleetId,
        fleetName: widget.fleetName,
        origin: widget.origin,
        destination: widget.destination,
        departureDate: dateStr,
        seatNumbers: seatNumbers,
        seatsBooked: widget.passengers,
        totalPrice: _totalPrice, // After discount
        bookingCode: '', // Generated by BookingService
        selectedSeatLabels: widget.selectedSeats,
      );

      // Atomic transaction: check seats → deduct → create pending booking
      // Also validates bookedSeats to prevent double-booking
      final result = await BookingService.createBooking(booking);

      if (!mounted) return;

      // Navigate to Payment Gateway page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            bookingId: result.id!,
            bookingCode: result.bookingCode,
            totalAmount: _totalPrice,
            origin: widget.origin,
            destination: widget.destination,
            fleetName: widget.fleetName,
            passengers: widget.passengers,
            departureDate: dateStr,
            expiryDate: result.expiryDate!,
          ),
        ),
      );
    } on SeatAlreadyBookedException catch (e) {
      if (!mounted) return;
      _showSeatConflictDialog(e.conflictedSeats);
    } on InsufficientSeatsException catch (e) {
      if (!mounted) return;
      _showSnack(
        'Kursi tidak cukup. Tersedia: ${e.available}',
        isError: true,
      );
    } on FleetNotFoundException {
      if (!mounted) return;
      _showSnack('Armada tidak ditemukan', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memproses: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Iconsax.close_circle : Iconsax.tick_circle,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? _C.danger : _C.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _showSeatConflictDialog(List<String> seats) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _C.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.warning_2, size: 22, color: _C.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kursi Sudah Terisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Maaf, kursi ${seats.join(", ")} baru saja dipesan orang lain.\n\nSilakan kembali ke halaman pilih kursi untuk memilih kursi yang tersedia.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Go back to seat selection
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: _C.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Pilih Ulang Kursi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id_ID').format(widget.date);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ═══ APP BAR ═══
          _buildAppBar(topPadding),

          // ═══ CONTENT ═══
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section: Rute Perjalanan ──
                  _sectionTitle('Rute Perjalanan', Iconsax.routing_2, 0),
                  const SizedBox(height: 10),
                  _buildRouteCard(dateStr, 100),

                  const SizedBox(height: 20),

                  // ── Section: Armada ──
                  _sectionTitle('Armada', Iconsax.bus, 150),
                  const SizedBox(height: 10),
                  _buildFleetCard(200),

                  // ── Section: Kursi Dipilih ──
                  if (widget.selectedSeats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Kursi Dipilih', Iconsax.driver, 220),
                    const SizedBox(height: 10),
                    _buildSelectedSeatsCard(240),
                  ],

                  const SizedBox(height: 20),

                  // ── Section: Kode Promo ──
                  _sectionTitle('Kode Promo', Iconsax.discount_shape, 250),
                  const SizedBox(height: 10),
                  _buildPromoCard(300),

                  const SizedBox(height: 20),

                  // ── Section: Rincian Harga ──
                  _sectionTitle('Rincian Harga', Iconsax.receipt_2, 350),
                  const SizedBox(height: 10),
                  _buildPriceCard(400),

                  const SizedBox(height: 20),

                  // ── Info Box ──
                  _buildInfoBox(500),
                ],
              ),
            ),
          ),

          // ═══ BOTTOM CTA ═══
          _buildBottomCTA(bottomPadding),
        ],
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
        border: Border(
          bottom: BorderSide(color: _C.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Text(
            'Checkout',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.shield_tick, size: 13, color: _C.teal),
                const SizedBox(width: 4),
                Text(
                  'Aman',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ── Section Title ─────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, int delayMs) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ── Route Card ────────────────────────────────────
  Widget _buildRouteCard(String dateStr, int delayMs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          // Origin → Destination
          Row(
            children: [
              _routeDot(_C.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.origin,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Dotted line
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 22,
                  color: _C.borderLight,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.routeSummary,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _C.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _routeDot(_C.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.destination,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _C.borderLight),
          const SizedBox(height: 12),
          // Meta chips
          Row(
            children: [
              _metaChip(Iconsax.calendar_1, dateStr),
              const SizedBox(width: 14),
              _metaChip(Iconsax.people, '${widget.passengers} penumpang'),
              const Spacer(),
              _metaChip(
                Iconsax.clock,
                _fmtDuration(widget.totalDurationMinutes),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _routeDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _C.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _C.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Fleet Card ────────────────────────────────────
  Widget _buildFleetCard(int delayMs) {
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.bus, size: 24, color: _C.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fleetName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.people, size: 12, color: _C.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.availableSeats} kursi tersedia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tersedia',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.success,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ── Selected Seats Card ───────────────────────────
  Widget _buildSelectedSeatsCard(int delayMs) {
    final seats = widget.selectedSeats..sort();
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
          Row(
            children: [
              Icon(Iconsax.driver, size: 16, color: _C.primary),
              const SizedBox(width: 8),
              Text(
                '${seats.length} Kursi Dipilih',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seats.map((seat) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _C.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  seat,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ── Promo Card ────────────────────────────────────
  Widget _buildPromoCard(int delayMs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: _appliedCode != null
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.ticket_discount,
                      size: 20, color: _C.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appliedCode!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hemat ${_fmtPrice(_discountAmount)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: _C.success,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _removePromo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _C.danger.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.close_circle,
                        size: 16, color: _C.danger),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan Kode Promo',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: _C.textTertiary,
                      ),
                      prefixIcon: const Icon(Iconsax.ticket_discount,
                          size: 18, color: _C.textTertiary),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 40),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _C.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _C.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: _C.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: _C.bg,
                    ),
                    onSubmitted: (_) => _applyPromo(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _isApplyingPromo ? null : _applyPromo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor:
                          _C.teal.withValues(alpha: 0.5),
                    ),
                    child: _isApplyingPromo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Terapkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ── Price Card ────────────────────────────────────
  Widget _buildPriceCard(int delayMs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          _priceRow('Harga rute', _fmtPrice(widget.routePrice)),
          if (widget.passengers > 1) ...[
            const SizedBox(height: 10),
            _priceRow('Jumlah penumpang', '× ${widget.passengers}'),
          ],
          const SizedBox(height: 10),
          _priceRow('Subtotal', _fmtPrice(_subtotal)),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.discount_shape,
                        size: 13, color: _C.success),
                    const SizedBox(width: 4),
                    Text(
                      'Diskon ($_appliedCode)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _C.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  '- ${_fmtPrice(_discountAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: _C.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              Text(
                _fmtPrice(_totalPrice),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textTertiary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Info Box ──────────────────────────────────────
  Widget _buildInfoBox(int delayMs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.teal.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.info_circle, size: 16, color: _C.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setelah menekan "Lanjut ke Pembayaran", kursi akan dikunci selama 15 menit. '
              'Segera selesaikan pembayaran sebelum batas waktu habis.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _C.teal,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
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
      child: Row(
        children: [
          // Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _C.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtPrice(_totalPrice),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),

          // CTA Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lanjut ke Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Iconsax.arrow_right_3, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
