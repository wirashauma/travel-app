// ignore_for_file: unused_field, deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_dijkstra_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue / No Purple
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFF1F5F9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
}

// Cloudinary config
const String _kCloudName = 'dr5lqvvhy';
const String _kUploadPreset = 'etravel_preset';
const String _kCloudinaryUrl =
    'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload';
// Default placeholder image for fleets
const String _kDefaultFleetImage =
    'https://images.unsplash.com/photo-1748215210950-536c6621629a?w=600&q=80';

// ═══════════════════════════════════════════════════════════
//  MANAGE FLEET PAGE — Real-time CRUD for Armada
// ═══════════════════════════════════════════════════════════
class ManageFleetPage extends StatelessWidget {
  const ManageFleetPage({super.key});
  // ── Firestore ref ──
  static final _fleetsRef =
      FirebaseFirestore.instance.collection('fleets').orderBy('name');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fleetsRef.snapshots(),
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _C.primary),
            );
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
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _EmptyState(
              icon: Iconsax.car,
              title: 'Belum Ada Armada',
              subtitle:
                  'Tekan tombol + untuk menambahkan armada baru.',
              color: _C.primary,
            );
          }
          // ── Fleet List ──
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _FleetCard(docId: doc.id, data: data, index: i);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFleetForm(context),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: Text(
          'Tambah Armada',
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
        'Manajemen Armada',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: _C.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }


  // ─────────────────────────────────────────────────────
  //  CLOUDINARY UPLOAD HELPER

  // ─────────────────────────────────────────────────────
  static Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_kCloudinaryUrl))
        ..fields['upload_preset'] = _kUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  //  SHOW FLEET FORM (Add / Edit) with Image Picker
  // ─────────────────────────────────────────────────────
  static void _showFleetForm(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? existing,
  }) {
    final existingName = existing?['name'] as String? ?? '';
    final nameCtrl = TextEditingController(text: existingName);
    final seatsCtrl = TextEditingController(
      text: existing != null ? '${existing['totalSeats'] ?? ''}' : '',
    );
    final vehicleTypeCtrl = TextEditingController(
      text: existing?['vehicleType'] as String? ?? '',
    );
    final isEdit = docId != null;
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        File? pickedImage;
        String? existingImageUrl = existing?['imageUrl'] as String?;
        bool isSaving = false;
        bool isUploading = false;
        String? selectedOrigin = existing?['origin'] as String?;
        String? selectedDestination = existing?['destination'] as String?;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // ── pick image ──
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final xFile = await picker.pickImage(
                source: source,
                maxWidth: 1200,
              );
              if (xFile != null) {
                setSheetState(() => pickedImage = File(xFile.path));
              }
            }

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
                        // ── Title ──
                        Text(
                          isEdit ? 'Edit Armada' : 'Tambah Armada Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEdit
                              ? 'Perbarui informasi armada.'
                              : 'Lengkapi data armada di bawah ini.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _C.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ── IMAGE PICKER AREA ──
                        Text(
                          'Foto Armada',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showImageSourceSheet(ctx, pickImage),
                          child: Container(
                            height: 170,
                            decoration: BoxDecoration(
                              color: _C.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _C.border, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildImagePreview(
                              pickedImage,
                              existingImageUrl,
                              isUploading,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormField(
                          label: 'Nama Mobil / Plat Nomor',
                          hint: 'Contoh: Minang Travel (Hiace BA 1234 MT)',
                          controller: nameCtrl,
                          icon: Iconsax.car,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FormField(
                          label: 'Jenis Kendaraan',
                          hint: 'Contoh: Toyota Hiace Premio',
                          controller: vehicleTypeCtrl,
                          icon: Iconsax.car,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // ── Rute Asal (Dynamic) ──
                        FutureBuilder<List<String>>(
                          future:
                              FirestoreDijkstraService.instance.getAllCities(),
                          builder: (ctx, snapshot) {
                            final citiesList = snapshot.data ?? [];
                            final isLoading = snapshot.connectionState ==
                                ConnectionState.waiting;
                            return _SearchableDropdownField(
                              label: 'Rute Asal',
                              hint: isLoading ? 'Memuat kota...' : 'Pilih rute asal',
                              initialValue: selectedOrigin,
                              icon: Iconsax.location,
                              items: citiesList,
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedOrigin = val;
                                });
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Wajib pilih rute asal';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // ── Rute Tujuan (Dynamic) ──
                        FutureBuilder<List<String>>(
                          future:
                              FirestoreDijkstraService.instance.getAllCities(),
                          builder: (ctx, snapshot) {
                            final citiesList = snapshot.data ?? [];
                            final isLoading = snapshot.connectionState ==
                                ConnectionState.waiting;
                            return _SearchableDropdownField(
                              label: 'Rute Tujuan',
                              hint: isLoading ? 'Memuat kota...' : 'Pilih rute tujuan',
                              initialValue: selectedDestination,
                              icon: Iconsax.location_tick,
                              items: citiesList,
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedDestination = val;
                                });
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Wajib pilih rute tujuan';
                                }
                                if (v == selectedOrigin) {
                                  return 'Tidak boleh sama dengan kota asal';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        // ── Total Kursi ──
                        _FormField(
                          label: 'Total Kursi',
                          hint: 'Contoh: 14',
                          controller: seatsCtrl,
                          icon: Iconsax.user,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Harus > 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        // ── Save Button ──
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (isSaving || isUploading)
                                ? null
                                : () async {
                                    try {
                                      if (formKey.currentState == null ||
                                          !formKey.currentState!.validate()) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                            ..clearSnackBars()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Harap isi semua field yang wajib.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: _C.warning,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                margin:
                                                    const EdgeInsets.all(16),
                                              ),
                                            );
                                        }
                                        return;
                                      }
                                      formKey.currentState!.save();
                                      setSheetState(() => isSaving = true);
                                      final name = nameCtrl.text.trim();
                                      if (name.isEmpty) {
                                        throw Exception(
                                            'Nama armada tidak valid');
                                      }
                                      final totalSeatsText =
                                          seatsCtrl.text.trim();
                                      final totalSeats =
                                          int.tryParse(totalSeatsText);
                                      if (totalSeats == null ||
                                          totalSeats <= 0) {
                                        throw Exception(
                                          'Jumlah kursi tidak valid',
                                        );
                                      }
                                      // Upload image to Cloudinary if picked
                                      String imageUrl = existingImageUrl ??
                                          _kDefaultFleetImage;
                                      if (pickedImage != null) {
                                        setSheetState(() => isUploading = true);
                                        final url = await _uploadToCloudinary(
                                          pickedImage!,
                                        );
                                        setSheetState(
                                          () => isUploading = false,
                                        );
                                        if (url != null) {
                                          imageUrl = url;
                                        } else {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                              ..clearSnackBars()
                                              ..showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Upload gagal, menggunakan gambar default.',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: _C.warning,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                ),
                                              );
                                          }
                                        }
                                      }
                                      final ref = FirebaseFirestore.instance
                                          .collection('fleets');
                                      if (isEdit) {
                                        final oldTotal =
                                            (existing?['totalSeats'] as num?)
                                                    ?.toInt() ??
                                                totalSeats;
                                        final oldAvail =
                                            (existing?['availableSeats']
                                                        as num?)
                                                    ?.toInt() ??
                                                oldTotal;
                                        final diff = totalSeats - oldTotal;
                                        final newAvail = (oldAvail + diff)
                                            .clamp(0, totalSeats);
                                        await ref.doc(docId).update({
                                          'name': name,
                                          'imageUrl': imageUrl,
                                          'totalSeats': totalSeats,
                                          'availableSeats': newAvail,
                                          'vehicleType':
                                              vehicleTypeCtrl.text.trim(),
                                          'origin': selectedOrigin,
                                          'destination': selectedDestination,
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                      } else {
                                        await ref.add({
                                          'name': name,
                                          'imageUrl': imageUrl,
                                          'totalSeats': totalSeats,
                                          'availableSeats': totalSeats,
                                          'vehicleType':
                                              vehicleTypeCtrl.text.trim(),
                                          'origin': selectedOrigin,
                                          'destination': selectedDestination,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                      }
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..clearSnackBars()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isEdit
                                                    ? 'Armada berhasil diperbarui'
                                                    : 'Armada berhasil ditambahkan',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: _C.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                              content: Text(
                                                e.toString(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: _C.error,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                              duration: const Duration(
                                                seconds: 5,
                                              ),
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
                            child: (isSaving || isUploading)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (isUploading) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          'Mengupload foto\u2026',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Text(
                                    isEdit
                                        ? 'Simpan Perubahan'
                                        : 'Tambah Armada',
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
        );
      },
    );
  }

  // ── Image preview widget ──
  static Widget _buildImagePreview(
    File? pickedImage,
    String? existingUrl,
    bool isUploading,
  ) {
    if (isUploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: _C.primary),
            SizedBox(height: 10),
            Text('Mengupload\u2026'),
          ],
        ),
      );
    }
    if (pickedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(pickedImage, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _C.success.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Foto dipilih \u2713',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            existingUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                'Tap untuk ganti foto',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _imagePlaceholder();
  }

  static Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.gallery_add,
          size: 40,
          color: _C.textTertiary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap untuk pilih foto',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _C.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Kamera atau Galeri',
          style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary),
        ),
      ],
    );
  }

  // ── Show image source options ──
  static void _showImageSourceSheet(
    BuildContext context,
    Future<void> Function(ImageSource) onPick,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.camera, color: _C.primary),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Ambil foto langsung',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _C.textTertiary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onPick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.gallery, color: _C.teal),
                ),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Pilih dari galeri perangkat',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _C.textTertiary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onPick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  DELETE FLEET
  // ─────────────────────────────────────────────────────
  static Future<void> _deleteFleet(
    BuildContext context,
    String docId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Armada?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
          ),
        ),
        content: Text(
          'Armada "$name" akan dihapus secara permanen.',
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
      await FirebaseFirestore.instance.collection('fleets').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Armada "$name" telah dihapus',
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
//  FLEET CARD WIDGET
//
//  ARSITEKTUR: Menghitung kursi tersedia secara REAL-TIME
//  dari koleksi `bookings` — BUKAN dari field `availableSeats`
//  di dokumen `fleets`. Jika booking dihapus manual di
//  Firebase Console, jumlah kursi otomatis update.
// ═══════════════════════════════════════════════════════════
class _FleetCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final int index;
  const _FleetCard({
    required this.docId,
    required this.data,
    required this.index,
  });
  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Armada Tanpa Nama';
    final imageUrl = data['imageUrl'] as String? ?? _kDefaultFleetImage;
    final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
    final todayDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // ── StreamBuilder: hitung kursi terpakai dari bookings ──
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('fleetId', isEqualTo: docId)
          .where('departureDate', isEqualTo: todayDate)
          .where('status',
              whereIn: ['pending', 'paid', 'validated', 'used']).snapshots(),
      builder: (context, bookingSnap) {
        // Hitung total kursi terpakai dari booking aktif hari ini
        int bookedSeatCount = 0;
        if (bookingSnap.hasData) {
          for (final doc in bookingSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final seats = (d['seatsBooked'] as num?)?.toInt() ?? 0;
            bookedSeatCount += seats;
          }
        }
        final availableSeats = (totalSeats - bookedSeatCount).clamp(
          0,
          totalSeats,
        );
        final ratio = totalSeats > 0 ? availableSeats / totalSeats : 0.0;
        Color statusColor;
        String statusLabel;
        Color statusBg;
        if (availableSeats == 0) {
          statusColor = _C.error;
          statusLabel = 'Penuh';
          statusBg = _C.errorBg;
        } else if (ratio <= 0.3) {
          statusColor = _C.warning;
          statusLabel = 'Hampir Penuh';
          statusBg = const Color(0xFFFFFBEB);
        } else {
          statusColor = _C.success;
          statusLabel = 'Tersedia';
          statusBg = _C.successBg;
        }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _C.border.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Iconsax.car,
                          size: 48,
                          color: _C.textTertiary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: _C.border.withValues(alpha: 0.15),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _C.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ── Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Iconsax.user,
                          size: 15,
                          color: _C.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tersedia: $availableSeats / $totalSeats Kursi',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: _C.border.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionChip(
                          icon: Iconsax.edit_2,
                          label: 'Edit',
                          color: _C.primary,
                          onTap: () => ManageFleetPage._showFleetForm(
                            context,
                            docId: docId,
                            existing: data,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ActionChip(
                          icon: Iconsax.trash,
                          label: 'Hapus',
                          color: _C.error,
                          onTap: () => ManageFleetPage._deleteFleet(
                            context,
                            docId,
                            name,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (100 + index * 60).ms, duration: 400.ms)
            .slideY(
              begin: 0.05,
              delay: (100 + index * 60).ms,
              duration: 400.ms,
            );
      }, // StreamBuilder builder
    ); // StreamBuilder
  }
}

