import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../e_ticket/presentation/live_e_ticket_page.dart';
import '../../payment/presentation/payment_page.dart';
import 'cancel_booking_page.dart';
import 'reschedule_page.dart';

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
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

}

// ─────────────────────────────────────────────────────────
//  CANCEL BOOKING — Navigate to full CancelBookingPage
// ─────────────────────────────────────────────────────────
Future<void> _confirmCancelBooking(
    BuildContext context, BookingModel booking) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CancelBookingPage(booking: booking),
    ),
  );

  if (result != true || !context.mounted) return;

  // Success — refresh is handled by StreamBuilder parent
}

// ═══════════════════════════════════════════════════════════
//  BOOKING HISTORY PAGE — Traveloka-style order history
//
//  StreamBuilder on bookings where userId == currentUser.uid
//  Sorted by createdAt descending (recent first)
//  Status-colored badges: pending → orange, paid → green,
//                         completed → teal, cancelled → red
// ═══════════════════════════════════════════════════════════
enum _FilterOption { all, pending, paid, completed, cancelled }

class BookingHistoryPage extends StatefulWidget {
  final bool showHeader;
  const BookingHistoryPage({super.key, this.showHeader = true});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  _FilterOption _selectedFilter = _FilterOption.all;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPadding = MediaQuery.of(context).padding.top;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Text(
            'Anda belum login',
            style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ═══ APP BAR ═══
          if (widget.showHeader) _AppBar(topPadding: topPadding),

          // ═══ FILTER CHIPS ═══
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),

          // ═══ BOOKING LIST ═══
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: BookingService.userBookingsStream(user.uid),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ShimmerList();
                }

                // Error
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error.toString());
                }

                // Empty
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return const _EmptyState();
                }

                // Filter
                final filtered = _filterBookings(bookings);

                if (filtered.isEmpty) {
                  return _EmptyFilterState();
                }

                // List
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    
                    // Background self-healing GC: cancel if expired in database
                    final isExpired = booking.status == BookingStatus.pending &&
                        booking.expiryDate != null &&
                        booking.expiryDate!.isBefore(DateTime.now());
                    if (isExpired) {
                      BookingService.cancelBooking(booking.id!);
                    }

                    return _BookingCard(
                      booking: booking,
                      onTap: () {
                        if (booking.status == BookingStatus.paid ||
                            booking.status == BookingStatus.validated ||
                            booking.status == BookingStatus.used ||
                            booking.status == BookingStatus.completed) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LiveETicketPage(bookingId: booking.id!),
                            ),
                          );
                        }
                      },
                      onCancel: (booking.status == BookingStatus.pending ||
                              booking.status == BookingStatus.paid)
                          ? () => _confirmCancelBooking(context, booking)
                          : null,
                    )
                        .animate()
                        .fadeIn(
                          delay: (100 + index * 60).ms,
                          duration: 400.ms,
                        )
                        .slideY(
                          begin: 0.04,
                          delay: (100 + index * 60).ms,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    if (_selectedFilter == _FilterOption.all) return bookings;

    return bookings.where((b) {
      switch (_selectedFilter) {
        case _FilterOption.pending:
          return b.status == BookingStatus.pending;
        case _FilterOption.paid:
          return b.status == BookingStatus.paid;
        case _FilterOption.completed:
          return b.status == BookingStatus.completed ||
              b.status == BookingStatus.validated ||
              b.status == BookingStatus.used;
        case _FilterOption.cancelled:
          return b.status == BookingStatus.cancelled;
        default:
          return true;
      }
    }).toList();
  }
}

