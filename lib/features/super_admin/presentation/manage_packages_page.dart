import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shipment_model.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
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
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
}

class ManagePackagesPage extends StatefulWidget {
  const ManagePackagesPage({super.key});

  @override
  State<ManagePackagesPage> createState() => _ManagePackagesPageState();
}

class _ManagePackagesPageState extends State<ManagePackagesPage> {
  String _search = '';
  String _activeFilter = 'pending'; // semua | pending | transit | selesai

  List<ShipmentModel> _filterPackages(List<ShipmentModel> list) {
    List<ShipmentModel> result = list;

    // Filter by tab status
    if (_activeFilter == 'pending') {
      result = result.where((s) => s.status == 'pending').toList();
    } else if (_activeFilter == 'transit') {
      result = result.where((s) => s.status == 'picked_up' || s.status == 'in_transit').toList();
    } else if (_activeFilter == 'selesai') {
      result = result.where((s) => s.status == 'delivered' || s.status == 'confirmed_by_passenger').toList();
    }

    // Filter by search query
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((s) {
        final desc = s.description.toLowerCase();
        final sender = (s.senderName ?? s.userName).toLowerCase();
        final receiver = (s.receiverName ?? '').toLowerCase();
        final code = (s.packageCode ?? '').toLowerCase();
        return desc.contains(q) || sender.contains(q) || receiver.contains(q) || code.contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> _approveAndHandover(ShipmentModel shipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Penyerahan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        content: Text(
          'Setujui pengiriman paket "${shipment.description}" dan serahkan ke mobil armada "${shipment.fleetName ?? 'Armada Pilihan'}"?',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: _C.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, Serahkan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _C.primary)),
    );

    try {
      // 1. Fetch assigned driver from the fleet document
      String? driverId;
      String? driverName;

      if (shipment.fleetId != null && shipment.fleetId!.isNotEmpty) {
        final fleetDoc = await FirebaseFirestore.instance
            .collection('fleets')
            .doc(shipment.fleetId)
            .get();

        if (fleetDoc.exists) {
          final data = fleetDoc.data();
          driverId = data?['driverId'] as String?;
          driverName = data?['driverName'] as String?;
        }
      }

      // 2. Generate unique package receipt code (PKG-YYYYMMDD-XXXX)
      final rand = Random();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      String code = 'PKG-$dateStr-${rand.nextInt(9000) + 1000}';

      // Ensure uniqueness in Firestore
      bool isUnique = false;
      int attempts = 0;
      while (!isUnique && attempts < 5) {
        final existing = await FirebaseFirestore.instance
            .collection('shipments')
            .where('packageCode', isEqualTo: code)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) {
          isUnique = true;
        } else {
          code = 'PKG-$dateStr-${rand.nextInt(9000) + 1000}';
          attempts++;
        }
      }

      // 3. Update Firestore shipment doc
      await FirebaseFirestore.instance.collection('shipments').doc(shipment.id).update({
        'status': 'picked_up', // status: picked_up means it is loaded onto the car
        'packageCode': code,
        'driverId': driverId,
        'driverName': driverName,
        'updatedAt': FieldValue.serverTimestamp(),
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // close loading dialog
      _showSnack('Paket berhasil disetujui & diserahkan ke sopir. Resi: $code');
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading
      _showSnack('Gagal menyerahkan paket: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manajemen Paket',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shipments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonLoader.list();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.warning_2, size: 48, color: _C.error),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data paket', style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary)),
                ],
              ),
            );
          }

          final allShipments = (snapshot.data?.docs ?? [])
              .map((doc) => ShipmentModel.fromFirestore(doc))
              .toList();
          allShipments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filtered = _filterPackages(allShipments);

          return Column(
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
                    hintText: 'Cari resi, pengirim, atau penerima...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
                    prefixIcon: const Icon(Iconsax.search_normal_1, size: 18, color: _C.textTertiary),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),

