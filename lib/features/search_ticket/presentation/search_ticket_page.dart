import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unused_field, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/services/dijkstra_service.dart';
import '../../../core/widgets/custom_route_map.dart';
import '../../seat_selection/presentation/seat_selection_page.dart';

// ─────────────────────────────────────────────────────────
//  COLOR PALETTE — Trust Blue
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryLight = Color(0xFF1A6BB5);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color orange = Color(0xFFF97316);
}

// ═══════════════════════════════════════════════════════════
//  SEARCH TICKET PAGE — Dijkstra + Real-time Firestore
//
//  Alur:
//  1. User pilih Kota Asal & Kota Tujuan (dari DijkstraService)
//  2. Jalankan DijkstraService.getShortestRoute()
//  3. Tampilkan rute optimal secara visual
//  4. StreamBuilder ke `fleets` → filter armada yang melayani
//     kota-kota dalam rute Dijkstra
//  5. Tap armada → SeatSelectionPage
// ═══════════════════════════════════════════════════════════
class SearchTicketPage extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final DateTime? initialDate;
  final int? initialPassengers;

  const SearchTicketPage({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    this.initialDate,
    this.initialPassengers,
  });

  @override
  State<SearchTicketPage> createState() => _SearchTicketPageState();
}

class _SearchTicketPageState extends State<SearchTicketPage> {
  // ── Form State ────────────────────────────────
  String? _originCity;
  String? _destinationCity;
  DateTime _selectedDate = DateTime.now();
  int _passengers = 1;

  // ── Dijkstra Result ───────────────────────────
  DijkstraRouteResult? _routeResult;
  bool _hasSearched = false;

  // ── Cities list ───────────────────────────────
  late final List<String> _cities;

  // ── Koordinat kota-kota Sumatera Barat ────────
  static const Map<String, LatLng> _cityCoordinates = {
    'Padang': LatLng(-0.9471, 100.4172),
    'Bukittinggi': LatLng(-0.3055, 100.3691),
    'Payakumbuh': LatLng(-0.2261, 100.6320),
    'Batusangkar': LatLng(-0.4586, 100.6180),
    'Padang Panjang': LatLng(-0.4710, 100.4164),
    'Solok': LatLng(-0.7994, 100.6553),
    'Sawahlunto': LatLng(-0.6837, 100.7789),
    'Pariaman': LatLng(-0.6245, 100.1185),
    'Pesisir Selatan': LatLng(-1.3571, 100.5740),
    'Pasaman': LatLng(0.2013, 99.9999),
    'Pasaman Barat': LatLng(0.3014, 99.6218),
    'Sijunjung': LatLng(-0.6980, 100.9450),
    'Dharmasraya': LatLng(-1.0590, 101.3670),
    'Solok Selatan': LatLng(-1.2375, 101.2690),
    'Lubuk Basung': LatLng(-0.3103, 100.0787),
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAFBFD),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _cities = DijkstraService.instance.getAllCities();

