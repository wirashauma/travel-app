// ignore_for_file: unused_field, deprecated_member_use, use_build_context_synchronously, dead_code

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/services/city_coordinates_seeder.dart';
import '../../../core/services/firestore_dijkstra_service.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
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
}


// ═══════════════════════════════════════════════════════════
//  MANAGE ROUTES PAGE — Firestore-backed Dijkstra edges
// ═══════════════════════════════════════════════════════════
class ManageRoutesPage extends StatelessWidget {
  const ManageRoutesPage({super.key});

  static final _routesRef =
      FirebaseFirestore.instance.collection('routes').orderBy('from');

  static final _currencyFmt = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: _routesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _C.primary),
            );
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Iconsax.warning_2,
              title: 'Terjadi Kesalahan',
              subtitle: '${snapshot.error}',
              color: _C.error,
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _EmptyState(
              icon: Iconsax.route_square,
              title: 'Belum Ada Rute',
              subtitle:
                  'Tekan tombol + untuk menambahkan jalur rute baru.',
              color: _C.primary,
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _RouteCard(
                docId: doc.id,
                data: data,
                index: i,
                currencyFmt: _currencyFmt,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteForm(context),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: Text(
          'Tambah Rute',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Manajemen Rute',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: _C.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.trash, size: 22),
          tooltip: 'Hapus Rute Non-Sumbar',
          onPressed: () => _deleteNonSumbarRoutes(context),
        ),
        IconButton(
          icon: const Icon(Iconsax.gps, size: 22),
          tooltip: 'Seed Koordinat GPS',
          onPressed: () => _seedCoordinates(context),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  SEED GPS COORDINATES
  // ─────────────────────────────────────────────────────
  static Future<void> _seedCoordinates(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.gps, color: _C.teal, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seed Koordinat GPS?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Akan menyuntikkan koordinat latitude & longitude ke:\n\n'
          '• Collection city_coordinates (lookup master)\n'
          '• Field fromLat/fromLng/toLat/toLng di setiap dokumen routes\n\n'
          'Data koordinat mencakup semua kota rute Sumatera.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _C.textSecondary,
            height: 1.4,
          ),
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Iconsax.gps, size: 18),
            label: Text(
              'Seed GPS',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await CityCoordinatesSeeder.seedAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '\u{1F4CD} ${result.cities} kota + ${result.routes} rute berhasil di-update dengan koordinat GPS!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: _C.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Gagal seed koordinat: $e',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: _C.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }



  // ─────────────────────────────────────────────────────
  //  DELETE NON-SUMBAR ROUTES — One-time cleanup
  // ─────────────────────────────────────────────────────
  static Future<void> _deleteNonSumbarRoutes(BuildContext context) async {
    const kotaSumbar = [
      'Batusangkar',
      'Bukittinggi',
      'Dharmasraya',
      'Lubuk Basung',
      'Padang',
      'Padang Panjang',
      'Pariaman',
      'Pasaman',
      'Pasaman Barat',
      'Payakumbuh',
      'Pesisir Selatan',
      'Sawahlunto',
      'Sijunjung',
      'Solok',
      'Solok Selatan',
    ];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.trash, color: _C.error, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bersihkan Rute Non-Sumbar?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Akan menghapus SEMUA dokumen di koleksi routes '
          'yang kota asal ATAU tujuannya bukan kota Sumatera Barat.\n\n'
          'Kota Sumbar: ${kotaSumbar.join(", ")}\n\n'
          'Aksi ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _C.textSecondary,
            height: 1.4,
          ),
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Iconsax.trash, size: 18),
            label: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final routesSnap =
          await FirebaseFirestore.instance.collection('routes').get();

      int deletedCount = 0;
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in routesSnap.docs) {
        final data = doc.data();
        final from = data['from'] as String? ?? '';
        final to = data['to'] as String? ?? '';
        if (!kotaSumbar.contains(from) || !kotaSumbar.contains(to)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '$deletedCount rute non-Sumbar berhasil dihapus!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: _C.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Gagal membersihkan: $e'),
              backgroundColor: _C.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }

  // ─────────────────────────────────────────────────────
  //  SHOW ROUTE FORM (Add / Edit)
  // ─────────────────────────────────────────────────────

  static void _showRouteForm(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? existing,
  }) {
    final distanceCtrl = TextEditingController(
      text: existing != null ? '${existing['distance'] ?? ''}' : '',
    );
    final priceCtrl = TextEditingController(
      text: existing != null ? '${existing['price'] ?? ''}' : '',
    );
    final durationCtrl = TextEditingController(
      text: existing?['duration'] ?? '',
    );
    final fromCtrl =
        TextEditingController(text: existing?['from'] as String? ?? '');
    final toCtrl =
        TextEditingController(text: existing?['to'] as String? ?? '');
    final isEdit = docId != null;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          bool isSaving = false;

          return Container(
            margin: const EdgeInsets.only(top: 60),
            decoration: const BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Handle bar ──
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _C.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        isEdit ? 'Edit Rute' : 'Tambah Rute Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEdit
                            ? 'Perbarui jalur antar kota.'
                            : 'Definisikan jalur/edge baru pada graph rute.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _C.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Kota Asal (Autocomplete) ──
                      FutureBuilder<List<String>>(
                          future:
                              FirestoreDijkstraService.instance.getAllCities(),
                          builder: (ctx, snapshot) {
                            final cities = snapshot.data ?? [];
                            return Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return cities.where((city) => city
                                    .toLowerCase()
                                    .contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              initialValue:
                                  TextEditingValue(text: fromCtrl.text),
                              fieldViewBuilder:
                                  (ctx, ctrl, focusNode, onFieldSubmitted) {
                                ctrl.addListener(() {
                                  fromCtrl.text = ctrl.text.trim();
                                });
                                return _FormField(
                                  label: 'Kota Asal',
                                  hint: 'Ketik kota asal...',
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  icon: Iconsax.location,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    return null;
                                  },
                                );
                              },
                              onSelected: (selection) {
                                fromCtrl.text = selection;
                              },
                            );
                          }),
                      const SizedBox(height: 16),

                      // ── Kota Tujuan (Autocomplete) ──
                      FutureBuilder<List<String>>(
                          future:
                              FirestoreDijkstraService.instance.getAllCities(),
                          builder: (ctx, snapshot) {
                            final cities = snapshot.data ?? [];
                            return Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return cities.where((city) => city
                                    .toLowerCase()
                                    .contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              initialValue: TextEditingValue(text: toCtrl.text),
                              fieldViewBuilder:
                                  (ctx, ctrl, focusNode, onFieldSubmitted) {
                                ctrl.addListener(() {
                                  toCtrl.text = ctrl.text.trim();
                                });
                                return _FormField(
                                  label: 'Kota Tujuan',
                                  hint: 'Ketik kota tujuan...',
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  icon: Iconsax.location_tick,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (v.trim().toLowerCase() ==
                                        fromCtrl.text.trim().toLowerCase()) {
                                      return 'Tidak boleh sama dengan kota asal';
                                    }
                                    return null;
                                  },
                                );
                              },
                              onSelected: (selection) {
                                toCtrl.text = selection;
                              },
                            );
                          }),
                      const SizedBox(height: 16),

                      // ── Jarak & Harga ──
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              label: 'Jarak (km)',
                              hint: '120',
                              controller: distanceCtrl,
                              icon: Iconsax.ruler,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Wajib';
                                }
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              label: 'Harga (Rp)',
                              hint: '85000',
                              controller: priceCtrl,
                              icon: Iconsax.money_recive,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Wajib';
                                }
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Durasi ──
                      _FormField(
                        label: 'Estimasi Durasi',
                        hint: 'Contoh: 3 jam 30 menit',
                        controller: durationCtrl,
                        icon: Iconsax.clock,
                      ),
                      const SizedBox(height: 28),

                      // ── Save Button ──
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);

                                  try {
                                    final from = fromCtrl.text.trim();
                                    final to = toCtrl.text.trim();
                                    final distance = int.parse(
                                      distanceCtrl.text.trim(),
                                    );
                                    final price = int.parse(
                                      priceCtrl.text.trim(),
                                    );
                                    final duration = durationCtrl.text.trim();

                                    final ref = FirebaseFirestore.instance
                                        .collection('routes');

                                    final payload = {
                                      'from': from,
                                      'to': to,
                                      'distance': distance,
                                      'price': price,
                                      'duration': duration,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    };

                                    if (isEdit) {
                                      await ref.doc(docId).update(payload);
                                    } else {
                                      payload['createdAt'] =
                                          FieldValue.serverTimestamp();
                                      await ref.add(payload);
                                    }

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                        ..clearSnackBars()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isEdit
                                                  ? 'Rute berhasil diperbarui'
                                                  : 'Rute berhasil ditambahkan',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: _C.success,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx)
                                        ..clearSnackBars()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: _C.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Simpan Perubahan' : 'Tambah Rute',
                                  style: GoogleFonts.inter(
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

  // ─────────────────────────────────────────────────────
  //  DELETE ROUTE
  // ─────────────────────────────────────────────────────
  static Future<void> _deleteRoute(
    BuildContext context,
    String docId,
    String label,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Rute?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
          ),
        ),
        content: Text(
          'Rute "$label" akan dihapus secara permanen.',
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('routes').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Rute berhasil dihapus',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: _C.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: _C.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  ROUTE CARD WIDGET
// ═══════════════════════════════════════════════════════════
class _RouteCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final int index;
  final NumberFormat currencyFmt;

  const _RouteCard({
    required this.docId,
    required this.data,
    required this.index,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final from = data['from'] as String? ?? '-';
    final to = data['to'] as String? ?? '-';
    final distance = (data['distance'] as num?)?.toInt() ?? 0;
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final duration = data['duration'] as String? ?? '';
    final label = '$from \u2192 $to';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── From \u2192 To ──
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _C.teal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.teal.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      from,
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

              // Dotted line
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 2,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      color: _C.textTertiary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      to,
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

              const SizedBox(height: 14),

              // ── Info chips ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Iconsax.ruler,
                    label: '$distance km',
                    color: _C.teal,
                  ),
                  _InfoChip(
                    icon: Iconsax.money_recive,
                    label: currencyFmt.format(price),
                    color: _C.primary,
                  ),
                  if (duration.isNotEmpty)
                    _InfoChip(
                      icon: Iconsax.clock,
                      label: duration,
                      color: _C.warning,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Action buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon: Iconsax.edit_2,
                    label: 'Edit',
                    color: _C.primary,
                    onTap: () => ManageRoutesPage._showRouteForm(
                      context,
                      docId: docId,
                      existing: data,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    icon: Iconsax.trash,
                    label: 'Hapus',
                    color: _C.error,
                    onTap: () => ManageRoutesPage._deleteRoute(
                      context,
                      docId,
                      label,
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
        .fadeIn(delay: (100 + index * 60).ms, duration: 400.ms)
        .slideY(begin: 0.05, delay: (100 + index * 60).ms, duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  INFO CHIP
// ═══════════════════════════════════════════════════════════
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════
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
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FORM FIELD WIDGET
// ═══════════════════════════════════════════════════════════
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: _C.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary),
            prefixIcon: Icon(icon, size: 20, color: _C.textTertiary),
            filled: true,
            fillColor: _C.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE WIDGET
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
              style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