              // ── Interactive Category filter chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildFilterChip('semua', 'Semua', allShipments.length, _C.primary),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Menunggu Persetujuan', allShipments.where((s) => s.status == 'pending').length, _C.warning),
                    const SizedBox(width: 8),
                    _buildFilterChip('transit', 'Dalam Perjalanan', allShipments.where((s) => s.status == 'picked_up' || s.status == 'in_transit').length, _C.info),
                    const SizedBox(width: 8),
                    _buildFilterChip('selesai', 'Selesai', allShipments.where((s) => s.status == 'delivered' || s.status == 'confirmed_by_passenger').length, _C.success),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

              // ── Package List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.box_2, size: 48, color: _C.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada paket ditemukan',
                              style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad + 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final shipment = filtered[i];
                          return _PackageAdminCard(
                            shipment: shipment,
                            index: i,
                            onApprove: () => _approveAndHandover(shipment),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, int count, Color color) {
    final isSelected = _activeFilter == filterKey;
    final activeColor = isSelected ? color : _C.textSecondary;
    final activeBgColor = isSelected ? color.withValues(alpha: 0.1) : Colors.white;
    final activeBorderColor = isSelected ? color : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activeBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeBorderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _C.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageAdminCard extends StatelessWidget {
  final ShipmentModel shipment;
  final int index;
  final VoidCallback onApprove;

  const _PackageAdminCard({
    required this.shipment,
    required this.index,
    required this.onApprove,
  });

  Color _statusColor() {
    switch (shipment.status) {
      case 'pending': return _C.warning;
      case 'picked_up':
      case 'in_transit': return _C.info;
      case 'delivered':
      case 'confirmed_by_passenger': return _C.success;
      default: return _C.textTertiary;
    }
  }

  Color _statusBg() {
    switch (shipment.status) {
      case 'pending': return _C.warningBg;
      case 'picked_up':
      case 'in_transit': return _C.infoBg;
      case 'delivered':
      case 'confirmed_by_passenger': return _C.successBg;
      default: return _C.borderLight;
    }
  }

  String _statusLabel() {
    switch (shipment.status) {
      case 'pending': return 'Menunggu Persetujuan';
      case 'picked_up': return 'Diserahkan ke Sopir';
      case 'in_transit': return 'Dalam Perjalanan';
      case 'delivered': return 'Sampai di Loket';
      case 'confirmed_by_passenger': return 'Diterima Penerima';
      default: return shipment.status;
    }
  }

  String get _packageSizeLabel {
    switch (shipment.packageSize) {
      case 'kecil': return 'Paket Kecil';
      case 'sedang': return 'Paket Sedang';
      case 'besar': return 'Paket Besar';
      default: return 'Kecil';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(shipment.createdAt);
    final hasCode = shipment.packageCode != null && shipment.packageCode!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: _C.primary.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _statusBg(), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _statusLabel(),
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: _statusColor()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Package Description
            Text(
              shipment.description,
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: _C.textPrimary),
            ),
            const SizedBox(height: 6),

            // Route
            Row(
              children: [
                const Icon(Iconsax.routing, size: 14, color: _C.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${shipment.origin} → ${shipment.destination}',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            const Divider(height: 1, color: _C.borderLight),
            const SizedBox(height: 10),

            // Details info rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengirim', style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary)),
                    const SizedBox(height: 2),
                    Text(shipment.senderName ?? shipment.userName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Penerima (Ambil di Loket)', style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary)),
                    const SizedBox(height: 2),
                    Text(shipment.receiverName ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ukuran Paket', style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary)),
                    const SizedBox(height: 2),
                    Text(_packageSizeLabel, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Armada Tujuan', style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary)),
                    const SizedBox(height: 2),
                    Text(shipment.fleetName ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _C.textPrimary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Unique Receipt Code display
            if (hasCode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Iconsax.barcode, size: 20, color: _C.primary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KODE RESI PAKET', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: _C.primary)),
                        const SizedBox(height: 1),
                        Text(
                          shipment.packageCode!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _C.textPrimary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Iconsax.copy, size: 16, color: _C.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shipment.packageCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Resi disalin!', style: GoogleFonts.inter(fontSize: 12)),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Approve Action Button
            if (shipment.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Iconsax.box_tick, size: 16),
                  label: Text('Setujui & Serahkan ke Sopir', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  onPressed: onApprove,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
