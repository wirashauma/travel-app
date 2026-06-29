import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shipment_model.dart';
import '../../../core/services/firestore_dijkstra_service.dart';
import '../../../core/services/shipment_service.dart';
import 'shipment_payment_page.dart';
import '../../../shared/widgets/skeleton_loader.dart';
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
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color inputFill = Color(0xFFF4F6F9);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFDC2626);
}

class PackageDeliveryPage extends StatelessWidget {
  const PackageDeliveryPage({super.key});

  static final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu')));
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _Header(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _AddPackageCard(userId: user.uid, userName: user.displayName ?? 'Pengguna'),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.primary, Color(0xFF1A6BB3)],
          ),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengiriman Paket',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Kirim paket dengan armada travel tujuan Anda',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPackageCard extends StatefulWidget {
  final String userId;
  final String userName;

  const _AddPackageCard({required this.userId, required this.userName});

  @override
  State<_AddPackageCard> createState() => _AddPackageCardState();
}

class _AddPackageCardState extends State<_AddPackageCard> with SingleTickerProviderStateMixin {
  // Location
  String? _selectedOrigin;
  String? _selectedDestination;
  List<String> _cities = [];

  // Swap animation
  late AnimationController _swapController;
  late Animation<double> _swapRotation;

  // Sender
  final _senderNameCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();

  // Receiver
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();

  // Package
  String? _selectedPackageSize; // kecil | sedang | besar
  final _descCtrl = TextEditingController();

  bool _loading = false;
  String _paymentMethod = 'cod'; // cod | midtrans
  List<Map<String, dynamic>> _matchingFleets = [];
  String? _selectedFleetId;
  bool _loadingFleets = false;
  Map<String, int> _fleetCapacityPoints = {};

  static const _packageOptions = [
    ('kecil', 'Paket Kecil', 15000, Iconsax.box_2),
    ('sedang', 'Paket Sedang', 30000, Iconsax.box_2),
    ('besar', 'Paket Besar', 50000, Iconsax.box_2),
  ];