// ─────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final double topPadding;
  const _AppBar({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 16),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(
          bottom: BorderSide(color: _C.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Riwayat Pemesanan',
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
              color: _C.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.document_text, size: 13, color: _C.primary),
                const SizedBox(width: 4),
                Text(
                  'Pesanan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────
//  BOOKING CARD — Traveloka-style order card
// ─────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return _C.warning;
      case BookingStatus.paid:
        return _C.success;
      case BookingStatus.validated:
        return _C.teal;
      case BookingStatus.used:
        return _C.teal;
      case BookingStatus.completed:
        return _C.teal;
      case BookingStatus.cancelled:
        return _C.danger;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Menunggu Bayar';
      case BookingStatus.paid:
        return 'Sudah Bayar';
      case BookingStatus.validated:
        return 'Tervalidasi';
      case BookingStatus.used:
        return 'Tervalidasi';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  IconData _statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Iconsax.clock;
      case BookingStatus.paid:
        return Iconsax.tick_circle;
      case BookingStatus.validated:
        return Iconsax.shield_tick;
      case BookingStatus.used:
        return Iconsax.verify;
      case BookingStatus.completed:
        return Iconsax.verify;
      case BookingStatus.cancelled:
        return Iconsax.close_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = booking.status == BookingStatus.pending &&
        booking.expiryDate != null &&
        booking.expiryDate!.isBefore(DateTime.now());

    final displayStatus = isExpired ? BookingStatus.cancelled : booking.status;
    final sColor = _statusColor(displayStatus);
    final isClickable = !isExpired && (booking.status == BookingStatus.paid ||
        booking.status == BookingStatus.validated ||
        booking.status == BookingStatus.used ||
        booking.status == BookingStatus.completed);

    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.borderLight),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header: Code + Status Badge ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.03),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.receipt_1, size: 14, color: _C.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.bookingCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(displayStatus),
                            size: 12, color: sColor),
                        const SizedBox(width: 4),
                        Text(
                          isExpired ? 'Kedaluwarsa' : _statusLabel(booking.status),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  // Route
                  Row(
                    children: [
                      _dot(_C.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.origin,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Iconsax.arrow_right_3,
                            size: 14, color: _C.textTertiary),
                      ),
                      Expanded(
                        child: Text(
                          booking.destination,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _dot(_C.danger),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Container(height: 1, color: _C.borderLight),
                  const SizedBox(height: 12),

                  // Meta row
                  Row(
                    children: [
                      Expanded(
                        child: _metaItem(
                          Iconsax.car,
                          booking.fleetName,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metaItem(
                          Iconsax.calendar_1,
                          '${booking.departureDate} (${booking.departureTime})',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _metaItem(
                        Iconsax.people,
                        '${booking.seatsBooked} pax',
                      ),
                    ],
                  ),

                  if (booking.selectedSeatLabels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Iconsax.driver,
                          size: 14,
                          color: _C.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kursi: ${booking.selectedSeatLabels.join(", ")}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Price + Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmtPrice(booking.totalPrice),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                        ),
                      ),
                      if (isClickable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _C.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat E-Tiket',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Iconsax.arrow_right_3,
                                  size: 12, color: _C.primary),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // ── Action Buttons ──
                  if (booking.status == BookingStatus.pending && !isExpired) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _C.borderLight),
                    const SizedBox(height: 12),
                    // Continue Payment
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentPage(
                                bookingId: booking.id!,
                                bookingCode: booking.bookingCode,
                                totalAmount: booking.totalPrice,
                                origin: booking.origin,
                                destination: booking.destination,
                                fleetName: booking.fleetName,
                                passengers: booking.seatsBooked,
                                departureDate: booking.departureDate,
                                departureTime: booking.departureTime,
                                expiryDate: booking.expiryDate ?? DateTime.now().add(const Duration(minutes: 15)),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Iconsax.wallet_3, size: 18),
                        label: Text(
                          'Lanjutkan Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: _C.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Cancel (full-width outlined button)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Iconsax.close_circle, size: 18),
                        label: Text(
                          'Batalkan Pesanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.danger,
                          side: BorderSide(
                            color: _C.danger.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (booking.status == BookingStatus.paid) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _C.borderLight),
                    const SizedBox(height: 12),
                    // Reschedule
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReschedulePage(booking: booking),
                            ),
                          );
                        },
                        icon: const Icon(Iconsax.calendar_edit, size: 18),
                        label: Text(
                          'Reschedule',
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Batalkan Pesanan (Post-Payment)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Iconsax.close_circle, size: 18),
                        label: Text(
                          'Batalkan Pesanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.danger,
                          side: BorderSide(
                            color: _C.danger.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _C.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _C.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
//  FILTER BAR — Horizontal scrollable filter chips
// ─────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _FilterOption selected;
  final ValueChanged<_FilterOption> onChanged;

  const _FilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (_FilterOption.all, 'Semua'),
      (_FilterOption.pending, 'Menunggu Bayar'),
      (_FilterOption.paid, 'Sudah Bayar'),
      (_FilterOption.completed, 'Selesai'),
      (_FilterOption.cancelled, 'Dibatalkan'),
    ];

    return Container(
      color: _C.white,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = filters[index];
                final isSelected = selected == option.$1;
                return GestureDetector(
                  onTap: () => onChanged(option.$1),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _C.primary
                          : _C.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _C.primary
                            : _C.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      option.$2,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _C.white : _C.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: _C.borderLight),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────
//  EMPTY STATE (after filter)
// ─────────────────────────────────────────────────
class _EmptyFilterState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.textTertiary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Iconsax.search_normal_1,
              size: 36,
              color: _C.textTertiary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ditemukan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada pesanan dengan\nstatus yang dipilih.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────
//  EMPTY STATE (no bookings at all)
// ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.textTertiary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Iconsax.document_text,
              size: 36,
              color: _C.textTertiary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Pesanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan Anda akan muncul di sini\nsetelah melakukan pemesanan.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: _C.danger),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Riwayat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  SHIMMER LOADING
// ─────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderLight),
          ),
          child: Column(
            children: [
              // Header shimmer
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _C.borderLight.withValues(alpha: 0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBar(width: 200, height: 14),
                      const SizedBox(height: 12),
                      _shimmerBar(width: 150, height: 10),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBar(width: 100, height: 16),
                          _shimmerBar(width: 80, height: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(),
            )
            .shimmer(
              delay: (index * 120).ms,
              duration: 1200.ms,
              color: _C.borderLight,
            );
      },
    );
  }

  static Widget _shimmerBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _C.borderLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
