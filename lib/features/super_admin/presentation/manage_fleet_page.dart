// ignore_for_file: unused_field, deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const Color bg = Color(0xFFFAFBFD);
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
    'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=600&q=80';

// ─────────────────────────────────────────────────────────
//  DAFTAR ARMADA TRAVEL LOKAL SUMBAR (BAKU)
// ─────────────────────────────────────────────────────────
const List<String> kSumbarFleetNames = [
  'Minang Travel',
  'Tranex Mandiri',
  'Travel AWR (Andalas Wira Rutin)',
  'Maestro Travel',
  'Armada Travel Oke',
  'Yok Travel',
  'Andalas Transport',
  'Rhino Travel',
  'Bukit Express',
  'Ayah Travel',
  'Xago Travel',
  'Hikmah Travel',
  'Sumatera Shuttle',
  'Padang Travelindo',
  'TX Travel Padang',
  'Nusa Mulya Travel',
  'Annanta Travel',
  'Regina Transport',
  'ASRI Travel (Asri Karya Angkasa)',
  'Aura Wisata Transport',
  'Nazira Wisata Transport',
  'Jasa Mulya Travel',
  'Sarana Wisata',
  'PO NPM (Naikilah Perusahaan Minang)',
  'ANS (Anas Nasional Motor)',
  'Gumarang Jaya',
];

const List<String> kSumbarVehicleTypes = [
  'Toyota Hiace',
  'Isuzu Elf',
  'Innova Reborn',
];

const List<String> kSumbarCities = [
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

// ─────────────────────────────────────────────────────────
//  SEED DATA — Travel & Minibus Sumatera Barat
//  Semua armada menggunakan tipe kendaraan Minibus/Travel
//  (Toyota Hiace, Isuzu Elf, Toyota Innova)
//
//  Field `driverId` dikosongkan sebagai default — akan diisi
//  oleh Super Admin via halaman Manajemen Penugasan Sopir.
// ─────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kSumatranFleets = [
  {
    'name': 'Minang Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Bukittinggi',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Bukittinggi–Payakumbuh',
  },
  {
    'name': 'Tranex Mandiri',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Bukittinggi',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Padang–Bukittinggi door-to-door',
  },
  {
    'name': 'Travel AWR (Andalas Wira Rutin)',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Solok',
    'driverId': '',
    'description': 'Isuzu Elf Microbus — Padang–Solok–Sawahlunto',
  },
  {
    'name': 'Maestro Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Bukittinggi',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Pekanbaru via Bukittinggi',
  },
  {
    'name': 'Armada Travel Oke',
    'imageUrl': '',
    'totalSeats': 7,
    'vehicleType': 'Innova Reborn',
    'origin': 'Padang',
    'destination': 'Dharmasraya',
    'driverId': '',
    'description': 'Toyota Innova Reborn — Padang–Solok–Dharmasraya',
  },
  {
    'name': 'Yok Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Bukittinggi',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Bukittinggi–Pekanbaru express',
  },
  {
    'name': 'Andalas Transport',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Batusangkar',
    'driverId': '',
    'description': 'Isuzu Elf NLR — Padang–Padang Panjang–Batusangkar',
  },
  {
    'name': 'Rhino Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Pasaman',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Bukittinggi–Pasaman',
  },
  {
    'name': 'Bukit Express',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Bukittinggi',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Bukittinggi–Payakumbuh–Pekanbaru',
  },
  {
    'name': 'Ayah Travel',
    'imageUrl': '',
    'totalSeats': 7,
    'vehicleType': 'Innova Reborn',
    'origin': 'Padang',
    'destination': 'Pasaman Barat',
    'driverId': '',
    'description': 'Toyota Innova Zenix — Padang–Pariaman–Pasaman Barat',
  },
  {
    'name': 'Xago Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Solok Selatan',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Solok–Solok Selatan',
  },
  {
    'name': 'Hikmah Travel',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Pesisir Selatan',
    'driverId': '',
    'description': 'Isuzu Elf Microbus — Padang–Pesisir Selatan',
  },
  {
    'name': 'Sumatera Shuttle',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Bukittinggi',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Padang–Bukittinggi nonstop',
  },
  {
    'name': 'Padang Travelindo',
    'imageUrl': '',
    'totalSeats': 7,
    'vehicleType': 'Innova Reborn',
    'origin': 'Padang',
    'destination': 'Lubuk Basung',
    'driverId': '',
    'description': 'Toyota Innova Reborn — Padang–Pariaman–Lubuk Basung',
  },
  {
    'name': 'TX Travel Padang',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Pekanbaru premium',
  },
  {
    'name': 'Nusa Mulya Travel',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Bukittinggi',
    'destination': 'Sijunjung',
    'driverId': '',
    'description': 'Isuzu Elf NLR — Bukittinggi–Batusangkar–Sijunjung',
  },
  {
    'name': 'Annanta Travel',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Padang–Bukittinggi–Payakumbuh',
  },
  {
    'name': 'Regina Transport',
    'imageUrl': '',
    'totalSeats': 7,
    'vehicleType': 'Innova Reborn',
    'origin': 'Padang',
    'destination': 'Solok',
    'driverId': '',
    'description': 'Toyota Innova Zenix — Padang–Solok eksekutif',
  },
  {
    'name': 'ASRI Travel (Asri Karya Angkasa)',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Solok Selatan',
    'driverId': '',
    'description':
        'Toyota Hiace Commuter — Padang–Pesisir Selatan–Solok Selatan',
  },
  {
    'name': 'Aura Wisata Transport',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Dharmasraya',
    'driverId': '',
    'description': 'Isuzu Elf Microbus — Padang–Sawahlunto–Dharmasraya',
  },
  {
    'name': 'Nazira Wisata Transport',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Pasaman Barat',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Padang–Pasaman–Pasaman Barat',
  },
  {
    'name': 'Jasa Mulya Travel',
    'imageUrl': '',
    'totalSeats': 7,
    'vehicleType': 'Innova Reborn',
    'origin': 'Bukittinggi',
    'destination': 'Solok',
    'driverId': '',
    'description': 'Toyota Innova Reborn — Bukittinggi–Padang Panjang–Solok',
  },
  {
    'name': 'Sarana Wisata',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Dharmasraya',
    'driverId': '',
    'description': 'Isuzu Elf NLR — Padang–Sijunjung–Dharmasraya',
  },
  {
    'name': 'PO NPM (Naikilah Perusahaan Minang)',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Bukittinggi',
    'driverId': '',
    'description': 'Toyota Hiace Commuter — Padang–Bukittinggi–Pekanbaru',
  },
  {
    'name': 'ANS (Anas Nasional Motor)',
    'imageUrl': '',
    'totalSeats': 14,
    'vehicleType': 'Toyota Hiace',
    'origin': 'Padang',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Toyota Hiace Premio — Padang–Bukittinggi–Payakumbuh',
  },
  {
    'name': 'Gumarang Jaya',
    'imageUrl': '',
    'totalSeats': 12,
    'vehicleType': 'Isuzu Elf',
    'origin': 'Padang',
    'destination': 'Payakumbuh',
    'driverId': '',
    'description': 'Isuzu Elf Microbus — Padang–Batusangkar–Payakumbuh',
  },
];

