import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/data/indonesia_regions.dart';
import '../../../core/data/indonesia_routes.dart';
import '../../../core/models/route_model.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
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
//  MANAGE DIJKSTRA ROUTES PAGE
// ═══════════════════════════════════════════════════════════
class ManageDijkstraRoutesPage extends StatefulWidget {
  const ManageDijkstraRoutesPage({super.key});

  @override
  State<ManageDijkstraRoutesPage> createState() =>
      _ManageDijkstraRoutesPageState();
}

class _ManageDijkstraRoutesPageState extends State<ManageDijkstraRoutesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Local editable copies from Indonesia data ──
  late List<CityNode> _cities;
  late List<RouteEdge> _routes;

  // ── Tab 1 — City form state ──
  final _cityNameCtrl = TextEditingController();
  final _cityProvinceCtrl = TextEditingController();
  RegionType _cityType = RegionType.kota;
  String _citySearch = '';

  // ── Tab 2 — Route form state ──
  String? _selectedFromId;
  String? _selectedToId;
  final _distanceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _routeSearch = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cities = List.from(IndonesiaRegions.all);
    _routes = List.from(IndonesiaRoutes.all);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _cityNameCtrl.dispose();
    _cityProvinceCtrl.dispose();
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── helpers ───
  String _cityName(String id) {
    try {
      return _cities.firstWhere((c) => c.id == id).fullName;
    } catch (_) {
      return id;
    }
  }

  final _fmt = NumberFormat('#,###', 'id_ID');

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
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
          'Manajemen Rute (Dijkstra)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _C.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _C.white,
          indicatorWeight: 3,
          labelColor: _C.white,
          unselectedLabelColor: _C.white.withValues(alpha: 0.55),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Master Kota (Node)'),
            Tab(text: 'Jalur & Harga (Edge)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCityTab(),
          _buildRouteTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1 — Master Kota (Node)
  // ═══════════════════════════════════════════════════════
  Widget _buildCityTab() {
    final filtered = _citySearch.isEmpty
        ? _cities
        : _cities.where((c) {
            final q = _citySearch.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.province.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // ── Form Card ──────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Kota Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _cityNameCtrl,
                hint: 'Nama Kota / Kabupaten',
                icon: Iconsax.building,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: _cityProvinceCtrl,
                hint: 'Provinsi',
                icon: Iconsax.map_1,
              ),
              const SizedBox(height: 10),
              // Region type toggle
              Row(
                children: [
                  _typeChip('Kota', RegionType.kota),
                  const SizedBox(width: 8),
                  _typeChip('Kabupaten', RegionType.kabupaten),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Iconsax.add, size: 18),
                    label: Text(
                      'Simpan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: _addCity,
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04),

        // ── Search ──────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchBar(
            hint: 'Cari kota / provinsi…',
            onChanged: (v) => setState(() => _citySearch = v),
          ),
        ),

        // ── Stats badge ──────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filtered.length} kota',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── City List ──────
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final c = filtered[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.type == RegionType.kota
                            ? _C.primary.withValues(alpha: 0.08)
                            : _C.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        c.type == RegionType.kota
                            ? Iconsax.building_3
                            : Iconsax.tree,
                        size: 16,
                        color: c.type == RegionType.kota
                            ? _C.primary
                            : _C.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.province,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: _C.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _deleteCity(c),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _C.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Iconsax.trash, size: 15, color: _C.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2 — Jalur & Harga (Edge)
  // ═══════════════════════════════════════════════════════
  Widget _buildRouteTab() {
    final filtered = _routeSearch.isEmpty
        ? _routes
        : _routes.where((r) {
            final q = _routeSearch.toLowerCase();
            return _cityName(r.fromCityId).toLowerCase().contains(q) ||
                _cityName(r.toCityId).toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // ── Form Card ──────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Jalur Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              // From / To dropdowns
              Row(
                children: [
                  Expanded(
                    child: _cityDropdown(
                      label: 'Kota Asal',
                      value: _selectedFromId,
                      onChanged: (v) => setState(() => _selectedFromId = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _cityDropdown(
                      label: 'Kota Tujuan',
                      value: _selectedToId,
                      onChanged: (v) => setState(() => _selectedToId = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _distanceCtrl,
                      hint: 'Jarak (km)',
                      icon: Iconsax.routing_2,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      controller: _durationCtrl,
                      hint: 'Waktu (mnt)',
                      icon: Iconsax.timer_1,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _priceCtrl,
                      hint: 'Harga (Rp)',
                      icon: Iconsax.money_send,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.teal,
                      foregroundColor: _C.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Iconsax.add, size: 18),
                    label: Text(
                      'Simpan Jalur',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: _addRoute,
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04),

        // ── Search ──────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchBar(
            hint: 'Cari jalur…',
            onChanged: (v) => setState(() => _routeSearch = v),
          ),
        ),

        // ── Stats badge ──────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filtered.length} jalur',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.teal,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Route List ──────
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final r = filtered[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cities
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _cityName(r.fromCityId),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Iconsax.arrow_right_3,
                              size: 14, color: _C.textTertiary),
                        ),
                        Icon(Iconsax.location_tick,
                            size: 14, color: _C.teal),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _cityName(r.toCityId),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _deleteRoute(r),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _C.errorBg,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(Iconsax.trash,
                                size: 13, color: _C.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Details
                    Row(
                      children: [
                        _routeTag(
                          Iconsax.routing_2,
                          '${r.distance.toStringAsFixed(0)} km',
                          _C.primary,
                        ),
                        const SizedBox(width: 10),
                        _routeTag(
                          Iconsax.timer_1,
                          '${r.duration} mnt',
                          _C.warning,
                        ),
                        const SizedBox(width: 10),
                        _routeTag(
                          Iconsax.money_send,
                          'Rp ${_fmt.format(r.price)}',
                          _C.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13.5, color: _C.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
        prefixIcon: Icon(icon, size: 18, color: _C.textTertiary),
        filled: true,
        fillColor: _C.borderLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border.withValues(alpha: 0.4)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13, color: _C.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.textHint),
          prefixIcon: Icon(Iconsax.search_normal_1,
              size: 18, color: _C.textTertiary),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _typeChip(String label, RegionType type) {
    final selected = _cityType == type;
    return GestureDetector(
      onTap: () => setState(() => _cityType = type),
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.primary : _C.borderLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _C.primary : _C.border.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? _C.white : _C.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _cityDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
        filled: true,
        fillColor: _C.borderLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.border.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _C.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
      ),
      menuMaxHeight: 350,
      style: GoogleFonts.inter(fontSize: 12.5, color: _C.textPrimary),
      items: _cities
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.fullName,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _C.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _routeTag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════
  void _addCity() {
    final name = _cityNameCtrl.text.trim();
    final province = _cityProvinceCtrl.text.trim();
    if (name.isEmpty || province.isEmpty) {
      _snack('Nama kota dan provinsi wajib diisi', isError: true);
      return;
    }
    final id = name.toLowerCase().replaceAll(' ', '_');
    if (_cities.any((c) => c.id == id)) {
      _snack('Kota "$name" sudah ada', isError: true);
      return;
    }
    setState(() {
      _cities.insert(
        0,
        CityNode(
          id: id,
          name: name,
          latitude: 0,
          longitude: 0,
          type: _cityType,
          province: province,
        ),
      );
    });
    _cityNameCtrl.clear();
    _cityProvinceCtrl.clear();
    _snack('Kota "$name" berhasil ditambahkan');
  }

  void _deleteCity(CityNode city) async {
    final confirmed = await _confirmDelete(city.fullName);
    if (confirmed != true) return;
    setState(() {
      _cities.remove(city);
      _routes.removeWhere(
          (r) => r.fromCityId == city.id || r.toCityId == city.id);
    });
    _snack('${city.fullName} dihapus');
  }

  void _addRoute() {
    if (_selectedFromId == null || _selectedToId == null) {
      _snack('Pilih kota asal dan tujuan', isError: true);
      return;
    }
    if (_selectedFromId == _selectedToId) {
      _snack('Kota asal dan tujuan tidak boleh sama', isError: true);
      return;
    }
    final dist = double.tryParse(_distanceCtrl.text) ?? 0;
    final dur = int.tryParse(_durationCtrl.text) ?? 0;
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    if (dist <= 0 || dur <= 0 || price <= 0) {
      _snack('Jarak, waktu, dan harga harus > 0', isError: true);
      return;
    }
    setState(() {
      _routes.insert(
        0,
        RouteEdge(
          fromCityId: _selectedFromId!,
          toCityId: _selectedToId!,
          distance: dist,
          duration: dur,
          price: price,
        ),
      );
    });
    _distanceCtrl.clear();
    _durationCtrl.clear();
    _priceCtrl.clear();
    _snack('Jalur baru berhasil ditambahkan');
  }

  void _deleteRoute(RouteEdge route) async {
    final from = _cityName(route.fromCityId);
    final to = _cityName(route.toCityId);
    final confirmed = await _confirmDelete('$from → $to');
    if (confirmed != true) return;
    setState(() => _routes.remove(route));
    _snack('Jalur $from → $to dihapus');
  }

  // ── Snackbar helper ───
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: isError ? _C.error : _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _confirmDelete(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.errorBg,
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.trash, color: _C.error, size: 26),
        ),
        title: Text(
          'Hapus Data?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus "$name"? Tindakan ini tidak dapat dibatalkan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.textSecondary,
              side: BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: _C.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Hapus',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
