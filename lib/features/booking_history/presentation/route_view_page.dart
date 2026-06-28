import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/models/lng_lat.dart';
import '../../../core/services/city_coordinates_seeder.dart';
import '../../../core/services/firestore_dijkstra_service.dart';
import '../../../core/services/mapbox_directions_service.dart';

// ── Helper: render pin icon ke Uint8List ───────────────
Future<Uint8List> _renderRoutePin(Color color, {double size = 72}) async {
  final w = size * 0.7;
  final h = size;
  final cx = w / 2;
  final r = w / 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(Offset(cx, r), r, Paint()..color = color);
  final path = Path()
    ..moveTo(cx, h)
    ..lineTo(0, r * 1.05)
    ..lineTo(w, r * 1.05)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawCircle(Offset(cx, r), r * 0.4, Paint()..color = Colors.white);
  final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Uint8List> _renderRouteDot(Color color, {double size = 28}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(
      Offset(size / 2, size / 2), size / 2, Paint()..color = color);
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2 - 3,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
  final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFDC2626);
}

class RouteViewPage extends StatefulWidget {
  final String origin;
  final String destination;
  final int? totalPrice;
  final int? passengers;

  const RouteViewPage({
    super.key,
    required this.origin,
    required this.destination,
    this.totalPrice,
    this.passengers,
  });

  @override
  State<RouteViewPage> createState() => _RouteViewPageState();
}

class _RouteViewPageState extends State<RouteViewPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;

  // Koordinasi async: keduanya harus true sebelum draw
  bool _managersReady = false;
  bool _styleLoaded = false;
  bool _elementsDrawn = false;

  bool _isLoading = true;
  String? _error;

  // Pre-rendered icon bytes
  Uint8List? _originBytes;
  Uint8List? _destBytes;
  Uint8List? _dotBytes;

  DijkstraResult? _routeResult;
  List<LngLat> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _preloadIcons();
    _loadRoute();
  }

  Future<void> _preloadIcons() async {
    final og = await _renderRoutePin(const Color(0xFF059669));
    final ds = await _renderRoutePin(Colors.red);
    final dt = await _renderRouteDot(const Color(0xFFF59E0B));
    if (!mounted) return;
    setState(() {
      _originBytes = og;
      _destBytes = ds;
      _dotBytes = dt;
    });
    _tryDraw();
  }

  Future<void> _loadRoute() async {
    try {
      final result = await FirestoreDijkstraService.instance.findCheapestPath(
        widget.origin,
        widget.destination,
      );

      if (result == null) {
        if (mounted) setState(() => _error = 'Rute tidak ditemukan');
        return;
      }

      List<LngLat> pts = [];
      Map<String, Map<String, double>>? coordsMap;
      try {
        coordsMap = await CityCoordinatesSeeder.fetchAllCoordinates();
      } catch (_) {}

      for (final city in result.path) {
        final fc = coordsMap?[city];
        if (fc != null) {
          pts.add(LngLat(fc['lng']!, fc['lat']!));
          continue;
        }
        final lc = CityCoordinatesSeeder.getCoordinates(city);
        if (lc != null) pts.add(LngLat(lc['lng']!, lc['lat']!));
      }

      if (!mounted) return;

      List<LngLat> roadRoute;
      try {
        roadRoute = await MapboxDirectionsService.instance.getRoute(pts);
      } catch (_) {
        roadRoute = pts;
      }

      setState(() {
        _routeResult = result;
        _routePoints = roadRoute;
        _isLoading = false;
      });
      _tryDraw();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat rute';
          _isLoading = false;
        });
      }
    }
  }

  // ── Hanya draw jika semua kondisi terpenuhi ──────────
  void _tryDraw() {
    if (_elementsDrawn) return;
    if (!_managersReady || !_styleLoaded) return;
    if (_routePoints.isEmpty) return;
    if (_originBytes == null || _destBytes == null || _dotBytes == null) return;
    _elementsDrawn = true;
    _buildMapElements();
    _fitBounds();
  }

  Future<void> _initManagers(MapboxMap map) async {
    _mapboxMap = map;
    _pointManager = await map.annotations.createPointAnnotationManager();
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    _managersReady = true;
    _tryDraw();
  }

  Future<void> _buildMapElements() async {
    if (_routePoints.isEmpty) return;

    final coords = _routePoints
        .map((p) => Position(p.lng, p.lat))
        .toList();

    await _polylineManager?.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: coords),
      lineColor: _C.primary.toARGB32(),
      lineWidth: 4.0,
      lineJoin: LineJoin.ROUND,
    ));
    await _polylineManager?.setLineCap(LineCap.ROUND);

    final origin = _routePoints.first;
    await _pointManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(origin.lng, origin.lat)),
      image: _originBytes,
      iconSize: 0.45,
      textField: widget.origin,
      textOffset: [0.0, 2.2],
      textSize: 11.0,
      textColor: _C.textPrimary.toARGB32(),
      textHaloColor: Colors.white.toARGB32(),
      textHaloWidth: 1.5,
    ));

    final dest = _routePoints.last;
    await _pointManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(dest.lng, dest.lat)),
      image: _destBytes,
      iconSize: 0.45,
      textField: widget.destination,
      textOffset: [0.0, 2.2],
      textSize: 11.0,
      textColor: _C.textPrimary.toARGB32(),
      textHaloColor: Colors.white.toARGB32(),
      textHaloWidth: 1.5,
    ));

    for (int i = 1; i < _routePoints.length - 1; i++) {
      final p = _routePoints[i];
      await _pointManager?.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(p.lng, p.lat)),
        image: _dotBytes,
        iconSize: 0.4,
      ));
    }
  }

  LngLat _calcCenter() {
    if (_routePoints.isEmpty) return const LngLat(101.5, -0.5);
    double s = _routePoints.first.lat, n = _routePoints.first.lat;
    double w = _routePoints.first.lng, e = _routePoints.first.lng;
    for (final p in _routePoints) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    return LngLat((w + e) / 2, (s + n) / 2);
  }

  double _calcZoom() {
    if (_routePoints.length < 2) return 5.0;
    double s = _routePoints.first.lat, n = _routePoints.first.lat;
    double w = _routePoints.first.lng, e = _routePoints.first.lng;
    for (final p in _routePoints) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    final latDiff = n - s;
    final lngDiff = e - w;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff <= 0) return 10.0;
    return (12.0 - maxDiff * 1.5).clamp(4.0, 12.0);
  }

  void _fitBounds() {
    if (_routePoints.isEmpty || _mapboxMap == null) return;
    final center = _calcCenter();
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(center.lng, center.lat)),
        zoom: _calcZoom(),
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _AppBar(top: top, origin: widget.origin, destination: widget.destination),
          Expanded(
            child: _isLoading
                ? _LoadingState()
                : _error != null
                    ? _ErrorState(message: _error!)
                    : Stack(
                        children: [
                          _buildMap(),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: _InfoPanel(
                              result: _routeResult!,
                              origin: widget.origin,
                              destination: widget.destination,
                              totalPrice: widget.totalPrice,
                              passengers: widget.passengers,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_routePoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.map, size: 48, color: _C.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Data rute tidak tersedia', style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary)),
          ],
        ),
      );
    }

    final center = _calcCenter();
    return MapWidget(
      key: const ValueKey('route_view_map'),
      mapOptions: MapOptions(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
        constrainMode: ConstrainMode.HEIGHT_ONLY,
        orientation: NorthOrientation.UPWARDS,
      ),
      viewport: CameraViewportState(
        center: Point(coordinates: Position(center.lng, center.lat)),
        zoom: _calcZoom(),
      ),
      styleUri: 'mapbox://styles/mapbox/streets-v12',
      onMapCreated: _initManagers,
      onStyleLoadedListener: (_) {
        if (!_styleLoaded) {
          _styleLoaded = true;
          _tryDraw();
        }
      },
    );
  }

  @override
  void dispose() {
    _mapboxMap?.dispose();
    super.dispose();
  }
}