// ═══════════════════════════════════════════════════════════
//  MANAGE FLEET PAGE — Real-time CRUD for Armada
// ═══════════════════════════════════════════════════════════
class ManageFleetPage extends StatelessWidget {
  const ManageFleetPage({super.key});

  // ── Firestore ref ──
  static final _fleetsRef = FirebaseFirestore.instance
      .collection('fleets')
      .orderBy('name');

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
              icon: Iconsax.bus,
              title: 'Belum Ada Armada',
              subtitle:
                  'Tekan tombol + untuk menambahkan armada baru\natau gunakan ikon \u2728 untuk seed data Sumatera.',
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
  //  APP BAR  (with seed button)
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
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome, size: 22),
          tooltip: 'Seed Data Armada Sumatera',
          onPressed: () => _seedFleets(context),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  SEED FLEETS
  // ─────────────────────────────────────────────────────
  static Future<void> _seedFleets(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _C.teal, size: 24),
            const SizedBox(width: 10),
            Text(
              'Seed Armada?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Akan menambahkan 26 armada travel Sumatera Barat:\n'
          '\u2022 Minang Travel, Tranex Mandiri, Bintang Minang\n'
          '\u2022 Sumbar Travel, Ratu Intan, Travel Ranah Minang\n'
          '\u2022 Koto Travel, Travel Pariaman, Bukittinggi Jaya\n'
          '\u2022 Solok Trans, Payakumbuh Express, Sawahlunto Go\n'
          '\u2022 Agam Jaya, Pesisir Travel, Sijunjung Trans\n'
          'dan lainnya (Minibus/Hiace Sumatera Barat).',
          style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary),
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
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              'Seed',
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
      final ref = FirebaseFirestore.instance.collection('fleets');
      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();

      for (final fleet in _kSumatranFleets) {
        final doc = ref.doc();
        batch.set(doc, {
          'name': fleet['name'],
          'imageUrl': fleet['imageUrl'],
          'totalSeats': fleet['totalSeats'],
          'availableSeats': fleet['totalSeats'],
          'vehicleType': fleet['vehicleType'] ?? '',
          'origin': fleet['origin'] ?? '',
          'destination': fleet['destination'] ?? '',
          'driverId': fleet['driverId'] ?? '',
          'description': fleet['description'],
          'createdAt': now,
          'updatedAt': now,
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\u2728 ${_kSumatranFleets.length} armada Sumatera berhasil ditambahkan!',
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal seed: $e'),
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
    // Check if existing name matches a known Sumbar fleet
    String? initialFleetName;
    if (existingName.isNotEmpty) {
      final match = kSumbarFleetNames.cast<String?>().firstWhere(
        (n) => n == existingName,
        orElse: () => null,
      );
      initialFleetName = match;
    }
    final seatsCtrl = TextEditingController(
      text: existing != null ? '${existing['totalSeats'] ?? ''}' : '',
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
        String? selectedFleetName = initialFleetName;
        String? selectedVehicleType = existing?['vehicleType'] as String?;
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

                        // ── Nama Armada (Dropdown Baku Sumbar) ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Armada',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedFleetName,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih nama armada',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _C.textTertiary,
                                ),
                                prefixIcon: const Icon(
                                  Iconsax.bus,
                                  size: 20,
                                  color: _C.textTertiary,
                                ),
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
                                  borderSide: const BorderSide(
                                    color: _C.primary,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _C.error,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _C.textPrimary,
                              ),
                              dropdownColor: _C.card,
                              menuMaxHeight: 350,
                              items: kSumbarFleetNames
                                  .map(
                                    (name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(
                                        name,
                                        style: GoogleFonts.inter(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setSheetState(() => selectedFleetName = val);
                              },
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Wajib pilih armada'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Jenis Kendaraan (Dropdown) ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jenis Kendaraan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  selectedVehicleType != null &&
                                      kSumbarVehicleTypes.contains(
                                        selectedVehicleType,
                                      )
                                  ? selectedVehicleType
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih jenis kendaraan',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _C.textTertiary,
                                ),
                                prefixIcon: const Icon(
                                  Iconsax.car,
                                  size: 20,
                                  color: _C.textTertiary,
                                ),
                                filled: true,
                                fillColor: _C.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _C.primary,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              items: kSumbarVehicleTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setSheetState(
                                () => selectedVehicleType = val,
                              ),
                              validator: (v) =>
                                  v == null ? 'Wajib pilih kendaraan' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Rute Asal (Dropdown) ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rute Asal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  selectedOrigin != null &&
                                      kSumbarCities.contains(selectedOrigin)
                                  ? selectedOrigin
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih kota asal',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _C.textTertiary,
                                ),
                                prefixIcon: const Icon(
                                  Iconsax.location,
                                  size: 20,
                                  color: _C.textTertiary,
                                ),
                                filled: true,
                                fillColor: _C.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _C.primary,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              items: kSumbarCities
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setSheetState(() => selectedOrigin = val),
                              validator: (v) =>
                                  v == null ? 'Wajib pilih kota asal' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Rute Tujuan (Dropdown) ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rute Tujuan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  selectedDestination != null &&
                                      kSumbarCities.contains(
                                        selectedDestination,
                                      )
                                  ? selectedDestination
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih kota tujuan',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _C.textTertiary,
                                ),
                                prefixIcon: const Icon(
                                  Iconsax.location_tick,
                                  size: 20,
                                  color: _C.textTertiary,
                                ),
                                filled: true,
                                fillColor: _C.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _C.border,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _C.primary,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              items: kSumbarCities
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setSheetState(
                                () => selectedDestination = val,
                              ),
                              validator: (v) {
                                if (v == null) return 'Wajib pilih kota tujuan';
                                if (v == selectedOrigin) {
                                  return 'Tidak boleh sama dengan kota asal';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);

                                    try {
                                      final name = selectedFleetName!.trim();
                                      final totalSeats = int.parse(
                                        seatsCtrl.text.trim(),
                                      );

                                      // Upload image to Cloudinary if picked
                                      String imageUrl =
                                          existingImageUrl ??
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
                                          'vehicleType': selectedVehicleType,
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
                                          'vehicleType': selectedVehicleType,
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
                                              content: Text('Error: $e'),
                                              backgroundColor: _C.error,
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

    // ── StreamBuilder: hitung kursi terpakai dari bookings ──
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('fleetId', isEqualTo: docId)
          .where('status', whereIn: ['pending', 'paid', 'validated', 'used'])
          .snapshots(),
      builder: (context, bookingSnap) {
        // Hitung total kursi terpakai dari SEMUA booking aktif
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
                              Iconsax.bus,
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