// ═══════════════════════════════════════════════════════════
//  ACTION CHIP
// ═══════════════════════════════════════════════════════════
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({
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
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
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

// ── SEARCHABLE DROPDOWN FIELD ──
class _SearchableDropdownField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _SearchableDropdownField({
    required this.label,
    required this.hint,
    this.initialValue,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_SearchableDropdownField> createState() => _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<_SearchableDropdownField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _showDropdown = false;
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _filteredItems = List.from(widget.items)..sort();
    
    _focusNode.addListener(() {
      setState(() {
        _showDropdown = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _SearchableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
    // Update filtered items if items list changes (e.g. FutureBuilder resolves)
    if (widget.items != oldWidget.items) {
      setState(() {
        _filteredItems = List.from(widget.items)..sort();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort();
      _showDropdown = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _C.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: _C.textTertiary,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                widget.icon,
                size: 20,
                color: _C.textTertiary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: IconButton(
              icon: const Icon(Iconsax.search_normal_1, size: 18, color: _C.textTertiary),
              onPressed: () {
                _focusNode.requestFocus();
                setState(() {
                  _showDropdown = !_showDropdown;
                });
              },
            ),
            filled: true,
            fillColor: _C.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.primary, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: _onSearch,
          validator: widget.validator,
        ),
        if (_showDropdown && _filteredItems.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 120), // Exactly 3 items tall
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredItems.length,
                itemBuilder: (context, idx) {
                  final item = _filteredItems[idx];
                  return InkWell(
                    onTap: () {
                      _controller.text = item;
                      widget.onChanged(item);
                      setState(() {
                        _showDropdown = false;
                        _focusNode.unfocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        border: idx < _filteredItems.length - 1
                            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
                            : null,
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