    // ── Pre-fill dari Beranda & auto-search ──
    if (widget.initialOrigin != null) {
      _originCity = widget.initialOrigin;
    }
    if (widget.initialDestination != null) {
      _destinationCity = widget.initialDestination;
    }
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialPassengers != null) {
      _passengers = widget.initialPassengers!;
    }

    // Otomatis jalankan Dijkstra jika kedua kota sudah terisi
    if (_originCity != null &&
        _destinationCity != null &&
        _originCity != _destinationCity) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleSearch());
    }
  }

  // ── Swap origin & destination ─────────────────
  void _swapCities() {
    if (_originCity == null && _destinationCity == null) return;
    setState(() {
      final temp = _originCity;
      _originCity = _destinationCity;
      _destinationCity = temp;
      _hasSearched = false;
      _routeResult = null;
    });
  }

  // ── Run Dijkstra Search ───────────────────────
  void _handleSearch() {
    if (_originCity == null || _destinationCity == null) {
      _showSnack('Pilih kota asal dan tujuan terlebih dahulu');
      return;
    }
    if (_originCity == _destinationCity) {
      _showSnack('Kota asal dan tujuan tidak boleh sama');
      return;
    }

    final result = DijkstraService.instance.getRouteDetail(
      _originCity!,
      _destinationCity!,
    );

    setState(() {
      _routeResult = result;
      _hasSearched = true;
    });
  }

  // ── Date Picker ───────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _C.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _C.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _C.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Re-trigger search if already searched
        if (_hasSearched) _handleSearch();
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: _C.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ── Helpers ────────────────────────────────────
  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ═══ HEADER + SEARCH FORM ════════════════
          _buildHeader(topPadding),

          // ═══ CONTENT AREA ════════════════════════
          Expanded(
            child: _hasSearched
                ? (_routeResult != null
                      ? _buildResultContent()
                      : _buildNoRoute())
                : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  HEADER — Search Form
  // ─────────────────────────────────────────────────
  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.arrow_left,
                    size: 20,
                    color: _C.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Cari Tiket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Origin & Destination ──
          Row(
            children: [
              Expanded(
                child: _buildCitySelector(
                  label: 'Asal',
                  city: _originCity,
                  icon: Iconsax.location,
                  iconColor: _C.success,
                  isOrigin: true,
                ),
              ),
              const SizedBox(width: 8),
              // Swap button
              GestureDetector(
                onTap: _swapCities,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.arrow_swap_horizontal,
                    size: 18,
                    color: _C.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCitySelector(
                  label: 'Tujuan',
                  city: _destinationCity,
                  icon: Iconsax.location_tick,
                  iconColor: _C.error,
                  isOrigin: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date + Passengers + Search ──
          Row(
            children: [
              // Date
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _C.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.calendar_1,
                          size: 18,
                          color: _C.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtDate(_selectedDate),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Passengers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_passengers > 1) {
                          setState(() => _passengers--);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 16,
                          color: _C.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_passengers',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_passengers < 5) {
                          setState(() => _passengers++);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: _C.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Search button
              GestureDetector(
                onTap: _handleSearch,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Iconsax.search_normal_1,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── City Selector Chip ──
  Widget _buildCitySelector({
    required String label,
    required String? city,
    required IconData icon,
    required Color iconColor,
    required bool isOrigin,
  }) {
    return GestureDetector(
      onTap: () => _showCityPicker(isOrigin: isOrigin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _C.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                city ?? label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: city != null ? FontWeight.w600 : FontWeight.w400,
                  color: city != null ? _C.textPrimary : _C.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Iconsax.arrow_down_1, size: 14, color: _C.textTertiary),
          ],
        ),
      ),
    );
  }

  // ── City Picker BottomSheet ──
  void _showCityPicker({required bool isOrigin}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(
        title: isOrigin ? 'Pilih Kota Asal' : 'Pilih Kota Tujuan',
        cities: _cities,
        selectedCity: isOrigin ? _originCity : _destinationCity,
        disabledCity: isOrigin ? _destinationCity : _originCity,
        onSelect: (city) {
          setState(() {
            if (isOrigin) {
              _originCity = city;
            } else {
              _destinationCity = city;
            }
            _hasSearched = false;
            _routeResult = null;
          });
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  INITIAL STATE — Before Search
  // ─────────────────────────────────────────────────
  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.map_1,
              size: 64,
              color: _C.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Cari Tiket Perjalanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih kota asal dan tujuan, lalu tekan tombol cari\nuntuk menemukan rute terbaik.',
              style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  NO ROUTE FOUND
  // ─────────────────────────────────────────────────
  Widget _buildNoRoute() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.map,
              size: 64,
              color: _C.warning.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Rute Tidak Ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada jalur antara $_originCity dan $_destinationCity.\nCoba pilih kota lain.',
              style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  RESULT CONTENT — Route + Fleet List
  // ─────────────────────────────────────────────────
  Widget _buildResultContent() {
    final result = _routeResult!;
    // Estimate price per km (Rp 600/km avg Sumatera Barat travel rate)
    final estimatedPrice = result.totalDistanceKm * 600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Route Visual Card ──
          _buildRouteCard(
            result,
            estimatedPrice,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

          const SizedBox(height: 16),

          // ── Google Maps Dijkstra Polyline ──
          _buildDijkstraMap(result)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 20),

          // ── Section Title ──
          Text(
            'Armada Tersedia',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'Armada yang melayani rute ini (real-time)',
            style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 14),

          // ── Fleet List — StreamBuilder ──
          _buildFleetStream(result, estimatedPrice),
        ],
      ),
    );
  }

  // ── Dijkstra Google Maps Widget ──
  Widget _buildDijkstraMap(DijkstraRouteResult result) {
    // Map city names in the Dijkstra path to LatLng coordinates
    final routePoints = <LatLng>[];
    for (final city in result.path) {
      final coord = _cityCoordinates[city];
      if (coord != null) routePoints.add(coord);
    }

    if (routePoints.length < 2) return const SizedBox.shrink();

    return CustomRouteMap(
      routePoints: routePoints,
      originName: result.path.first,
      destinationName: result.path.last,
      height: 220,
      borderRadius: 16,
    );
  }

  // ── Route Card ──
  Widget _buildRouteCard(DijkstraRouteResult result, int estimatedPrice) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: _C.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _C.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.routing_2,
                    size: 18,
                    color: _C.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rute Optimal (Dijkstra)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.path.length - 1} segmen · ${result.totalDistanceKm} km',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _C.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Route Path Visual ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Column(
              children: [
                for (int i = 0; i < result.path.length; i++) ...[
                  Row(
                    children: [
                      // Dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? _C.success
                              : i == result.path.length - 1
                              ? _C.error
                              : _C.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (i == 0
                                          ? _C.success
                                          : i == result.path.length - 1
                                          ? _C.error
                                          : _C.orange)
                                      .withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.path[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: (i == 0 || i == result.path.length - 1)
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                        ),
                      ),
                      if (i == 0) _buildChip('Asal', _C.success),
                      if (i == result.path.length - 1)
                        _buildChip('Tujuan', _C.error),
                      if (i > 0 && i < result.path.length - 1)
                        _buildChip('Transit', _C.orange),
                    ],
                  ),
                  // Connector line
                  if (i < result.path.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _C.primary.withValues(alpha: 0.2),
                                  _C.primary.withValues(alpha: 0.08),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),

          // ── Stats Row ──
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildStatItem(
                  Iconsax.routing,
                  '${result.totalDistanceKm} km',
                  'Jarak',
                ),
                _buildStatDivider(),
                _buildStatItem(
                  Iconsax.clock,
                  result.formattedDuration,
                  'Durasi',
                ),
                _buildStatDivider(),
                _buildStatItem(
                  Iconsax.money_4,
                  _fmtPrice(estimatedPrice),
                  'Est. Harga',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: _C.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: _C.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ─────────────────────────────────────────────────
  //  FLEET STREAM — Real-time Firestore
  // ─────────────────────────────────────────────────
  Widget _buildFleetStream(DijkstraRouteResult result, int estimatedPrice) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fleets')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: _C.primary,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat armada...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _C.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return _infoBox(
            icon: Iconsax.warning_2,
            title: 'Gagal Memuat',
            subtitle: '${snapshot.error}',
            color: _C.error,
          );
        }

        // Show all fleets — each _FleetCard computes real-time
        // seat availability from bookings StreamBuilder.
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _infoBox(
            icon: Iconsax.bus,
            title: 'Tidak Ada Armada',
            subtitle:
                'Belum ada armada tersedia untuk $_passengers penumpang.\nCoba kurangi jumlah atau pilih tanggal lain.',
            color: _C.warning,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _FleetCard(
              docId: doc.id,
              data: data,
              index: i,
              passengers: _passengers,
              estimatedPrice: estimatedPrice,
              routeResult: result,
              date: _selectedDate,
              onBook: () => _goToSeatSelection(
                fleetId: doc.id,
                fleetName: data['name'] as String? ?? '',
                totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 0,
                routeResult: result,
                estimatedPrice: estimatedPrice,
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 100 + (i * 60)),
              duration: 400.ms,
            );
          },
        );
      },
    );
  }

  // ── Navigate to Seat Selection ──
  void _goToSeatSelection({
    required String fleetId,
    required String fleetName,
    required int totalSeats,
    required DijkstraRouteResult routeResult,
    required int estimatedPrice,
  }) {
    final totalPrice = estimatedPrice * _passengers;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionPage(
          fleetId: fleetId,
          fleetName: fleetName,
          totalSeats: totalSeats,
          origin: _originCity!,
          destination: _destinationCity!,
          date: _selectedDate,
          passengers: _passengers,
          routePrice: estimatedPrice,
          routeSummary: routeResult.routeSummary,
          totalDistance: routeResult.totalDistanceKm.toDouble(),
          totalDurationMinutes: routeResult.estimatedDurationMinutes,
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FLEET CARD WIDGET
// ═══════════════════════════════════════════════════════════
class _FleetCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final int index;
  final int passengers;
  final int estimatedPrice;
  final DijkstraRouteResult routeResult;
  final DateTime date;
  final VoidCallback onBook;

  const _FleetCard({
    required this.docId,
    required this.data,
    required this.index,
    required this.passengers,
    required this.estimatedPrice,
    required this.routeResult,
    required this.date,
    required this.onBook,
  });

  String _fmtPrice(int price) {
    final f = NumberFormat('#,###', 'id_ID');
    return 'Rp ${f.format(price)}';
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Armada';
    final imageUrl = data['imageUrl'] as String?;
    final totalSeats = (data['totalSeats'] as num?)?.toInt() ?? 0;
    final description = data['description'] as String? ?? '';
    final totalPrice = estimatedPrice * passengers;

    // ── Real-time seat availability from bookings ──
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('fleetId', isEqualTo: docId)
          .where('status', whereIn: ['pending', 'paid', 'validated', 'used'])
          .snapshots(),
      builder: (context, bookingSnap) {
        int bookedSeatCount = 0;
        if (bookingSnap.hasData) {
          for (final doc in bookingSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            bookedSeatCount += (d['seatsBooked'] as num?)?.toInt() ?? 0;
          }
        }
        final availableSeats = (totalSeats - bookedSeatCount).clamp(
          0,
          totalSeats,
        );
        final isBookable = availableSeats >= passengers;

        return Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderLight, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fleet Image / Initials ──
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _getInitials(name),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _C.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(name),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Seats badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: availableSeats > 5
                                  ? _C.success.withValues(alpha: 0.08)
                                  : _C.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$availableSeats/$totalSeats kursi',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: availableSeats > 5
                                    ? _C.success
                                    : _C.warning,
                              ),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                description,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: _C.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price + Book button row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fmtPrice(totalPrice),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _C.primary,
                                  ),
                                ),
                                Text(
                                  '$passengers penumpang',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: _C.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: isBookable ? onBook : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _C.textTertiary
                                    .withValues(alpha: 0.15),
                                disabledForegroundColor: _C.textTertiary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(
                                isBookable ? 'Pesan' : 'Penuh',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, // StreamBuilder builder
    ); // StreamBuilder
  }
}

