import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shipment_model.dart';
import '../../../core/services/shipment_service.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
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
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFF0F9FF);
}

class DriverPackageConfirmationPage extends StatefulWidget {
  const DriverPackageConfirmationPage({super.key});

  @override
  State<DriverPackageConfirmationPage> createState() => _DriverPackageConfirmationPageState();
}

class _DriverPackageConfirmationPageState extends State<DriverPackageConfirmationPage> {
  final _auth = FirebaseAuth.instance;

  String? _origin;
  String? _destination;

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final fleets = await FirebaseFirestore.instance
          .collection('fleets')
          .where('driverId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (fleets.docs.isEmpty) return;

      final doc = fleets.docs.first;
      final data = doc.data();
      if (mounted) {
        setState(() {
          _origin = data['origin'] as String? ?? '';
          _destination = data['destination'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu')));
    }

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text('Konfirmasi Paket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: _C.primary,
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Tersedia'),
                  Tab(text: 'Ditugaskan'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AvailablePackagesTab(
                    fleetOrigin: _origin,
                    fleetDestination: _destination,
                  ),
                  _DriverPackagesTab(driverId: user.uid, driverName: user.displayName ?? 'Sopir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailablePackagesTab extends StatefulWidget {
  final String? fleetOrigin;
  final String? fleetDestination;

  const _AvailablePackagesTab({
    this.fleetOrigin,
    this.fleetDestination,
  });

  @override
  State<_AvailablePackagesTab> createState() => _AvailablePackagesTabState();
}

class _AvailablePackagesTabState extends State<_AvailablePackagesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.fleetOrigin == null || widget.fleetDestination == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.car, size: 64, color: _C.textTertiary),
            const SizedBox(height: 16),
            Text('Anda belum memiliki armada',
                style: GoogleFonts.inter(fontSize: 15, color: _C.textSecondary)),
            const SizedBox(height: 4),
            Text('Hubungi admin untuk penugasan armada',
                style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary)),
          ],
        ),
      );
    }

    return StreamBuilder<List<ShipmentModel>>(
      stream: ShipmentService.pendingShipmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, size: 64, color: _C.textTertiary),
                const SizedBox(height: 16),
                Text('Gagal memuat paket', style: GoogleFonts.inter(fontSize: 15, color: _C.textSecondary)),
                const SizedBox(height: 4),
                Text(snapshot.error.toString(), style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
              ],
            ),
          );
        }
        final packages = (snapshot.data ?? [])
            .where((s) => s.origin == widget.fleetOrigin && s.destination == widget.fleetDestination)
            .toList();
        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.box_2, size: 64, color: _C.textTertiary),
                const SizedBox(height: 16),
                Text('Tidak ada paket tersedia', style: GoogleFonts.inter(fontSize: 15, color: _C.textSecondary)),
              ],
            ),
          );
        }
        final user = FirebaseAuth.instance.currentUser;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PackageCard(
            shipment: packages[index],
            index: index,
            showTakeButton: true,
            driverId: user?.uid ?? '',
            driverName: user?.displayName ?? 'Sopir',
          ),
        );
      },
    );
  }
}

class _DriverPackagesTab extends StatelessWidget {
  final String driverId;
  final String driverName;

