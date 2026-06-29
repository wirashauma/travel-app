// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/booking_model.dart';

// ─────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary    = Color(0xFF0F4C81);
  static const Color teal       = Color(0xFF0D9488);
  static const Color bg         = Color(0xFFF1F5F9);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE2E8F0);
  static const Color textPrimary    = Color(0xFF0F172A);
  static const Color textSecondary  = Color(0xFF475569);
  static const Color textTertiary   = Color(0xFF94A3B8);
  static const Color success    = Color(0xFF059669);
  static const Color successBg  = Color(0xFFECFDF5);
  static const Color warning    = Color(0xFFD97706);
  static const Color warningBg  = Color(0xFFFFFBEB);
  static const Color info       = Color(0xFF0284C7);
  static const Color infoBg     = Color(0xFFF0F9FF);
  static const Color error      = Color(0xFFDC2626);
}

// ═══════════════════════════════════════════════════════════
//  PASSENGER DETAIL PAGE
// ═══════════════════════════════════════════════════════════
class PassengerDetailPage extends StatelessWidget {
  final BookingModel booking;

  const PassengerDetailPage({super.key, required this.booking});

  String _fmtPrice(int price) => NumberFormat.currency(
        locale: 'id',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);

  // ── Status helpers ──
  Color get _statusColor {
    if (booking.status == BookingStatus.used) return _C.success;
    if (booking.status == BookingStatus.validated) return _C.info;
    if (booking.status == BookingStatus.noShow) return _C.error;
    return _C.warning;
  }

  Color get _statusBg {
    if (booking.status == BookingStatus.used) return _C.successBg;
    if (booking.status == BookingStatus.validated) return _C.infoBg;
    if (booking.status == BookingStatus.noShow) return const Color(0xFFFEE2E2);
    return _C.warningBg;
  }

  IconData get _statusIcon {
    if (booking.status == BookingStatus.used) return Iconsax.tick_circle;
    if (booking.status == BookingStatus.validated) return Iconsax.shield_tick;
    if (booking.status == BookingStatus.noShow) return Iconsax.user_remove;
    return Iconsax.clock;
  }

  String get _statusLabel {
    if (booking.status == BookingStatus.used) return 'Sudah Naik';
    if (booking.status == BookingStatus.validated) return 'Tervalidasi';
    if (booking.status == BookingStatus.noShow) return 'Tidak Datang';
    return 'Belum Check-in';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context, topPad),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Booking Code Card ──
                  _buildBookingCodeCard(),
                  const SizedBox(height: 16),

                  // ── Status Card ──
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // ── Passenger Info Card ──
                  _buildPassengerInfoCard(),
                  const SizedBox(height: 16),

                  // ── Trip Info Card ──
                  _buildTripInfoCard(),
                  const SizedBox(height: 16),