// ═══════════════════════════════════════════════════════════
//  CITY PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════
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
  late List<String> _filteredCities;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(widget.cities);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCities = List.from(widget.cities);
      } else {
        _filteredCities = widget.cities
            .where((c) => c.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
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
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: _C.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14, color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: _C.textTertiary,
                ),
                prefixIcon: const Icon(
                  Iconsax.search_normal,
                  size: 18,
                  color: _C.textTertiary,
                ),
                filled: true,
                fillColor: _C.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _filteredCities.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ditemukan',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _C.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _filteredCities.length,
                    itemBuilder: (_, i) {
                      final city = _filteredCities[i];
                      final isSelected = city == widget.selectedCity;
                      final isDisabled = city == widget.disabledCity;
                      return ListTile(
                        leading: Icon(
                          Iconsax.location,
                          size: 18,
                          color: isDisabled
                              ? _C.textTertiary.withValues(alpha: 0.3)
                              : isSelected
                              ? _C.primary
                              : _C.textTertiary,
                        ),
                        title: Text(
                          city,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDisabled
                                ? _C.textTertiary.withValues(alpha: 0.4)
                                : _C.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Iconsax.tick_circle5,
                                size: 20,
                                color: _C.primary,
                              )
                            : null,
                        onTap: isDisabled
                            ? null
                            : () {
                                widget.onSelect(city);
                                Navigator.pop(context);
                              },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