class _AppBar extends StatelessWidget {
  final double top;
  final String origin;
  final String destination;

  const _AppBar({required this.top, required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4, top + 8, 20, 14),
      decoration: BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, size: 22),
            color: _C.textPrimary,
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rute Perjalanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _C.textPrimary,
                  ),
                ),
                Text(
                  '$origin → $destination',
                  style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final DijkstraResult result;
  final String origin;
  final String destination;
  final int? totalPrice;
  final int? passengers;

  const _InfoPanel({
    required this.result,
    required this.origin,
    required this.destination,
    this.totalPrice,
    this.passengers,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -4)),
          BoxShadow(color: _C.primary.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(color: _C.borderLight, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _routeDot(_C.success, origin),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DashedLine(color: _C.primary.withValues(alpha: 0.3)),
                      ),
                    ),
                    _routeDot(_C.danger, destination),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _statCard(Iconsax.routing_2, '${f.format(result.totalDistance.toInt())} km', 'Jarak'),
                    const SizedBox(width: 10),
                    _statCard(Iconsax.clock, result.formattedDuration, 'Durasi'),
                    const SizedBox(width: 10),
                    if (totalPrice != null)
                      _statCard(Iconsax.wallet_3, _fmtPrice(totalPrice!), 'Total'),
                    if (passengers != null)
                      _statCard(Iconsax.people, '$passengers pax', 'Penumpang'),
                  ],
                ),
                const SizedBox(height: 16),
                if (result.path.length > 2) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.location, size: 16, color: _C.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Melewati: ${result.path.sublist(1, result.path.length - 1).join(' → ')}',
                            style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w500, color: _C.textSecondary,
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
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _routeDot(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _C.white, width: 2)),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textSecondary)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: _C.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(int? p) {
    if (p == null) return '';
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(p)}';
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashes = (constraints.constrainWidth() / 6).floor();
        return Row(
          children: List.generate(dashes, (i) => Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: i.isEven ? color : Colors.transparent,
            ),
          )),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text('Memuat rute...', style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.map, size: 48, color: _C.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(fontSize: 13, color: _C.textTertiary)),
        ],
      ),
    );
  }
}
