import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../payment/presentation/payment_page.dart';

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
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
}

class ReschedulePage extends StatefulWidget {
  final BookingModel booking;

  const ReschedulePage({super.key, required this.booking});

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isProcessing = false;

  static const _timeSlots = ['08:00 WIB', '10:00 WIB', '13:00 WIB', '16:00 WIB'];

  String get _formattedSelectedDate {
    if (_selectedDate == null) return '';
    final f = DateFormat('dd MMM yyyy', 'id_ID');
    return f.format(_selectedDate!);
  }

  bool get _canConfirm => _selectedDate != null && _selectedTime != null && !_isProcessing;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _C.primary,
              onPrimary: Colors.white,
              surface: _C.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmReschedule() async {
    if (!_canConfirm) return;
    setState(() => _isProcessing = true);

    try {
      final formattedDate = _formattedSelectedDate;
      final formattedTime = _selectedTime!.replaceAll(' WIB', '');

      // Untuk booking paid: bayar admin fee dulu, baru apply reschedule
      if (widget.booking.status == BookingStatus.paid) {
        final adminFee = (widget.booking.totalPrice * 0.1).round();
        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              bookingId: widget.booking.id!,
              bookingCode: widget.booking.bookingCode,
              totalAmount: adminFee,
              origin: widget.booking.origin,
              destination: widget.booking.destination,
              fleetName: widget.booking.fleetName,
              passengers: widget.booking.seatsBooked,
              departureDate: formattedDate,
              expiryDate: DateTime.now().add(const Duration(hours: 1)),
              customMidtransOrderId: '${widget.booking.id}-admin',
            ),
          ),
        );

        if (!mounted) return;
        // Cek apakah admin fee berhasil dibayar
        final snap = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.booking.id!)
            .get();
        final hasAdminFeePaid = snap.data()?['adminFeePaidAt'] != null;
        if (!hasAdminFeePaid) {
          // Payment gagal/dibatalkan/expired — tetap di halaman agar bisa coba lagi
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pembayaran dibatalkan. Silakan coba lagi.',
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
          return;
        }

        // Payment sukses — sekarang apply reschedule
        await BookingService.rescheduleBooking(
          widget.booking.id!,
          formattedDate,
          formattedTime,
        );

        if (!mounted) return;
      } else {
        // Pending booking: langsung reschedule
        await BookingService.rescheduleBooking(
          widget.booking.id!,
          formattedDate,
          formattedTime,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jadwal berhasil diubah ke $formattedDate $formattedTime WIB',
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
                  'Gagal: ${e.toString().replaceFirst('Exception: ', '')}',
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTicketCard(),
                    const SizedBox(height: 28),
                    _buildOldSchedule(),
                    const SizedBox(height: 28),
                    _buildNewSchedule(),
                    const SizedBox(height: 20),
                    _buildFeeNote(),
                    const SizedBox(height: 24),
                  ],
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
            'Reschedule',
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

  Widget _buildTicketCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _C.textTertiary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _C.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CONFIRMED',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'BOOKING ID',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _C.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.bookingCode,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Route visualization
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.origin.substring(0, 3).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            widget.booking.origin,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _C.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(width: 24, height: 1, color: _C.textPrimary),
                          const SizedBox(width: 4),
                          Icon(Iconsax.car, size: 20, color: _C.textPrimary),
                          const SizedBox(width: 4),
                          Container(width: 24, height: 1, color: _C.textPrimary),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.booking.destination.substring(0, 3).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            widget.booking.destination,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _C.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _C.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.departureDate.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'SEAT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _C.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.selectedSeatLabels.isNotEmpty
                              ? widget.booking.selectedSeatLabels.join(', ')
                              : '${widget.booking.seatsBooked} Kursi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          // Dashed separator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _DashedLinePainter(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.03, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildOldSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JADWAL LAMA',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.calendar_1, size: 20, color: _C.primary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.departureDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keberangkatan sebelumnya',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _C.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.03, duration: 400.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildNewSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILIH JADWAL BARU',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Pilih Tanggal',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _C.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDate != null ? _C.primary : _C.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? _formattedSelectedDate
                      : 'Pilih tanggal keberangkatan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: _selectedDate != null ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedDate != null ? _C.textPrimary : _C.textTertiary,
                  ),
                ),
                const Icon(Iconsax.calendar_1, size: 18, color: _C.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pilih Jam',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _C.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final time = _timeSlots[index];
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? _C.primary : _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _C.primary : _C.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _C.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(Iconsax.tick_circle, size: 16, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          },
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildFeeNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.info_circle, size: 16, color: _C.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Administrasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perubahan jadwal akan dikenakan biaya administrasi sebesar 10% dari harga tiket.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _C.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildBottomActions(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border(
          top: BorderSide(color: _C.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.textPrimary,
                  side: BorderSide(color: _C.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'BATAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _canConfirm ? _confirmReschedule : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.tick_circle, size: 18),
                label: Text(
                  _isProcessing ? 'MEMPROSES...' : 'KONFIRMASI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canConfirm ? _C.primary : _C.textTertiary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.08, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
