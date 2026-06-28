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
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFEF4444);
}

enum _TrackingStep {
  submitted,    // Diajukan
  confirmed,    // Dikonfirmasi
  inTransit,    // Dalam Pengiriman
  delivered,    // Selesai
  cancelled,    // Dibatalkan
}

class PackageTrackingPage extends StatefulWidget {
  final ShipmentModel shipment;
  const PackageTrackingPage({super.key, required this.shipment});

  @override
  State<PackageTrackingPage> createState() => _PackageTrackingPageState();
}

class _PackageTrackingPageState extends State<PackageTrackingPage> {
  late ShipmentModel _shipment;

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
  }

  _TrackingStep _currentStep() {
    switch (_shipment.status) {
      case 'pending':
        return _TrackingStep.submitted;
      case 'confirmed':
        return _TrackingStep.confirmed;
      case 'picked_up':
      case 'in_transit':
        return _TrackingStep.inTransit;
      case 'delivered':
      case 'confirmed_by_passenger':
        return _TrackingStep.delivered;
      case 'cancelled':
        return _TrackingStep.cancelled;
      default:
        return _TrackingStep.submitted;
    }
  }

  int _stepIndex(_TrackingStep step) {
    switch (step) {
      case _TrackingStep.submitted: return 0;
      case _TrackingStep.confirmed: return 1;
      case _TrackingStep.inTransit: return 2;
      case _TrackingStep.delivered: return 3;
      case _TrackingStep.cancelled: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStep();
    final isCancelled = currentStep == _TrackingStep.cancelled;
    final activeIndex = isCancelled ? 0 : _stepIndex(currentStep);

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<ShipmentModel>(
        stream: ShipmentService.shipmentStream(_shipment.id!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _shipment = snapshot.data!;
          }
          return CustomScrollView(
            slivers: [
              _Header(shipment: _shipment),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(currentStep),
                      const SizedBox(height: 20),
                      _buildTimeline(currentStep, isCancelled, activeIndex),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildDetailCard(),
                      const SizedBox(height: 24),
                      _buildActionButton(currentStep),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(_TrackingStep step) {
    final isCancelled = step == _TrackingStep.cancelled;
    final isDelivered = step == _TrackingStep.delivered;
    Color bannerColor;
    String bannerLabel;
    IconData bannerIcon;

    if (isDelivered) {
      bannerColor = _C.success;
      bannerLabel = 'Paket sudah selesai';
      bannerIcon = Iconsax.tick_circle;
    } else if (isCancelled) {
      bannerColor = _C.danger;
      bannerLabel = 'Paket dibatalkan';
      bannerIcon = Iconsax.close_circle;
    } else {
      bannerColor = _C.primary;
      bannerLabel = 'Paket dalam proses';
      bannerIcon = Iconsax.clock;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(bannerIcon, size: 24, color: bannerColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerLabel,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: bannerColor)),
                const SizedBox(height: 2),
                Text(_statusDescription(step),
                    style: GoogleFonts.inter(fontSize: 12, color: _C.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildTimeline(_TrackingStep currentStep, bool isCancelled, int activeIndex) {
    if (isCancelled) {
      return _buildCancelledTimeline();
    }

    final steps = [
      ('Diajukan', 'Paket telah diajukan', Iconsax.document_text, _shipment.createdAt),
      ('Dikonfirmasi', 'Paket dikonfirmasi oleh admin', Iconsax.tick_circle,
          _shipment.updatedAt),
      ('Dalam Pengiriman', 'Paket sedang dalam perjalanan', Iconsax.truck_fast,
          _shipment.pickedUpAt ?? _shipment.updatedAt),
      ('Selesai', 'Paket sudah diterima', Iconsax.location_tick,
          _shipment.deliveredAt ?? (_shipment.status == 'confirmed_by_passenger' ? _shipment.updatedAt : null)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Pengiriman',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final (label, desc, icon, date) = steps[i];
            final isActive = i <= activeIndex;
            final isLast = i == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive ? _C.primary : _C.borderLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              isActive && i < activeIndex ? Iconsax.tick_circle : icon,
                              size: 14,
                              color: isActive ? Colors.white : _C.textTertiary,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: i < activeIndex ? _C.primary : _C.borderLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? _C.textPrimary : _C.textTertiary)),
                          const SizedBox(height: 2),
                          Text(desc,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: isActive ? _C.textSecondary : _C.textTertiary)),
                          if (date != null && isActive) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(date),
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w500, color: _C.primary.withValues(alpha: 0.7)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildCancelledTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Pengiriman',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _C.danger,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Center(
                  child: Icon(Iconsax.close_circle, size: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dibatalkan',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600, color: _C.danger)),
                    const SizedBox(height: 2),
                    Text('Paket ini telah dibatalkan',
                        style: GoogleFonts.inter(fontSize: 12, color: _C.textSecondary)),
                    if (_shipment.updatedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(_shipment.updatedAt!),
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w500, color: _C.danger.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Pengiriman',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          const SizedBox(height: 16),
          _infoRow(Iconsax.map_1, 'Asal', _shipment.origin),
          const SizedBox(height: 10),
          _infoRow(Iconsax.map, 'Tujuan', _shipment.destination),
          const SizedBox(height: 10),
          _infoRow(Iconsax.box_2, 'Deskripsi', _shipment.description),
          if (_shipment.fleetName != null) ...[
            const SizedBox(height: 10),
            _infoRow(Iconsax.car, 'Armada', _shipment.fleetName!),
          ],
          if (_shipment.packageSize != null && _shipment.packagePrice != null) ...[
            const SizedBox(height: 10),
            _infoRow(Iconsax.weight, 'Ukuran', _packageLabel()),
            const SizedBox(height: 10),
            _infoRow(Iconsax.money, 'Biaya',
                'Rp${NumberFormat('#,###', 'id_ID').format(_shipment.packagePrice)}'),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Penerima',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPrimary)),
          const SizedBox(height: 16),
          if (_shipment.senderName != null)
            _infoRow(Iconsax.profile_circle, 'Pengirim', _shipment.senderName!),
          if (_shipment.receiverName != null) ...[
            const SizedBox(height: 10),
            _infoRow(Iconsax.directbox_notif, 'Penerima', _shipment.receiverName!),
          ],
          if (_shipment.receiverPhone != null) ...[
            const SizedBox(height: 10),
            _infoRow(Iconsax.call, 'No HP Penerima', _shipment.receiverPhone!),
          ],
          if (_shipment.receiverAddress != null) ...[
            const SizedBox(height: 10),
            _infoRow(Iconsax.location, 'Alamat', _shipment.receiverAddress!, maxLines: 3),
          ],
          if (_shipment.paymentMethod != null) ...[
            const SizedBox(height: 10),
            _infoRow(
              Iconsax.wallet,
              'Pembayaran',
              _shipment.paymentMethod == 'cod' ? 'COD (Bayar di Tempat)' : 'Midtrans (Online)',
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildActionButton(_TrackingStep step) {
    if (step != _TrackingStep.delivered && step != _TrackingStep.confirmed) {
      return const SizedBox.shrink();
    }
    if (step == _TrackingStep.delivered) {
      return const SizedBox.shrink();
    }
    if (_shipment.status == 'confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _confirmDelivered(),
          icon: const Icon(Iconsax.tick_circle, size: 18),
          label: Text('Konfirmasi Paket Diterima',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.success,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmDelivered() async {
    try {
      await ShipmentService.updateStatus(_shipment.id!, 'confirmed_by_passenger');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paket dikonfirmasi sudah diterima',
                style: GoogleFonts.inter(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengonfirmasi',
                style: GoogleFonts.inter(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _packageLabel() {
    switch (_shipment.packageSize) {
      case 'kecil': return 'Kecil';
      case 'sedang': return 'Sedang';
      case 'besar': return 'Besar';
      default: return '-';
    }
  }

  String _statusDescription(_TrackingStep step) {
    switch (step) {
      case _TrackingStep.submitted:
        return 'Menunggu konfirmasi dari admin';
      case _TrackingStep.confirmed:
        return 'Paket telah dikonfirmasi dan akan segera diproses';
      case _TrackingStep.inTransit:
        return 'Paket sedang dalam perjalanan menuju tujuan';
      case _TrackingStep.delivered:
        return 'Paket sudah sampai di tujuan';
      case _TrackingStep.cancelled:
        return 'Pengiriman paket ini dibatalkan';
    }
  }

  Widget _infoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: _C.textTertiary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: _C.textPrimary),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final ShipmentModel shipment;
  const _Header({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      backgroundColor: _C.primary,
      elevation: 0,
      expandedHeight: 140,
      collapsedHeight: top + kToolbarHeight,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.fromLTRB(20, top + kToolbarHeight + 8, 20, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.primary, Color(0xFF1A6BB3)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(shipment.description,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${shipment.origin} → ${shipment.destination}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