  const _DriverPackagesTab({required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShipmentModel>>(
      stream: ShipmentService.driverShipmentsStream(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, size: 64, color: _C.textTertiary),
                const SizedBox(height: 16),
                Text('Gagal memuat paket', style: GoogleFonts.inter(fontSize: 15, color: _C.textSecondary)),
                const SizedBox(height: 4),
                Text(snapshot.error.toString(), style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
              ],
            ),
          );
        }
        final packages = snapshot.data ?? [];
        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.box_tick, size: 64, color: _C.textTertiary),
                const SizedBox(height: 16),
                Text('Belum ada paket ditugaskan', style: GoogleFonts.inter(fontSize: 15, color: _C.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PackageCard(
            shipment: packages[index],
            index: index,
            showTakeButton: false,
            driverId: driverId,
            driverName: driverName,
          ),
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ShipmentModel shipment;
  final int index;
  final bool showTakeButton;
  final String driverId;
  final String driverName;

  const _PackageCard({
    required this.shipment,
    required this.index,
    required this.showTakeButton,
    required this.driverId,
    required this.driverName,
  });

  Color _statusColor() {
    switch (shipment.status) {
      case 'pending': return _C.warning;
      case 'picked_up': return _C.info;
      case 'in_transit': return _C.primary;
      case 'delivered': return _C.success;
      case 'confirmed_by_passenger': return _C.success;
      default: return _C.textTertiary;
    }
  }

  Color _statusBg() {
    switch (shipment.status) {
      case 'pending': return _C.warningBg;
      case 'picked_up': return _C.infoBg;
      case 'in_transit': return _C.infoBg;
      case 'delivered': return _C.successBg;
      case 'confirmed_by_passenger': return _C.successBg;
      default: return _C.border;
    }
  }

  String _statusLabel() {
    switch (shipment.status) {
      case 'pending': return 'Menunggu Sopir';
      case 'picked_up': return 'Sudah Diambil';
      case 'in_transit': return 'Dalam Perjalanan';
      case 'delivered': return 'Sudah Sampai';
      case 'confirmed_by_passenger': return 'Selesai';
      default: return shipment.status;
    }
  }

  IconData _statusIcon() {
    switch (shipment.status) {
      case 'pending': return Iconsax.clock;
      case 'picked_up': return Iconsax.tick_circle;
      case 'in_transit': return Iconsax.truck_fast;
      case 'delivered': return Iconsax.location_tick;
      case 'confirmed_by_passenger': return Iconsax.tick_circle;
      default: return Iconsax.box_2;
    }
  }

  String? get _packageLabel {
    switch (shipment.packageSize) {
      case 'kecil': return 'Kecil';
      case 'sedang': return 'Sedang';
      case 'besar': return 'Besar';
      default: return null;
    }
  }

  List<_ActionButton> _actions(BuildContext context) {
    final actions = <_ActionButton>[];
    switch (shipment.status) {
      case 'pending':
        if (showTakeButton) {
          actions.add(_ActionButton(
            label: 'Ambil Paket',
            icon: Iconsax.box_tick,
            color: _C.primary,
            onTap: () async {
              await ShipmentService.updateStatus(shipment.id!, 'picked_up',
                  driverId: driverId, driverName: driverName);
            },
          ));
        }
        break;
      case 'picked_up':
        actions.add(_ActionButton(
          label: 'Dalam Perjalanan',
          icon: Iconsax.truck_fast,
          color: _C.info,
          onTap: () async {
            await ShipmentService.updateStatus(shipment.id!, 'in_transit');
          },
        ));
      case 'in_transit':
        actions.add(_ActionButton(
          label: 'Tandai Sampai',
          icon: Iconsax.location_tick,
          color: _C.success,
          onTap: () async {
            await ShipmentService.updateStatus(shipment.id!, 'delivered');
          },
        ));
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(shipment.createdAt);
    final acts = _actions(context);

    return Card(
      elevation: 0,
      color: _C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _C.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(dateStr),
            const SizedBox(height: 16),
            _buildRouteStrip(),
            const SizedBox(height: 16),
            _buildSenderSection(),
            if (shipment.receiverName != null) ...[
              const SizedBox(height: 16),
              _buildReceiverSection(),
            ],
            if (_packageLabel != null || shipment.paymentMethod != null) ...[
              const SizedBox(height: 16),
              _buildPackageInfoSection(),
            ],
            if (shipment.notes != null && shipment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesSection(),
            ],
            if (acts.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...acts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _ActionChip(action: a),
                    ),
                  )),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 + index * 60).ms, duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms);
  }

  Widget _buildHeader(String dateStr) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _statusBg(), borderRadius: BorderRadius.circular(12)),
          child: Icon(_statusIcon(), size: 22, color: _statusColor()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shipment.description,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: _C.textPrimary)),
              const SizedBox(height: 2),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _statusBg(), borderRadius: BorderRadius.circular(8)),
          child: Text(_statusLabel(),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor())),
        ),
      ],
    );
  }

  Widget _buildRouteStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asal', style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                const SizedBox(height: 2),
                Text(shipment.origin,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Iconsax.arrow_right_3, size: 16, color: _C.textTertiary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Tujuan', style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                const SizedBox(height: 2),
                Text(shipment.destination,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderSection() {
    return _infoGroup('Pengirim', [
      _infoRow(Iconsax.profile_circle, 'Nama', shipment.senderName ?? shipment.userName),
      _infoRow(Iconsax.call, 'No. HP', shipment.senderPhone ?? shipment.userPhone),
    ]);
  }

  Widget _buildReceiverSection() {
    final children = <Widget>[
      _infoRow(Iconsax.directbox_notif, 'Nama', shipment.receiverName!),
    ];
    if (shipment.receiverPhone != null) {
      children.add(_infoRow(Iconsax.call, 'No. HP', shipment.receiverPhone!));
    }
    if (shipment.receiverAddress != null && shipment.receiverAddress!.isNotEmpty) {
      children.add(_addressRow(shipment.receiverAddress!));
    }
    return _infoGroup('Penerima', children);
  }

  Widget _buildPackageInfoSection() {
    final children = <Widget>[];
    if (_packageLabel != null && shipment.packagePrice != null) {
      children.add(_infoRow(Iconsax.box_2, 'Paket',
          '$_packageLabel (Rp${NumberFormat('#,###', 'id_ID').format(shipment.packagePrice)})'));
    }
    if (shipment.paymentMethod != null) {
      children.add(_infoRow(Iconsax.wallet, 'Pembayaran',
          shipment.paymentMethod == 'midtrans' ? 'Midtrans (Online)' : 'COD (Bayar di Tempat)'));
    }
    if (shipment.paymentStatus != null) {
      final isPaid = shipment.paymentStatus == 'paid';
      children.add(_infoRow(isPaid ? Iconsax.tick_circle : Iconsax.timer, 'Status Bayar', isPaid ? 'Lunas' : 'Belum Bayar',
          valueColor: isPaid ? _C.success : _C.warning));
    }
    return _infoGroup('Informasi Paket', children);
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.warningBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.message_text, size: 16, color: _C.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catatan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _C.warning)),
                const SizedBox(height: 4),
                Text(shipment.notes!, style: GoogleFonts.inter(fontSize: 13, color: _C.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSecondary)),
        const SizedBox(height: 8),
        ...List.generate(children.length, (i) {
          if (i == 0) return children[i];
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: children[i],
          );
        }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        SizedBox(width: 18, child: Icon(icon, size: 14, color: _C.textTertiary)),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary)),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? _C.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _addressRow(String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 18, child: Icon(Iconsax.location, size: 14, color: _C.textTertiary)),
        const SizedBox(width: 8),
        Text('Alamat: ', style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary)),
        Expanded(
          child: Text(address,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _C.textPrimary)),
        ),
      ],
    );
  }
}

class _ActionButton {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
}

class _ActionChip extends StatelessWidget {
  final _ActionButton action;

  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: action.onTap,
      style: TextButton.styleFrom(
        backgroundColor: action.color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, size: 16, color: action.color),
          const SizedBox(width: 6),
          Text(action.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: action.color)),
        ],
      ),
    );
  }
}
