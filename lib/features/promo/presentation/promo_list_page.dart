import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeBg = Color(0xFFFFF7ED);
}

// ═══════════════════════════════════════════════════════════
//  PROMO LIST PAGE — User-facing promo codes listing
//
//  StreamBuilder from Firestore `promo_codes` collection
//  Shows only active, non-expired promos
//  Copy-to-clipboard on tap
// ═══════════════════════════════════════════════════════════
class PromoListPage extends StatelessWidget {
  const PromoListPage({super.key});

  static final _promoRef = FirebaseFirestore.instance.collection('promo_codes');
  static final _currFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Iconsax.discount_shape5,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promo & Diskon',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gunakan kode promo saat checkout',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Promo List with StreamBuilder ──
          // NOTE: Only filter by isActive — no orderBy to avoid
          // composite index requirement. Sort client-side instead.
          StreamBuilder<QuerySnapshot>(
            stream: _promoRef
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              // ── Loading ──
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: SkeletonLoader.grid(itemCount: 4),
                );
              }

              // ── Error ──
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Iconsax.warning_2,
                    title: 'Gagal Memuat',
                    subtitle: 'Periksa koneksi internet Anda',
                  ),
                );
              }

              // ── Filter expired promos client-side & sort by createdAt ──
              final now = DateTime.now();
              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final expiry = data['expiryDate'];
                if (expiry == null) return true;
                final expiryDate = (expiry as Timestamp).toDate();
                return expiryDate.isAfter(now);
              }).toList()
                ..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return (bTime as Timestamp)
                      .compareTo(aTime as Timestamp);
                });

              // ── Empty ──
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Iconsax.ticket_expired,
                    title: 'Belum Ada Promo',
                    subtitle:
                        'Promo akan muncul di sini saat tersedia.\nNantikan penawaran menarik!',
                  ),
                );
              }

              // ── List ──
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _PromoCard(
                      data: data,
                      index: index,
                      currFmt: _currFmt,
                    );
                  },
                ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 32 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PROMO CARD — Visual coupon-style card
// ─────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final NumberFormat currFmt;

  const _PromoCard({
    required this.data,
    required this.index,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final code = data['code'] as String? ?? '-';
    final discountType = data['discountType'] as String? ?? 'percentage';
    final discountValue = (data['discountValue'] as num?)?.toDouble() ?? 0;
    final expiryDate = data['expiryDate'] != null
        ? (data['expiryDate'] as Timestamp).toDate()
        : null;

    // Quota
    final maxUsage = (data['maxUsage'] as num?)?.toInt() ?? 0;
    final usageCount = (data['usageCount'] as num?)?.toInt() ?? 0;
    final isLimited = maxUsage > 0;
    final remaining = isLimited ? maxUsage - usageCount : -1;
    final isExhausted = isLimited && usageCount >= maxUsage;
    final quotaProgress =
        isLimited ? (usageCount / maxUsage).clamp(0.0, 1.0) : 0.0;

    final isPercentage = discountType == 'percentage';
    final discountLabel = isPercentage
        ? '${discountValue.toInt()}%'
        : currFmt.format(discountValue);

    // Days remaining
    final daysLeft = expiryDate != null
        ? expiryDate.difference(DateTime.now()).inDays
        : 999;
    final isExpiringSoon = daysLeft <= 3 && daysLeft >= 0;

    // Card accent colors — gray out if exhausted
    final accentColor =
        isExhausted ? _C.textTertiary : (isPercentage ? _C.teal : _C.orange);
    final accentBg = isExhausted
        ? const Color(0xFFF1F5F9)
        : (isPercentage ? _C.successBg : _C.orangeBg);

    return Opacity(
      opacity: isExhausted ? 0.65 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExhausted
                ? const Color(0xFFE2E8F0)
                : _C.border,
          ),
          boxShadow: isExhausted
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isExhausted ? null : () => _copyCode(context, code),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ── Discount Badge ──
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: accentColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isExhausted
                                ? Icon(Iconsax.ticket_expired,
                                    color: accentColor, size: 22)
                                : Icon(
                                    isPercentage
                                        ? Iconsax.percentage_circle
                                        : Iconsax.money_recive,
                                    color: accentColor,
                                    size: 22,
                                  ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  isExhausted
                                      ? 'HABIS'
                                      : (isPercentage ? discountLabel : 'OFF'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isPercentage ? 18 : 12,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ── Details ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Discount description
                            Text(
                              isPercentage
                                  ? 'Diskon $discountLabel'
                                  : 'Potongan ${currFmt.format(discountValue)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isExhausted
                                    ? _C.textTertiary
                                    : _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Code badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _C.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _C.primary.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.copy,
                                      size: 12, color: _C.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      code,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.primary,
                                        letterSpacing: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Expiry row
                            Row(
                              children: [
                                Icon(
                                  isExpiringSoon
                                      ? Iconsax.timer_1
                                      : Iconsax.calendar_1,
                                  size: 12,
                                  color: isExpiringSoon
                                      ? _C.warning
                                      : _C.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    expiryDate != null
                                        ? isExpiringSoon
                                            ? 'Berakhir $daysLeft hari lagi!'
                                            : 'Berlaku s.d ${DateFormat('dd MMM yyyy', 'id').format(expiryDate)}'
                                        : 'Tanpa batas waktu',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isExpiringSoon
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isExpiringSoon
                                          ? _C.warning
                                          : _C.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Copy / Exhausted indicator ──
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isExhausted
                              ? const Color(0xFFFEF2F2)
                              : _C.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isExhausted
                              ? Iconsax.close_circle
                              : Iconsax.copy,
                          size: 16,
                          color: isExhausted
                              ? const Color(0xFFDC2626)
                              : _C.textTertiary,
                        ),
                      ),
                    ],
                  ),

                  // ── Quota progress bar (only if limited) ──
                  if (isLimited) ...[
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isExhausted
                                  ? '🚫 Kupon sudah habis'
                                  : '🎟 Sisa $remaining kupon tersedia',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isExhausted
                                    ? const Color(0xFFDC2626)
                                    : _C.textTertiary,
                              ),
                            ),
                            Text(
                              '$usageCount/$maxUsage digunakan',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quotaProgress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isExhausted
                                  ? const Color(0xFFDC2626)
                                  : quotaProgress > 0.8
                                      ? _C.warning
                                      : _C.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index), duration: 350.ms)
        .slideX(begin: 0.04, delay: Duration(milliseconds: 80 * index));
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kode "$code" disalin! Pakai saat checkout.',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.borderLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _C.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _C.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}
