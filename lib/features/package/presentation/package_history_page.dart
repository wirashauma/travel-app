import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shipment_model.dart';
import '../../../core/services/shipment_service.dart';
import 'package_tracking_page.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
}

enum _FilterOption { all, pending, inTransit, delivered, cancelled }

class PackageHistoryPage extends StatefulWidget {
  const PackageHistoryPage({super.key});

  @override
  State<PackageHistoryPage> createState() => _PackageHistoryPageState();
}

class _PackageHistoryPageState extends State<PackageHistoryPage> {
  _FilterOption _selectedFilter = _FilterOption.all;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Text('Silakan login terlebih dahulu',
              style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _Header(),
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (f) => setState(() => _selectedFilter = f),
          ),
          Expanded(
            child: StreamBuilder<List<ShipmentModel>>(
              stream: ShipmentService.userShipmentsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ShimmerList();
                }
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: Iconsax.warning_2,
                    message: 'Gagal memuat data',
                    subtitle: 'Tarik ke bawah untuk mencoba lagi',
                  );
                }
                var shipments = snapshot.data ?? [];
                shipments = _applyFilter(shipments);
                if (shipments.isEmpty) {
                  return _EmptyState(
                    icon: Iconsax.box_2,
                    message: _selectedFilter == _FilterOption.all
                        ? 'Belum ada paket'
                        : 'Tidak ada paket dengan status ini',
                    subtitle: 'Paket yang kamu ajukan akan muncul di sini',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: shipments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PackageCard(
                    shipment: shipments[i],
                    index: i,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PackageTrackingPage(shipment: shipments[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ShipmentModel> _applyFilter(List<ShipmentModel> items) {
    switch (_selectedFilter) {
      case _FilterOption.all:
        return items;
      case _FilterOption.pending:
        return items.where((s) => s.status == 'pending').toList();
      case _FilterOption.inTransit:
        return items.where((s) => s.status == 'picked_up' || s.status == 'in_transit' || s.status == 'confirmed').toList();
      case _FilterOption.delivered:
        return items.where((s) => s.status == 'delivered' || s.status == 'confirmed_by_passenger').toList();
      case _FilterOption.cancelled:
        return items.where((s) => s.status == 'cancelled').toList();
    }
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primary, Color(0xFF1A6BB3)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat Paket',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text('Semua pengajuan paket kamu',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _FilterOption selected;
  final ValueChanged<_FilterOption> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  static const _options = [
    (_FilterOption.all, 'Semua'),
    (_FilterOption.pending, 'Diajukan'),
    (_FilterOption.inTransit, 'Dikirim'),
    (_FilterOption.delivered, 'Selesai'),
    (_FilterOption.cancelled, 'Batal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _options.map((opt) {
            final (value, label) = opt;
            final isSelected = selected == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _C.primary : _C.borderLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : _C.textSecondary,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ShipmentModel shipment;
  final int index;
  final VoidCallback onTap;
  const _PackageCard({required this.shipment, required this.index, required this.onTap});

  Color _statusColor() {
    switch (shipment.status) {
      case 'pending': return _C.warning;
      case 'picked_up':
      case 'in_transit':
      case 'confirmed': return _C.info;
      case 'delivered':
      case 'confirmed_by_passenger': return _C.success;
      case 'cancelled': return _C.danger;
      default: return _C.textTertiary;
    }
  }

  Color _statusBg() {
    switch (shipment.status) {
      case 'pending': return _C.warningBg;
      case 'picked_up':
      case 'in_transit':
      case 'confirmed': return _C.infoBg;
      case 'delivered':
      case 'confirmed_by_passenger': return _C.successBg;
      case 'cancelled': return _C.dangerBg;
      default: return _C.borderLight;
    }
  }

  String _statusLabel() {
    switch (shipment.status) {
      case 'pending': return 'Diajukan';
      case 'confirmed': return 'Dikonfirmasi';
      case 'picked_up': return 'Sudah Diambil';
      case 'in_transit': return 'Dalam Perjalanan';
      case 'delivered': return 'Sudah Sampai';
      case 'confirmed_by_passenger': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return shipment.status;
    }
  }

  IconData _statusIcon() {
    switch (shipment.status) {
      case 'pending': return Iconsax.clock;
      case 'confirmed': return Iconsax.tick_circle;
      case 'picked_up': return Iconsax.tick_circle;
      case 'in_transit': return Iconsax.truck_fast;
      case 'delivered': return Iconsax.location_tick;
      case 'confirmed_by_passenger': return Iconsax.tick_circle;
      case 'cancelled': return Iconsax.close_circle;
      default: return Iconsax.box_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(shipment.createdAt);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusBg(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_statusIcon(), size: 20, color: _statusColor()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shipment.description,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary)),
                        const SizedBox(height: 2),
                        Text(dateStr,
                            style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(), size: 12, color: _statusColor()),
                        const SizedBox(width: 4),
                        Text(_statusLabel(),
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor())),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(Iconsax.map_1, 'Asal', shipment.origin),
              const SizedBox(height: 6),
              _row(Iconsax.map, 'Tujuan', shipment.destination),
              if (shipment.fleetName != null) ...[
                const SizedBox(height: 6),
                _row(Iconsax.car, 'Armada', shipment.fleetName!),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Lihat Detail',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _C.primary)),
                  const SizedBox(width: 4),
                  Icon(Iconsax.arrow_right_3, size: 14, color: _C.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 + index * 60).ms, duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms);
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _C.textTertiary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary)),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: _C.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Card(
        elevation: 0,
        color: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _C.border),
        ),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _C.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120, height: 14,
                        decoration: BoxDecoration(
                          color: _C.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80, height: 10,
                        decoration: BoxDecoration(
                          color: _C.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: _C.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80, height: 12,
                    decoration: BoxDecoration(
                      color: _C.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 100, height: 12,
                    decoration: BoxDecoration(
                      color: _C.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().shimmer(duration: 1200.ms, color: _C.borderLight);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState({
    this.icon = Iconsax.box_2,
    required this.message,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: _C.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _C.textSecondary),
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
