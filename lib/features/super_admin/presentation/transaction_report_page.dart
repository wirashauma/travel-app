import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
}

// ═══════════════════════════════════════════════════════════
//  TRANSACTION REPORT PAGE — Real-time bookings stream
// ═══════════════════════════════════════════════════════════
class TransactionReportPage extends StatefulWidget {
  const TransactionReportPage({super.key});

  @override
  State<TransactionReportPage> createState() =>
      _TransactionReportPageState();
}

class _TransactionReportPageState extends State<TransactionReportPage> {
  String _selectedFilter = 'all';

  static final _bookingsRef = FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true);

  static final _currencyFmt = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          'Laporan Transaksi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Filter Chips ──
          _buildFilterChips(),

          // ── Booking List ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _bookingsRef.snapshots(),
              builder: (context, snapshot) {
                // ── Loading ──
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SkeletonLoader.list();
                }

                // ── Error ──
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: Iconsax.warning_2,
                    title: 'Terjadi Kesalahan',
                    subtitle: '${snapshot.error}',
                    color: _C.error,
                  );
                }

                // ── Empty ──
                final allDocs = snapshot.data?.docs ?? [];
                if (allDocs.isEmpty) {
                  return const _EmptyState(
                    icon: Iconsax.receipt_item,
                    title: 'Belum Ada Transaksi',
                    subtitle:
                        'Data booking akan muncul di sini secara real-time.',
                    color: _C.primary,
                  );
                }

                // ── Apply status filter ──
                final docs = _selectedFilter == 'all'
                    ? allDocs
                    : allDocs.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final s = (d['status'] as String? ?? 'pending')
                            .toLowerCase();
                        return s == _selectedFilter;
                      }).toList();

                if (docs.isEmpty) {
                  return _EmptyState(
                    icon: Iconsax.filter,
                    title: 'Tidak Ada Transaksi',
                    subtitle:
                        'Tidak ada transaksi dengan status ini.',
                    color: _C.primary,
                  );
                }

                // ── Summary Header + List ──
                return Column(
                  children: [
                    _buildSummaryBar(allDocs),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return _TransactionCard(
                            docId: doc.id,
                            data: data,
                            index: i,
                            currencyFmt: _currencyFmt,
                            dateFmt: _dateFmt,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  FILTER CHIPS ROW
  // ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const filters = [
      {'key': 'all', 'label': 'Semua'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'paid', 'label': 'Paid'},
      {'key': 'completed', 'label': 'Selesai'},
      {'key': 'cancelled', 'label': 'Batal'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: _C.bg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final key = f['key']!;
            final isSelected = _selectedFilter == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(f['label']!),
                onSelected: (_) =>
                    setState(() => _selectedFilter = key),
                selectedColor:
                    _C.primary.withValues(alpha: 0.12),
                checkmarkColor: _C.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? _C.primary
                      : _C.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        isSelected ? _C.primary : _C.border,
                  ),
                ),
                backgroundColor: _C.card,
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSummaryBar(List<QueryDocumentSnapshot> docs) {
    int totalRevenue = 0;
    int paidCount = 0;
    int pendingCount = 0;
    int completedCount = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String? ?? '').toLowerCase();
      final price = (data['totalPrice'] as num?)?.toInt() ?? 0;
      totalRevenue += price;
      if (status == 'paid') paidCount++;
      if (status == 'pending') pendingCount++;
      if (status == 'completed') completedCount++;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFmt.format(totalRevenue),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryChip(
                  label: '${docs.length} Total', color: Colors.white),
              const SizedBox(width: 8),
              _SummaryChip(
                  label: '$paidCount Paid',
                  color: const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _SummaryChip(
                  label: '$pendingCount Pending',
                  color: const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _SummaryChip(
                  label: '$completedCount Done',
                  color: const Color(0xFF60A5FA)),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.03, duration: 400.ms);
  }
}

// ── Summary chip ──────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TRANSACTION CARD
// ═══════════════════════════════════════════════════════════
class _TransactionCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final int index;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _TransactionCard({
    required this.docId,
    required this.data,
    required this.index,
    required this.currencyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final userName = data['userName'] as String? ?? 'Unknown User';
    final origin =
        data['origin'] as String? ?? data['from'] as String? ?? '-';
    final destination =
        data['destination'] as String? ?? data['to'] as String? ?? '-';
    final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
    final status = (data['status'] as String? ?? 'pending').toLowerCase();
    final seats = (data['seatsBooked'] as num?)?.toInt() ??
        data['seats'] as int? ??
        1;

    String dateStr = '-';
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      dateStr = dateFmt.format(createdAt.toDate());
    }

    final departDate = data['departureDate'] as String? ?? '';

    final shortId = docId.length > 8
        ? docId.substring(0, 8).toUpperCase()
        : docId.toUpperCase();

    final statusStyle = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Booking ID + Status badge ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.receipt_item,
                          size: 16, color: _C.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        '#$shortId',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusStyle.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusStyle.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusStyle.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── User name ──
              Row(
                children: [
                  const Icon(Iconsax.user, size: 15, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Route ──
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _C.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$origin  \u2192  $destination',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _C.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Info row: date, seats, price ──
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Iconsax.calendar_1,
                      label: departDate.isNotEmpty ? departDate : dateStr,
                      color: _C.info,
                    ),
                  ),
                  _InfoItem(
                    icon: Iconsax.people,
                    label: '$seats kursi',
                    color: _C.teal,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currencyFmt.format(totalPrice),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (80 + index * 50).ms, duration: 350.ms)
        .slideY(
            begin: 0.04, delay: (80 + index * 50).ms, duration: 350.ms);
  }

  _StatusStyle _getStatusStyle(String status) {
    switch (status) {
      case 'paid':
        return const _StatusStyle(
          label: 'Paid',
          color: _C.success,
          bgColor: _C.successBg,
        );
      case 'used':
        return const _StatusStyle(
          label: 'Validated',
          color: _C.info,
          bgColor: _C.infoBg,
        );
      case 'completed':
        return const _StatusStyle(
          label: 'Completed',
          color: _C.info,
          bgColor: _C.infoBg,
        );
      case 'cancelled':
        return const _StatusStyle(
          label: 'Cancelled',
          color: _C.error,
          bgColor: _C.errorBg,
        );
      default:
        return const _StatusStyle(
          label: 'Pending',
          color: _C.warning,
          bgColor: _C.warningBg,
        );
    }
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color bgColor;
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

// ── Info item ─────────────────────────────────────────────
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _C.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13, color: _C.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