  int get _totalPrice {
    if (_selectedPackageSize == null) return 0;
    final option = _packageOptions.firstWhere(
      (o) => o.$1 == _selectedPackageSize,
      orElse: () => ('', '', 0, Iconsax.box_2),
    );
    return option.$3;
  }

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swapRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _swapController, curve: Curves.easeInOutCubic),
    );

    _loadCities();
    // Pre-fill sender from Firebase user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _senderNameCtrl.text = user.displayName ?? '';
      _senderPhoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _swapController.dispose();
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _swapLocations() {
    if (_selectedOrigin == null && _selectedDestination == null) return;
    _swapController.forward(from: 0);
    setState(() {
      final temp = _selectedOrigin;
      _selectedOrigin = _selectedDestination;
      _selectedDestination = temp;
      _selectedFleetId = null;
      _matchingFleets = [];
    });
    _loadMatchingFleets();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await FirestoreDijkstraService.instance.getAllCities();
      if (mounted && cities.isNotEmpty) {
        setState(() => _cities = cities);
        return;
      }
    } catch (_) {}
    // Jika Firestore gagal, biarkan _cities kosong (akan tampil state kosong)
    if (mounted) setState(() => _cities = []);
  }

  Future<void> _loadMatchingFleets() async {
    if (_selectedOrigin == null || _selectedDestination == null) return;
    setState(() {
      _loadingFleets = true;
      _fleetCapacityPoints = {};
    });
    try {
      final fleets = await ShipmentService.getMatchingFleets(_selectedOrigin!, _selectedDestination!);
      
      final Map<String, int> capacityPoints = {};
      await Future.wait(fleets.map((fleet) async {
        final id = fleet['id'] as String? ?? '';
        if (id.isEmpty) return;
        final snap = await FirebaseFirestore.instance
            .collection('shipments')
            .where('fleetId', isEqualTo: id)
            .where('status', whereIn: ['picked_up', 'in_transit'])
            .get();
        
        int points = 0;
        for (final doc in snap.docs) {
          final size = doc.data()['packageSize'] as String? ?? 'kecil';
          if (size == 'kecil') points += 1;
          else if (size == 'sedang') points += 2;
          else if (size == 'besar') points += 4;
        }
        capacityPoints[id] = points;
      }));

      if (mounted) {
        setState(() {
          _matchingFleets = fleets;
          _fleetCapacityPoints = capacityPoints;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _matchingFleets = [];
          _fleetCapacityPoints = {};
        });
      }
    } finally {
      if (mounted) setState(() => _loadingFleets = false);
    }
  }

  Future<void> _submitFromSheet(BuildContext sheetCtx) async {
    if (_selectedOrigin == null ||
        _selectedDestination == null ||
        _selectedFleetId == null ||
        _senderNameCtrl.text.trim().isEmpty ||
        _senderPhoneCtrl.text.trim().isEmpty ||
        _receiverNameCtrl.text.trim().isEmpty ||
        _receiverPhoneCtrl.text.trim().isEmpty ||
        _selectedPackageSize == null ||
        _descCtrl.text.trim().isEmpty) {
      _showSnack('Harap isi semua field');
      return;
    }

    if (_selectedOrigin == _selectedDestination) {
      _showSnack('Kota asal dan tujuan tidak boleh sama');
      return;
    }

    setState(() => _loading = true);
    try {
      final selectedFleet = _matchingFleets.firstWhere(
        (f) => f['id'] == _selectedFleetId,
        orElse: () => <String, dynamic>{},
      );
      final shipment = await ShipmentService.create(ShipmentModel(
        userId: widget.userId,
        userName: widget.userName,
        userPhone: _senderPhoneCtrl.text.trim(),
        origin: _selectedOrigin!,
        destination: _selectedDestination!,
        description: _descCtrl.text.trim(),
        weight: 0,
        status: 'pending',
        createdAt: DateTime.now(),
        senderName: _senderNameCtrl.text.trim(),
        senderPhone: _senderPhoneCtrl.text.trim(),
        receiverName: _receiverNameCtrl.text.trim(),
        receiverPhone: _receiverPhoneCtrl.text.trim(),
        receiverAddress: null,
        packageSize: _selectedPackageSize,
        packagePrice: _totalPrice,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentMethod == 'midtrans' ? 'unpaid' : 'paid',
        fleetId: _selectedFleetId,
        fleetName: selectedFleet['name'] as String?,
      ));

      if (_paymentMethod == 'midtrans') {
        if (!sheetCtx.mounted) return;
        // Navigate to payment page
        final paid = await Navigator.push<bool>(
          sheetCtx,
          MaterialPageRoute(
            builder: (_) => ShipmentPaymentPage(shipment: shipment),
          ),
        );
        if (paid != true) return; // Payment not completed — keep form
      }

      if (!sheetCtx.mounted) return;
      // Close bottom sheet
      Navigator.pop(sheetCtx);

      // Reset form
      setState(() {
        _selectedOrigin = null;
        _selectedDestination = null;
        _selectedFleetId = null;
        _matchingFleets = [];
        _selectedPackageSize = null;
        _paymentMethod = 'cod';
        _senderNameCtrl.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
        _senderPhoneCtrl.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
        _receiverNameCtrl.clear();
        _receiverPhoneCtrl.clear();
        _descCtrl.clear();
      });
      _showSnack('Paket berhasil didaftarkan');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PackageTrackingPage(shipment: shipment),
          ),
        );
      }
    } catch (e) {
      _showSnack('Gagal mendaftarkan paket');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPackageDetailsFormSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Pengiriman',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle, color: _C.textTertiary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: _C.borderLight),

                    // ── Sender ──
                    _sectionHeader(Iconsax.profile_circle, 'Data Pengirim'),
                    const SizedBox(height: 12),
                    _input(_senderNameCtrl, 'Nama Pengirim', Iconsax.user),
                    const SizedBox(height: 12),
                    _input(_senderPhoneCtrl, 'No HP Pengirim', Iconsax.call, keyboardType: TextInputType.phone, maxLength: 12),

                    const SizedBox(height: 20),

                    // ── Receiver ──
                    _sectionHeader(Iconsax.directbox_notif, 'Data Penerima'),
                    const SizedBox(height: 12),
                    _input(_receiverNameCtrl, 'Nama Penerima', Iconsax.user),
                    const SizedBox(height: 12),
                    _input(_receiverPhoneCtrl, 'No HP Penerima', Iconsax.call, keyboardType: TextInputType.phone, maxLength: 12),

                    const SizedBox(height: 20),

                    // ── Payment Method ──
                    _sectionHeader(Iconsax.wallet, 'Metode Pembayaran'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _paymentOption(
                            'cod',
                            'COD (Bayar di Tempat)',
                            Iconsax.money,
                            _C.warning,
                            setSheetState,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _paymentOption(
                            'midtrans',
                            'Midtrans (Online)',
                            Iconsax.card,
                            _C.primary,
                            setSheetState,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Total + Submit ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Biaya',
                                    style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Rp${NumberFormat('#,###', 'id_ID').format(_totalPrice)}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22, fontWeight: FontWeight.w800, color: _C.primary)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : () => _submitFromSheet(context),
                            icon: _loading
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Iconsax.send_2, size: 18),
                            label: Text(
                              _loading ? 'MENGIRIM...' : 'Kirim Paket',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _pickCity(bool isOrigin) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(
        title: isOrigin ? 'Pilih Kota Asal' : 'Pilih Kota Tujuan',
        cities: _cities,
        selectedCity: isOrigin ? _selectedOrigin : _selectedDestination,
        disabledCity: isOrigin ? _selectedDestination : _selectedOrigin,
        onSelect: (city) {
          setState(() {
            if (isOrigin) {
              _selectedOrigin = city;
            } else {
              _selectedDestination = city;
            }
            _selectedFleetId = null;
            _matchingFleets = [];
          });
          _loadMatchingFleets();
        },
      ),
    );
  }

  Widget _buildRouteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: dot-connector line
            SizedBox(
              width: 16,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Origin dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _C.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _C.success.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Connector line
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _C.success.withValues(alpha: 0.4),
                            _C.danger.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Destination dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _C.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _C.danger.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Right: location fields + swap button
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Origin
                  _buildLocationTile(
                    label: 'Kota Asal',
                    value: _selectedOrigin,
                    hint: 'Pilih Kota Asal',
                    onTap: () => _pickCity(true),
                  ),
                  // Swap button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _swapLocations,
                      child: RotationTransition(
                        turns: _swapRotation,
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.primary.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.arrow_swap_horizontal,
                            size: 16,
                            color: _C.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Destination
                  _buildLocationTile(
                    label: 'Kota Tujuan',
                    value: _selectedDestination,
                    hint: 'Pilih Kota Tujuan',
                    onTap: () => _pickCity(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _C.borderLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? hint,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: value != null ? FontWeight.w700 : FontWeight.w400,
                      color: value != null ? _C.textPrimary : _C.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_down_1, size: 16, color: _C.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Iconsax.box_2, 'Ukuran Paket'),
        const SizedBox(height: 12),
        Row(
          children: _packageOptions.map((option) {
            final (key, label, price, icon) = option;
            final isSelected = _selectedPackageSize == key;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPackageSize = key;
                    _selectedFleetId = null;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: option.$1 == 'kecil' ? 0 : 6,
                    right: option.$1 == 'besar' ? 0 : 6,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _C.primary.withValues(alpha: 0.06) : _C.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _C.primary : _C.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Icon(icon, size: 24, color: isSelected ? _C.primary : _C.textTertiary),
                            const SizedBox(height: 6),
                            Text(label,
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? _C.primary : _C.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Rp${NumberFormat('#,###', 'id_ID').format(price)}',
                                style: GoogleFonts.inter(fontSize: 9, color: _C.textTertiary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: _C.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.tick_circle5, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPackageDescInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Iconsax.note_text, 'Deskripsi Paket'),
        const SizedBox(height: 12),
        _input(_descCtrl, 'Contoh: Baju, Sepatu, Dokumen Penting...', Iconsax.document_text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location ──
              _sectionHeader(Iconsax.map_1, 'Lokasi'),
              const SizedBox(height: 12),
              _buildRouteSection(),

              const SizedBox(height: 20),

              // ── Package Size ──
              _buildPackageSizeSelector(),

              const SizedBox(height: 20),

              // ── Description ──
              _buildPackageDescInput(),

              const SizedBox(height: 20),

              // ── Fleet Selection ──
              _buildFleetSelector(),

              if (_selectedFleetId != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showPackageDetailsFormSheet,
                    icon: const Icon(Iconsax.document_text, size: 20),
                    label: Text(
                      'Lanjutkan Pengisian Detail Paket',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon, Color color, [void Function(void Function())? setSheetState]) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        if (setSheetState != null) {
          setSheetState(() {
            _paymentMethod = value;
          });
        }
        setState(() => _paymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : _C.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : _C.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : _C.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : _C.textPrimary)),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Iconsax.tick_circle5, size: 18, color: color),
            ],
          ],
        ),
      ),
    );
  }

  bool _isLargeVehicle(String vehicleType) {
    final vt = vehicleType.toLowerCase();
    return vt.contains('hiace') ||
        vt.contains('elf') ||
        vt.contains('bus') ||
        vt.contains('cargo') ||
        vt.contains('box') ||
        vt.contains('van') ||
        vt.contains('blind') ||
        vt.contains('pickup') ||
        vt.contains('truck') ||
        vt.contains('tronton') ||
        vt.contains('fuso') ||
        vt.contains('l300');
  }

  Widget _buildFleetSelector() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      return const SizedBox.shrink();
    }
    if (_selectedPackageSize == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Iconsax.car, 'Pilih Armada'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.warning.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Silakan pilih ukuran paket terlebih dahulu untuk melihat armada yang tersedia.',
              style: GoogleFonts.inter(fontSize: 12, color: _C.warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Iconsax.car, 'Pilih Armada'),
        const SizedBox(height: 12),
        if (_loadingFleets)
          SkeletonLoader.list(itemCount: 2)
        else if (_matchingFleets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.warning.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Tidak ada armada tersedia untuk rute $_selectedOrigin → $_selectedDestination',
              style: GoogleFonts.inter(fontSize: 12, color: _C.warning),
            ),
          )
        else
          ...List.generate(_matchingFleets.length, (i) {
            final fleet = _matchingFleets[i];
            final id = fleet['id'] as String? ?? '';
            final name = fleet['name'] as String? ?? '';
            final vehicleType = fleet['vehicleType'] as String? ?? '';
            final fOrigin = fleet['origin'] as String? ?? '';
            final fDest = fleet['destination'] as String? ?? '';
            final isSelected = _selectedFleetId == id;

            final isLarge = _isLargeVehicle(vehicleType);
            final maxPoints = isLarge ? 10 : 4;
            final occupiedPoints = _fleetCapacityPoints[id] ?? 0;
            final packagePoints = _selectedPackageSize == 'kecil' ? 1 : (_selectedPackageSize == 'sedang' ? 2 : 4);
            
            final sizeSupported = _selectedPackageSize != 'besar' || isLarge;
            final hasCapacity = occupiedPoints + packagePoints <= maxPoints;
            final isSelectable = sizeSupported && hasCapacity;

            return Padding(
              padding: EdgeInsets.only(bottom: i < _matchingFleets.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: isSelectable ? () => setState(() => _selectedFleetId = id) : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !isSelectable
                        ? const Color(0xFFF8FAFC)
                        : (isSelected ? _C.primary.withValues(alpha: 0.06) : _C.inputFill),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isSelectable
                          ? const Color(0xFFE2E8F0)
                          : (isSelected ? _C.primary : _C.border),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: !isSelectable
                              ? const Color(0xFFE2E8F0)
                              : (isSelected ? _C.primary.withValues(alpha: 0.1) : _C.borderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.car,
                          size: 18,
                          color: !isSelectable
                              ? _C.textTertiary
                              : (isSelected ? _C.primary : _C.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelectable ? _C.textPrimary : _C.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$vehicleType • $fOrigin → $fDest',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _C.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Capacity Point indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelectable
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Kargo Terisi: $occupiedPoints/$maxPoints Poin',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelectable
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSelectable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(
                            !sizeSupported ? 'Ukuran Besar Tidak Didukung' : 'Kapasitas Kargo Penuh',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        )
                      else if (isSelected)
                        const Icon(Iconsax.tick_circle5, size: 18, color: _C.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.textSecondary),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }


  Widget _input(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _C.textPrimary,
      ),
      cursorColor: _C.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 18, color: _C.textTertiary),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        filled: true,
        fillColor: _C.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
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
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
        isDense: true,
        counterText: '',
      ),
    );
  }
}

// ── City Picker Bottom Sheet ──
class _CityPickerSheet extends StatefulWidget {
  final String title;
  final List<String> cities;
  final String? selectedCity;
  final String? disabledCity;
  final ValueChanged<String> onSelect;

  const _CityPickerSheet({
    required this.title,
    required this.cities,
    this.selectedCity,
    this.disabledCity,
    required this.onSelect,
  });

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.cities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(widget.cities);
      } else {
        _filtered = widget.cities
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _C.textPrimary,
              ),
              cursorColor: _C.primary,
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: _C.textTertiary,
                ),
                prefixIcon: const Icon(
                  Iconsax.search_normal_1,
                  size: 18,
                  color: _C.textTertiary,
                ),
                filled: true,
                fillColor: _C.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                  borderSide: const BorderSide(
                    color: _C.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} kota ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _C.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 4, 12, bottomPadding + 16),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final city = _filtered[index];
                final isSelected = city == widget.selectedCity;
                final isDisabled = city == widget.disabledCity;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDisabled
                        ? null
                        : () {
                            widget.onSelect(city);
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _C.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? _C.bg
                                  : _C.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.building,
                              size: 16,
                              color: isDisabled
                                  ? _C.textTertiary
                                  : _C.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              city,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDisabled
                                    ? _C.textTertiary
                                    : _C.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Iconsax.tick_circle5,
                              size: 20,
                              color: _C.primary.withValues(alpha: 0.7),
                            ),
                          if (isDisabled)
                            Text(
                              'Sudah dipilih',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _C.textTertiary,
                              ),
                            ),
                        ],
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
}

// ── Shipment Card ──

