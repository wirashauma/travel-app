// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/models/lng_lat.dart';
import '../../../core/services/city_coordinates_seeder.dart';
import '../../../core/services/firestore_dijkstra_service.dart';
import '../../../core/services/mapbox_directions_service.dart';
import '../../../core/widgets/custom_route_map.dart';
import '../../select_fleet/presentation/select_fleet_page.dart';

// ─────────────────────────────────────────────────────────
//  COLORS — Trust Blue / Navy / Teal / Clean Slate
// ─────────────────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color teal = Color(0xFF0D9488);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════
//  SEARCH RESULT PAGE — Real-time Dijkstra from Firestore
// ═══════════════════════════════════════════════════════════
class SearchResultPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;

  const SearchResultPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  // ── State ──────────────────────────────────────
  DijkstraResult? _result;
  List<LngLat> _routeLatLngs = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadRoute();
  }

  // ── Data Loading with Firestore Dijkstra ──
  Future<void> _loadRoute() async {
    try {
      final result = await FirestoreDijkstraService.instance.findCheapestPath(
        widget.origin,
        widget.destination,
      );
      // Convert city names → LngLat for the map
      List<LngLat> latLngs = [];
      if (result != null) {
        // 1) Coba lokal dulu (0ms, tanpa network)
        final missingCities = <String>[];
        for (final cityName in result.path) {
          final localCoords = CityCoordinatesSeeder.getCoordinates(cityName);
          if (localCoords != null) {
            latLngs.add(LngLat(localCoords['lng']!, localCoords['lat']!));
          } else {
            missingCities.add(cityName);
          }
        }
        // 2) Fallback Firestore hanya untuk kota yang tidak ada di lokal
        if (missingCities.isNotEmpty) {
          try {
            final coordsMap = await CityCoordinatesSeeder.fetchAllCoordinates();
            for (final cityName in missingCities) {
              final fc = coordsMap[cityName];
              if (fc != null) {
                latLngs.add(LngLat(fc['lng']!, fc['lat']!));
              }
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;

      // 3) Tampilkan rute lurus DULU, upgrade ke road route async
      setState(() {
        _result = result;
        _routeLatLngs = latLngs;
        _isLoading = false;
      });

      // 4) Upgrade ke road-following route di background
      try {
        final roadRoute = await MapboxDirectionsService.instance.getRoute(latLngs);
        if (mounted) setState(() => _routeLatLngs = roadRoute);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────
  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(price)}';
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isToday = DateUtils.isSameDay(widget.date, DateTime.now());
    final dateLabel = isToday
        ? 'Hari Ini'
        : DateFormat('EEE, d MMM yyyy', 'id_ID').format(widget.date);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ═══ APP BAR ════════════════════════════
          _buildAppBar(topPadding, dateLabel),

          // ═══ CONTENT ═══════════════════════════
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _hasError
                ? _buildErrorState()
                : (_result == null || _result!.path.isEmpty)
                ? _buildEmptyState()
                : _buildRouteFound(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────
  Widget _buildAppBar(double topPadding, String dateLabel) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 16),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.origin}  →  ${widget.destination}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 13,
                      color: _C.textTertiary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _C.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Iconsax.people,
                      size: 13,
                      color: _C.textTertiary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.passengers} penumpang',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _C.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─────────────────────────────────────────────────
  //  ROUTE FOUND — Dijkstra Result + Fleet CTA
  // ─────────────────────────────────────────────────
  Widget _buildRouteFound() {
    final result = _result!;
    final isDirect = result.path.length <= 2;
    final transitCount = result.path.length - 2;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // ── Route Summary Card ──
          _buildRouteSummary(result, isDirect, transitCount)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, duration: 400.ms),

          const SizedBox(height: 16),

          // ── Google Maps — Dijkstra Route Visualization ──
          if (_routeLatLngs.length >= 2)
            CustomRouteMap(
                  routePoints: _routeLatLngs,
                  originName: widget.origin,
                  destinationName: widget.destination,
                  height: 250,
                )
                .animate()
                .fadeIn(delay: 120.ms, duration: 450.ms)
                .slideY(begin: 0.05, delay: 120.ms, duration: 450.ms),

          if (_routeLatLngs.length >= 2) const SizedBox(height: 16),

          // ── Route Path Visualization ──
          _buildRoutePathCard(result)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.05, delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // ── Price Breakdown Card ──
          _buildPriceCard(result)
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.05, delay: 350.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── CTA — Pilih Armada ──
          _buildFleetCTA()
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.08, delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  // ── Route Summary Card ───────────────────────────
  Widget _buildRouteSummary(
    DijkstraResult result,
    bool isDirect,
    int transitCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route type label
          Row(
            children: [
              Icon(Iconsax.routing_2, size: 16, color: _C.primary),
              const SizedBox(width: 6),
              Text(
                isDirect ? 'Rute Langsung' : 'Rute via Transit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Full path
          Text(
            result.routeSummary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Info chips
          Row(
            children: [
              _infoChip(
                Iconsax.routing_2,
                '${result.totalDistance.toStringAsFixed(0)} km',
                _C.primary,
              ),
              const SizedBox(width: 10),
              _infoChip(Iconsax.clock, result.formattedDuration, _C.teal),
              const SizedBox(width: 10),
              _infoChip(
                Iconsax.arrow_swap_horizontal,
                isDirect ? 'Langsung' : '$transitCount transit',
                isDirect ? _C.success : _C.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Route Path Visualization ─────────────────────
  Widget _buildRoutePathCard(DijkstraResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.map, size: 16, color: _C.primary),
              const SizedBox(width: 8),
              Text(
                'Jalur Perjalanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Path steps
          ...List.generate(result.path.length, (i) {
            final city = result.path[i];
            final isFirst = i == 0;
            final isLast = i == result.path.length - 1;

            return Column(
              children: [
                Row(
                  children: [
                    // Dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst
                            ? _C.teal
                            : isLast
                            ? _C.primary
                            : _C.warning,
                        border: Border.all(
                          color:
                              (isFirst
                                      ? _C.teal
                                      : isLast
                                      ? _C.primary
                                      : _C.warning)
                                  .withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        city,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: (isFirst || isLast)
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Asal',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _C.teal,
                          ),
                        ),
                      ),
                    if (isLast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tujuan',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _C.primary,
                          ),
                        ),
                      ),
                    if (!isFirst && !isLast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Transit',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _C.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                // Connector line
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Row(
                      children: [
                        Container(width: 2, height: 28, color: _C.borderLight),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Price Card ────────────────────────────────────
  Widget _buildPriceCard(DijkstraResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.money_recive, size: 16, color: _C.primary),
              const SizedBox(width: 8),
              Text(
                'Rincian Biaya Rute',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _priceRow('Biaya rute per kursi', _formatPrice(result.totalPrice)),
          const SizedBox(height: 8),
          _priceRow('Jumlah penumpang', '${widget.passengers} orang'),
          const SizedBox(height: 8),
          _priceRow(
            'Jarak tempuh',
            '${result.totalDistance.toStringAsFixed(0)} km',
          ),
          const SizedBox(height: 8),
          _priceRow('Estimasi waktu', result.formattedDuration),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 14),
            color: _C.borderLight,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Estimasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatPrice(result.totalPrice * widget.passengers),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _C.textTertiary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── CTA Button — Navigate to Fleet Selection ─────
  Widget _buildFleetCTA() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => SelectFleetPage(
                origin: widget.origin,
                destination: widget.destination,
                date: widget.date,
                passengers: widget.passengers,
                routePrice: _result!.totalPrice,
                routeSummary: _result!.routeSummary,
                totalDistance: _result!.totalDistance,
                totalDurationMinutes: _result!.totalDurationMinutes,
              ),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.car, size: 18),
            const SizedBox(width: 10),
            const Text('Pilih Armada'),
            const SizedBox(width: 6),
            const Icon(Iconsax.arrow_right_3, size: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  SHIMMER LOADING STATE
  // ─────────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8ECF1),
        highlightColor: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  EMPTY STATE — Route Not Found
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _C.textTertiary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Iconsax.route_square,
                    size: 42,
                    color: _C.textTertiary.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Rute Tidak Ditemukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tidak ditemukan rute yang menghubungkan\n${widget.origin} dan ${widget.destination}.\nSilakan coba kota lain.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: _C.textTertiary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.search_normal, size: 16),
                  label: const Text('Ubah Pencarian'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          delay: 200.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─────────────────────────────────────────────────
  //  ERROR STATE
  // ─────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _C.textTertiary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Iconsax.warning_2,
                size: 42,
                color: _C.textTertiary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Gagal memuat data rute.\nPeriksa koneksi internet Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: _C.textTertiary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadRoute();
              },
              icon: const Icon(Iconsax.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}