                  // ── Pickup Address Card ──
                  if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty)
                    _buildPickupCard(context),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Bar ──
      bottomNavigationBar: _buildBottomBar(context, bottomPad),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double topPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1565A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22, color: Colors.white),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Penumpang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.origin.isNotEmpty && booking.destination.isNotEmpty
                      ? '${booking.origin} → ${booking.destination}'
                      : booking.fleetName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─────────────────────────────────────────────────────
  //  BOOKING CODE CARD
  // ─────────────────────────────────────────────────────
  Widget _buildBookingCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // QR Icon area
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Iconsax.scan_barcode,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kode Tiket',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: booking.bookingCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kode disalin!',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                          backgroundColor: _C.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      booking.bookingCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap untuk salin',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmtPrice(booking.totalPrice),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.06, delay: 100.ms);
  }

  // ─────────────────────────────────────────────────────
  //  STATUS CARD
  // ─────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, size: 22, color: _statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Tiket',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _C.textTertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (booking.updatedAt != null)
            Text(
              DateFormat('HH:mm').format(booking.updatedAt!),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.06, delay: 150.ms);
  }

  // ─────────────────────────────────────────────────────
  //  PASSENGER INFO CARD
  // ─────────────────────────────────────────────────────
  Widget _buildPassengerInfoCard() {
    final initial = booking.userName.isNotEmpty
        ? booking.userName[0].toUpperCase()
        : '?';

    return _SectionCard(
      title: 'Informasi Penumpang',
      icon: Iconsax.user,
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.people, size: 13, color: _C.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.seatsBooked} kursi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking.seatNumbers.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 14),
            // Seat numbers
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: booking.seatNumbers.map((seat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.ticket, size: 14, color: _C.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Kursi $seat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.06, delay: 200.ms);
  }

  // ─────────────────────────────────────────────────────
  //  TRIP INFO CARD
  // ─────────────────────────────────────────────────────
  Widget _buildTripInfoCard() {
    return _SectionCard(
      title: 'Info Perjalanan',
      icon: Iconsax.routing_2,
      child: Column(
        children: [
          _InfoRow(
            icon: Iconsax.location,
            label: 'Rute',
            value: '${booking.origin} → ${booking.destination}',
            iconColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Iconsax.calendar_1,
            label: 'Tanggal',
            value: booking.departureDate,
            iconColor: _C.warning,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Iconsax.clock,
            label: 'Jam',
            value: booking.departureTime.isNotEmpty ? booking.departureTime : '-',
            iconColor: _C.info,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Iconsax.car,
            label: 'Armada',
            value: booking.fleetName,
            iconColor: _C.primary,
          ),
          if (booking.createdAt != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Iconsax.receipt_item,
              label: 'Dipesan',
              value: DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt!),
              iconColor: _C.teal,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.06, delay: 250.ms);
  }

  // ─────────────────────────────────────────────────────
  //  PICKUP ADDRESS CARD
  // ─────────────────────────────────────────────────────
  Widget _buildPickupCard(BuildContext context) {
    return _SectionCard(
      title: 'Alamat Penjemputan',
      icon: Iconsax.location_tick,
      trailing: GestureDetector(
        onTap: () => _openMaps(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.routing, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'Navigasi',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          if (booking.pickupLatitude != null && booking.pickupLongitude != null) ...[
            GestureDetector(
              onTap: () => _openMaps(context),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      _C.primary.withValues(alpha: 0.08),
                      _C.teal.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _C.border),
                ),
                child: Stack(
                  children: [
                    // Grid lines (map feel)
                    CustomPaint(
                      size: const Size(double.infinity, 130),
                      painter: _MapGridPainter(),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.location,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Tap untuk buka peta',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coordinates badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${booking.pickupLatitude!.toStringAsFixed(4)}, ${booking.pickupLongitude!.toStringAsFixed(4)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: _C.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Address text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.location,
                  size: 15,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  booking.pickupAddress!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _C.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.06, delay: 300.ms);
  }

  // ─────────────────────────────────────────────────────
  //  BOTTOM ACTION BAR
  // ─────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, double bottomPad) {
    final isUsed = booking.status == BookingStatus.used;
    final isNoShow = booking.status == BookingStatus.noShow;
    final isValidated = booking.status == BookingStatus.validated;
    final canMarkDone = !isUsed && !isNoShow;
    final canMarkNoShow = (booking.status == BookingStatus.paid || booking.status == BookingStatus.validated);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty) || canMarkNoShow) ...[
            Row(
              children: [
                // Navigate button (if has pickup)
                if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty)
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(context),
                        icon: const Icon(Iconsax.routing, size: 16),
                        label: Text(
                          'Navigasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          side: const BorderSide(color: _C.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty && canMarkNoShow)
                  const SizedBox(width: 10),
                // No-Show Button
                if (canMarkNoShow)
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsNoShow(context),
                        icon: const Icon(Iconsax.user_remove, size: 16, color: _C.error),
                        label: Text(
                          'No-Show',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.error,
                          side: const BorderSide(color: _C.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Mark as done button (Primary action)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: canMarkDone ? () => _markAsSelesai(context) : null,
              icon: Icon(
                isUsed ? Iconsax.tick_circle : Iconsax.check,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                isUsed
                    ? 'Sudah Dijemput'
                    : isNoShow
                        ? 'Tidak Datang'
                        : isValidated
                            ? 'Tandai Selesai'
                            : 'Konfirmasi Naik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUsed || isNoShow
                    ? const Color(0xFF94A3B8)
                    : _C.success,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                elevation: isUsed || isNoShow ? 0 : 3,
                shadowColor: _C.success.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────────────
  Future<void> _markAsSelesai(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': 'used', 'updatedAt': FieldValue.serverTimestamp()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${booking.userName} selesai dijemput!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: _C.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsNoShow(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tandai No-Show?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda yakin penumpang ini tidak datang (absen)? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: _C.textTertiary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Ya, Absen',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': 'no_show', 'updatedAt': FieldValue.serverTimestamp()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${booking.userName} ditandai sebagai No-Show.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: _C.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: _C.error,
          ),
        );
      }
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final lat = booking.pickupLatitude;
    final lng = booking.pickupLongitude;
    final addr = booking.pickupAddress;

    if ((lat == null || lng == null) && (addr == null || addr.isEmpty)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi tidak tersedia',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: _C.warning,
          ),
        );
      }
      return;
    }

    final Uri url;
    if (lat != null && lng != null) {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr!)}');
    }

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka peta: $e'),
            backgroundColor: _C.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: _C.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
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
                  color: _C.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
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

// ─────────────────────────────────────────────────────
//  MAP GRID PAINTER (decorative)
// ─────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F4C81).withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
