// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
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
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
}

// ═══════════════════════════════════════════════════════════
//  MANAGE DRIVER ASSIGNMENTS PAGE — Super Admin
//
//  Halaman khusus untuk menugaskan/mengganti Sopir pada
//  masing-masing Armada. Dipisahkan dari Manajemen Armada
//  sesuai Clean Architecture (SDM ≠ Entitas).
//
//  Flow:
//  1. StreamBuilder pada `fleets` → daftar semua armada
//  2. Tiap card menunjukkan status penugasan sopir
//  3. Tombol "Tugaskan/Ganti" → ModalBottomSheet
//  4. BottomSheet StreamBuilder `users` role=admin → pilih sopir
//  5. Update langsung `fleets/{id}` driverId + driverName
//  6. Dashboard Sopir (nested StreamBuilder) berubah real-time
// ═══════════════════════════════════════════════════════════
class ManageDriverAssignmentsPage extends StatelessWidget {
  const ManageDriverAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──
          SliverToBoxAdapter(child: _buildHeader(context)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── FLEET LIST — Real-time ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fleets')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _C.primary),
                  ),
                );
              }

              // Error
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    icon: Iconsax.warning_2,
                    title: 'Gagal Memuat',
                    subtitle: 'Periksa koneksi internet Anda',
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // Empty
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    icon: Iconsax.bus,
                    title: 'Belum Ada Armada',
                    subtitle:
                        'Tambahkan armada terlebih dahulu\ndi menu Manajemen Armada',
                  ),
                );
              }

              // Fleet cards
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _FleetAssignmentCard(
                      fleetId: doc.id,
                      data: data,
                      index: index,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C81), Color(0xFF1A6BB5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Iconsax.arrow_left,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Penugasan Supir',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.user_tag,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kelola penugasan sopir untuk setiap armada.\n'
                        'Perubahan langsung tersinkronisasi ke HP sopir.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─────────────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────────────
  static Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ═══════════════════════════════════════════════════════════
//  FLEET ASSIGNMENT CARD — Shows fleet + driver status
// ═══════════════════════════════════════════════════════════
class _FleetAssignmentCard extends StatelessWidget {
  final String fleetId;
  final Map<String, dynamic> data;
  final int index;

  const _FleetAssignmentCard({
    required this.fleetId,
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Armada';
    final description = data['description'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
    final availableSeats = (data['availableSeats'] as num?)?.toInt() ?? 0;
    final driverId = data['driverId'] as String? ?? '';
    final driverName = data['driverName'] as String? ?? '';
    final hasDriver = driverId.isNotEmpty;

    return Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Image + fleet info ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fleet image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildImageFallback(),
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return _buildImageFallback(loading: true);
                                },
                              )
                            : _buildImageFallback(),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Fleet info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _C.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Seat info
                          Row(
                            children: [
                              _InfoTag(
                                icon: Iconsax.people,
                                label: '$availableSeats/$totalSeats kursi',
                                color: _C.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              Container(height: 1, color: _C.borderLight),

              // ── Driver status + action ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Status badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasDriver ? _C.successBg : _C.errorBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasDriver
                                ? _C.success.withValues(alpha: 0.2)
                                : _C.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasDriver
                                  ? Iconsax.user_tick
                                  : Iconsax.user_remove,
                              size: 16,
                              color: hasDriver ? _C.success : _C.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasDriver
                                        ? 'Supir Aktif'
                                        : 'Belum Ada Supir',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: hasDriver ? _C.success : _C.error,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (hasDriver) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      driverName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Action button
                    Material(
                      color: hasDriver
                          ? _C.primary.withValues(alpha: 0.08)
                          : _C.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showDriverPicker(
                          context,
                          fleetId: fleetId,
                          fleetName: name,
                          currentDriverId: driverId,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasDriver ? Iconsax.refresh : Iconsax.user_add,
                                size: 16,
                                color: hasDriver ? _C.primary : _C.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasDriver ? 'Ganti' : 'Tugaskan',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: hasDriver ? _C.primary : _C.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: 350.ms,
        )
        .slideY(
          begin: 0.05,
          delay: Duration(milliseconds: 60 * index),
          duration: 350.ms,
        );
  }

  Widget _buildImageFallback({bool loading = false}) {
    return Container(
      color: _C.borderLight,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.textTertiary,
                ),
              )
            : Icon(
                Iconsax.bus,
                size: 28,
                color: _C.textTertiary.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  DRIVER PICKER — Modal Bottom Sheet (Null-Safe)
  // ─────────────────────────────────────────────────────
  static void _showDriverPicker(
    BuildContext context, {
    required String fleetId,
    required String fleetName,
    required String currentDriverId,
  }) {
    // Simpan reference ke parent context untuk SnackBar
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.user_tag,
                        size: 20,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Supir',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Untuk armada: $fleetName',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _C.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Container(height: 1, color: _C.borderLight),

              // ── "Hapus Penugasan" option (if currently assigned) ──
              if (currentDriverId.isNotEmpty)
                _RemoveAssignmentTile(
                  fleetId: fleetId,
                  parentContext: parentContext,
                ),

              // ── Driver list — Real-time StreamBuilder (tanpa orderBy) ──
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'admin')
                      .snapshots(),
                  builder: (ctx, snapshot) {
                    // ── 1. Loading ──
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: _C.primary),
                        ),
                      );
                    }

                    // ── 2. Error — print ke console + UI ──
                    if (snapshot.hasError) {
                      debugPrint(
                        '[ManageDriverAssignments] StreamBuilder error: ${snapshot.error}',
                      );
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _C.errorBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.warning_2,
                                size: 28,
                                color: _C.error,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Terjadi kesalahan sistem',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Silakan coba lagi nanti',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ── Ambil docs (null-safe) + client-side sort ──
                    final drivers = (snapshot.data?.docs ?? [])
                      ..sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>? ?? {};
                        final dataB = b.data() as Map<String, dynamic>? ?? {};
                        final nameA =
                            (dataA['name'] as String? ??
                                    dataA['namaLengkap'] as String? ??
                                    dataA['fullName'] as String? ??
                                    'zzz')
                                .toLowerCase();
                        final nameB =
                            (dataB['name'] as String? ??
                                    dataB['namaLengkap'] as String? ??
                                    dataB['fullName'] as String? ??
                                    'zzz')
                                .toLowerCase();
                        return nameA.compareTo(nameB);
                      });

                    // ── 3. Empty ──
                    if (drivers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _C.warningBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.people,
                                size: 28,
                                color: _C.warning,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum Ada Akun Supir',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Belum ada akun supir yang terdaftar.\n'
                              'Silakan ubah role user menjadi admin\n'
                              'terlebih dahulu.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _C.textTertiary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // ── 4. Driver list — ListView.builder + ListTile ──
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: drivers.length,
                      itemBuilder: (ctx, i) {
                        final driverDoc = drivers[i];
                        final data =
                            driverDoc.data() as Map<String, dynamic>? ?? {};

                        // Null-safe field access dengan multiple fallback
                        final String driverName =
                            data['name'] as String? ??
                            data['namaLengkap'] as String? ??
                            data['fullName'] as String? ??
                            'Supir Tanpa Nama';
                        final String driverEmail =
                            data['email'] as String? ?? 'Tidak ada email';
                        final String driverUid = driverDoc.id;
                        final bool isCurrentDriver =
                            driverUid == currentDriverId;

                        // Inisial untuk CircleAvatar
                        final String initials = driverName.isNotEmpty
                            ? driverName[0].toUpperCase()
                            : '?';

                        return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Material(
                                color: isCurrentDriver
                                    ? _C.primary.withValues(alpha: 0.06)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isCurrentDriver
                                        ? _C.success.withValues(alpha: 0.12)
                                        : _C.primary.withValues(alpha: 0.08),
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrentDriver
                                            ? _C.success
                                            : _C.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    driverName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    driverEmail,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _C.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isCurrentDriver
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _C.successBg,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _C.success.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Iconsax.tick_circle,
                                                size: 12,
                                                color: _C.success,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Aktif',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: _C.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Icon(
                                          Iconsax.arrow_right_3,
                                          size: 16,
                                          color: _C.textHint,
                                        ),
                                  onTap: isCurrentDriver
                                      ? null
                                      : () async {
                                          // ── Loading dialog ──
                                          showDialog(
                                            context: ctx,
                                            barrierDismissible: false,
                                            builder: (_) => Center(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _C.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: const SizedBox(
                                                  width: 32,
                                                  height: 32,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        color: _C.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          );

                                          try {
                                            // ── Update Firestore ──
                                            await FirebaseFirestore.instance
                                                .collection('fleets')
                                                .doc(fleetId)
                                                .update({
                                                  'driverId': driverUid,
                                                  'driverName': driverName,
                                                  'updatedAt':
                                                      FieldValue.serverTimestamp(),
                                                });

                                            // Tutup loading dialog
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }
                                            // Tutup bottom sheet
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }

                                            // SnackBar hijau
                                            if (parentContext.mounted) {
                                              ScaffoldMessenger.of(
                                                  parentContext,
                                                )
                                                ..clearSnackBars()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        const Icon(
                                                          Iconsax.tick_circle,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Supir $driverName berhasil ditugaskan!',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: _C.success,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                            }
                                          } catch (e) {
                                            // Tutup loading dialog
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }
                                            // SnackBar error
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
                                                ..clearSnackBars()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gagal menugaskan: $e',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor: _C.error,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                  ),
                                                );
                                            }
                                          }
                                        },
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 40 * i),
                              duration: 250.ms,
                            )
                            .slideX(
                              begin: 0.03,
                              delay: Duration(milliseconds: 40 * i),
                              duration: 250.ms,
                            );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  REMOVE ASSIGNMENT TILE — Unassign driver from fleet
// ═══════════════════════════════════════════════════════════
class _RemoveAssignmentTile extends StatefulWidget {
  final String fleetId;
  final BuildContext parentContext;

  const _RemoveAssignmentTile({
    required this.fleetId,
    required this.parentContext,
  });

  @override
  State<_RemoveAssignmentTile> createState() => _RemoveAssignmentTileState();
}

class _RemoveAssignmentTileState extends State<_RemoveAssignmentTile> {
  bool _isRemoving = false;

  Future<void> _removeAssignment() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);

    try {
      await FirebaseFirestore.instance
          .collection('fleets')
          .doc(widget.fleetId)
          .update({
            'driverId': '',
            'driverName': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context);

      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Penugasan supir berhasil dihapus',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: _C.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _removeAssignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isRemoving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _C.error,
                        ),
                      )
                    : const Icon(
                        Iconsax.user_remove,
                        size: 18,
                        color: _C.error,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus Penugasan Supir',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.error,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: _C.error.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info Tag helper ──
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
