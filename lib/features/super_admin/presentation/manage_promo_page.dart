// ignore_for_file: unused_field, deprecated_member_use, unnecessary_non_null_assertion

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / Enterprise / No Purple
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
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
}

// ═══════════════════════════════════════════════════════════
//  MANAGE PROMO PAGE — CRUD promo_codes collection
//
//  Firestore `promo_codes/{docId}`:
//    code          : String   (UPPERCASE, unique)
//    discountType  : String   ('percentage' | 'fixed')
//    discountValue : num
//    expiryDate    : Timestamp
//    isActive      : bool
//    createdAt     : Timestamp
// ═══════════════════════════════════════════════════════════
class ManagePromoPage extends StatefulWidget {
  const ManagePromoPage({super.key});

  @override
  State<ManagePromoPage> createState() => _ManagePromoPageState();
}

class _ManagePromoPageState extends State<ManagePromoPage> {
  static final _db = FirebaseFirestore.instance;
  static final _promoRef = _db.collection('promo_codes');

  String _search = '';

  // ── Stream ──
  Stream<QuerySnapshot<Map<String, dynamic>>> get _promoStream =>
      _promoRef.orderBy('createdAt', descending: true).snapshots();

  // ── Helpers ──
  String _fmtCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _fmtDate(Timestamp ts) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(ts.toDate());
  }

  bool _isExpired(Timestamp ts) => ts.toDate().isBefore(DateTime.now());

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
          backgroundColor: isError ? _C.error : _C.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ── Toggle Active ──
  Future<void> _toggleActive(String docId, bool currentValue) async {
    try {
      await _promoRef.doc(docId).update({'isActive': !currentValue});
      _showSnack(currentValue ? 'Kupon dinonaktifkan' : 'Kupon diaktifkan');
    } catch (e) {
      _showSnack('Gagal mengubah status: $e', isError: true);
    }
  }

  // ── Delete ──
  Future<void> _confirmDelete(String docId, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Kupon',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus kupon "$code"?\nTindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 14, color: _C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.textTertiary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: _C.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _promoRef.doc(docId).delete();
        if (mounted) _showSnack('Kupon "$code" berhasil dihapus');
      } catch (e) {
        if (mounted) _showSnack('Gagal menghapus: $e', isError: true);
      }
    }
  }

  // ── Show Add / Edit Bottom Sheet ──
  void _showPromoSheet({DocumentSnapshot<Map<String, dynamic>>? doc}) {
    final isEdit = doc != null;
    final data = doc?.data();

    final codeCtrl = TextEditingController(text: data?['code'] ?? '');
    final valueCtrl = TextEditingController(
      text: data?['discountValue']?.toString() ?? '',
    );
    String discountType = data?['discountType'] ?? 'percentage';
    DateTime expiryDate = data != null && data['expiryDate'] != null
        ? (data['expiryDate'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 30));
    bool isActive = data?['isActive'] ?? true;
    bool isSaving = false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: expiryDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: _C.primary,
                    onSurface: _C.textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setSheetState(() => expiryDate = picked);
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);

            final code = codeCtrl.text.trim().toUpperCase();
            final value = num.tryParse(valueCtrl.text.trim()) ?? 0;

            // Validate percentage range
            if (discountType == 'percentage' && (value <= 0 || value > 100)) {
              _showSnack('Persentase harus antara 1–100', isError: true);
              setSheetState(() => isSaving = false);
              return;
            }
            if (discountType == 'fixed' && value <= 0) {
              _showSnack('Nilai diskon harus lebih dari 0', isError: true);
              setSheetState(() => isSaving = false);
              return;
            }

            try {
              // Check duplicate code (except self when editing)
              final existing = await _promoRef
                  .where('code', isEqualTo: code)
                  .get();
              final hasDuplicate = existing.docs.any((d) => d.id != doc?.id);
              if (hasDuplicate) {
                if (mounted) {
                  _showSnack('Kode "$code" sudah digunakan', isError: true);
                }
                setSheetState(() => isSaving = false);
                return;
              }

              final payload = {
                'code': code,
                'discountType': discountType,
                'discountValue': value,
                'expiryDate': Timestamp.fromDate(expiryDate),
                'isActive': isActive,
              };

              if (isEdit) {
                await _promoRef.doc(doc.id).update(payload);
              } else {
                payload['createdAt'] = FieldValue.serverTimestamp();
                await _promoRef.add(payload);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                _showSnack(
                  isEdit
                      ? 'Kupon "$code" berhasil diperbarui'
                      : 'Kupon "$code" berhasil ditambahkan',
                );
              }
            } catch (e) {
              if (mounted) _showSnack('Gagal menyimpan: $e', isError: true);
            } finally {
              if (ctx.mounted) setSheetState(() => isSaving = false);
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Handle bar ──
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _C.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Title ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _C.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Iconsax.edit_2 : Iconsax.ticket_discount,
                              color: _C.teal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Kupon' : 'Kupon Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ── Code ──
                      _SheetLabel('Kode Kupon'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          UpperCaseTextFormatter(),
                        ],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                        decoration: _inputDeco('Misal: MINANG20'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Kode tidak boleh kosong';
                          }
                          if (v.trim().length < 3) {
                            return 'Minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Discount Type ──
                      _SheetLabel('Tipe Diskon'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TypeChip(
                            label: 'Persen (%)',
                            icon: Iconsax.percentage_square,
                            isSelected: discountType == 'percentage',
                            onTap: () => setSheetState(
                              () => discountType = 'percentage',
                            ),
                          ),
                          const SizedBox(width: 10),
                          _TypeChip(
                            label: 'Nominal (Rp)',
                            icon: Iconsax.money_send,
                            isSelected: discountType == 'fixed',
                            onTap: () =>
                                setSheetState(() => discountType = 'fixed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Value ──
                      _SheetLabel(
                        discountType == 'percentage'
                            ? 'Nilai Diskon (%)'
                            : 'Nilai Diskon (Rp)',
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        decoration: _inputDeco(
                          discountType == 'percentage'
                              ? 'Misal: 20'
                              : 'Misal: 50000',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nilai tidak boleh kosong';
                          }
                          final n = num.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Masukkan angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Expiry Date ──
                      _SheetLabel('Tanggal Kedaluwarsa'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.calendar_1,
                                size: 18,
                                color: _C.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                  'id_ID',
                                ).format(expiryDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _C.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Active Toggle ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? _C.successBg : _C.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? _C.success.withValues(alpha: 0.2)
                                : _C.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Iconsax.tick_circle
                                  : Iconsax.close_circle,
                              size: 18,
                              color: isActive ? _C.success : _C.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isActive ? 'Kupon Aktif' : 'Kupon Nonaktif',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? _C.success : _C.error,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: isActive,
                              activeColor: _C.success,
                              onChanged: (v) =>
                                  setSheetState(() => isActive = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Save Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: _C.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            disabledBackgroundColor: _C.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _C.white,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Simpan Perubahan' : 'Tambah Kupon',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
    filled: true,
    fillColor: _C.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.error),
    ),
  );

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _C.primary,
        foregroundColor: _C.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manajemen Kupon',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _C.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoSheet(),
        backgroundColor: _C.primary,
        foregroundColor: _C.white,
        icon: const Icon(Iconsax.add, size: 20),
        label: Text(
          'Kupon Baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(fontSize: 13.5, color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari kode kupon…',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
                prefixIcon: Icon(
                  Iconsax.search_normal_1,
                  size: 18,
                  color: _C.textTertiary,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 8),

          // ── Promo list (StreamBuilder) ──
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _promoStream,
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.primary),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.warning_2, size: 48, color: _C.error),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat data kupon',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _C.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Filter by search
                final filtered = _search.isEmpty
                    ? docs
                    : docs.where((d) {
                        final code = (d.data()['code'] ?? '')
                            .toString()
                            .toLowerCase();
                        return code.contains(_search.toLowerCase());
                      }).toList();

                // Empty
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.ticket_expired,
                          size: 56,
                          color: _C.textHint,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _search.isEmpty
                              ? 'Belum ada kupon'
                              : 'Kupon tidak ditemukan',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _C.textTertiary,
                          ),
                        ),
                        if (_search.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap tombol "Kupon Baru" untuk menambah',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: _C.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Stats summary
                final activeCount = docs
                    .where((d) => d.data()['isActive'] == true)
                    .length;
                final expiredCount = docs.where((d) {
                  final exp = d.data()['expiryDate'] as Timestamp?;
                  return exp != null && _isExpired(exp);
                }).length;

                return Column(
                  children: [
                    // ── Summary chips ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: '${docs.length} Total',
                            color: _C.primary,
                            bg: _C.primary.withValues(alpha: 0.08),
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: '$activeCount Aktif',
                            color: _C.success,
                            bg: _C.successBg,
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: '$expiredCount Expired',
                            color: _C.warning,
                            bg: _C.warningBg,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

                    // ── List ──
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 80),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final doc = filtered[i];
                          final data = doc.data();
                          return _PromoCard(
                            doc: doc,
                            data: data,
                            index: i,
                            fmtCurrency: _fmtCurrency,
                            fmtDate: _fmtDate,
                            isExpired: _isExpired,
                            onToggle: () => _toggleActive(
                              doc.id,
                              data['isActive'] ?? false,
                            ),
                            onEdit: () => _showPromoSheet(doc: doc),
                            onDelete: () =>
                                _confirmDelete(doc.id, data['code'] ?? ''),
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
}

// ═══════════════════════════════════════════════════════════
//  WIDGETS
// ═══════════════════════════════════════════════════════════

// ── Promo Card ──
class _PromoCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, dynamic> data;
  final int index;
  final String Function(num) fmtCurrency;
  final String Function(Timestamp) fmtDate;
  final bool Function(Timestamp) isExpired;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PromoCard({
    required this.doc,
    required this.data,
    required this.index,
    required this.fmtCurrency,
    required this.fmtDate,
    required this.isExpired,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final code = data['code'] ?? '';
    final type = data['discountType'] ?? 'percentage';
    final value = data['discountValue'] ?? 0;
    final expiry = data['expiryDate'] as Timestamp?;
    final active = data['isActive'] ?? false;
    final expired = expiry != null && isExpired(expiry);

    // Determine status
    String statusLabel;
    Color statusColor;
    Color statusBg;
    if (!active) {
      statusLabel = 'Nonaktif';
      statusColor = _C.error;
      statusBg = _C.errorBg;
    } else if (expired) {
      statusLabel = 'Kedaluwarsa';
      statusColor = _C.warning;
      statusBg = _C.warningBg;
    } else {
      statusLabel = 'Aktif';
      statusColor = _C.success;
      statusBg = _C.successBg;
    }

    final discountText = type == 'percentage'
        ? '${(value as num).toInt()}%'
        : fmtCurrency(value as num);

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderLight),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Code + Status ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.ticket_discount,
                      size: 22,
                      color: _C.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type == 'percentage'
                              ? 'Diskon Persentase'
                              : 'Diskon Nominal',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: _C.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Details row ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _DetailCol(
                        label: 'Potongan',
                        value: discountText,
                        color: _C.primary,
                      ),
                    ),
                    Container(width: 1, height: 30, color: _C.border),
                    Expanded(
                      child: _DetailCol(
                        label: 'Berlaku s/d',
                        value: expiry != null ? fmtDate(expiry) : '-',
                        color: expired ? _C.warning : _C.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Actions ──
              Row(
                children: [
                  // Toggle
                  Expanded(
                    child: _ActionBtn(
                      icon: active ? Iconsax.eye_slash : Iconsax.eye,
                      label: active ? 'Nonaktifkan' : 'Aktifkan',
                      color: active ? _C.warning : _C.success,
                      onTap: onToggle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit
                  Expanded(
                    child: _ActionBtn(
                      icon: Iconsax.edit_2,
                      label: 'Edit',
                      color: _C.info,
                      onTap: onEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  Expanded(
                    child: _ActionBtn(
                      icon: Iconsax.trash,
                      label: 'Hapus',
                      color: _C.error,
                      onTap: onDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (100 + index * 60).ms, duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

// ── Detail Column ──
class _DetailCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.5, color: _C.textTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Action Button ──
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
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
      ),
    );
  }
}

// ── Summary Chip ──
class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Sheet Label ──
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _C.textSecondary,
      ),
    );
  }
}

// ── Type Chip ──
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _C.primary.withValues(alpha: 0.08) : _C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _C.primary : _C.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? _C.primary : _C.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _C.primary : _C.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── UpperCase Formatter ──
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
