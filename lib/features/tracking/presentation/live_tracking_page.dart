import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
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

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
}

// ──────────────────────────────────────────────────────────
//  Helper: Render icon to Uint8List untuk Mapbox annotation
// ──────────────────────────────────────────────────────────
Future<Uint8List> _renderIconToBytes({
  required Color color,
  required IconData icon,
  double size = 80,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;

  // Lingkaran latar
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  // Ikon di tengah
  final tp = TextPainter(textDirection: ui.TextDirection.ltr);
  tp.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      fontSize: size * 0.52,
      color: Colors.white,
    ),
  );
  tp.layout();
  tp.paint(
    canvas,
    Offset((size - tp.width) / 2, (size - tp.height) / 2),
  );

  final img = await recorder
      .endRecording()
      .toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

// ──────────────────────────────────────────────────────────
//  Pin teardrop sederhana untuk origin / destination
// ──────────────────────────────────────────────────────────
Future<Uint8List> _renderPinToBytes(Color color, {double size = 72}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final h = size;
  final w = size * 0.7;
  final cx = w / 2;
  final r = w / 2;

  final paint = Paint()..color = color;
  // Lingkaran atas
  canvas.drawCircle(Offset(cx, r), r, paint);
  // Segitiga bawah
  final path = Path()
    ..moveTo(cx, h)
    ..lineTo(0, r * 1.1)
    ..lineTo(w, r * 1.1)
    ..close();
  canvas.drawPath(path, paint);
  // Titik putih di tengah
  canvas.drawCircle(Offset(cx, r), r * 0.38, Paint()..color = Colors.white);

  final img = await recorder
      .endRecording()
      .toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

// ──────────────────────────────────────────────────────────
//  LiveTrackingPage
// ──────────────────────────────────────────────────────────
class LiveTrackingPage extends StatefulWidget {
  final String fleetId;
  final String origin;
  final String destination;
  final String fleetName;

  const LiveTrackingPage({
    super.key,
    required this.fleetId,
    required this.origin,
    required this.destination,
    required this.fleetName,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  PointAnnotation? _driverAnnotation;

  String? _error;

  // Flags koordinasi async
  bool _managersReady = false;
  bool _styleLoaded = false;
  bool _routeDrawn = false;

  DijkstraResult? _routeResult;
  List<LngLat> _routePoints = [];

  LngLat? _driverPos;
  LngLat? _pendingDriverPos;
  bool _driverOnline = false;
  String _tripStatus = 'menunggu';
  DateTime? _lastUpdate;

  // Pre-rendered icon bytes
  Uint8List? _originIconBytes;
  Uint8List? _destIconBytes;
  Uint8List? _driverIconBytes;

  late StreamSubscription<DocumentSnapshot> _locationSub;
  late StreamSubscription<DocumentSnapshot> _fleetSub;

  @override
  void initState() {
    super.initState();
    _preloadIcons();
    _loadRoute();
    _listenLocation();
    _listenFleet();
  }

  // ── Pre-render icons ──────────────────────────────────────
  Future<void> _preloadIcons() async {
    final originBytes = await _renderPinToBytes(_C.success);
    final destBytes = await _renderPinToBytes(Colors.red);
    final driverBytes = await _renderIconToBytes(
      color: const Color(0xFF1A6BB5),
      icon: Icons.directions_car,
    );
    if (!mounted) return;
    setState(() {
      _originIconBytes = originBytes;
      _destIconBytes = destBytes;
      _driverIconBytes = driverBytes;
    });
  }

  // ── Load route dari Firestore + Dijkstra + Mapbox Directions ──
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

      if (!mounted) return;

      setState(() {
        _routeResult = result;
        _routePoints = roadRoute;
      });

      // Coba langsung draw jika map sudah siap
      _tryDrawRoute();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat rute: $e');
    }
  }

  // ── Stream lokasi driver ──────────────────────────────────
  void _listenLocation() {
    _locationSub = FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(widget.fleetId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final d = doc.data();
      if (d == null) return;

      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      final online = d['isOnline'] as bool? ?? false;
      final ts = d['updatedAt'] as Timestamp?;

      LngLat? newPos;
      if (lat != null && lng != null) newPos = LngLat(lng, lat);

      setState(() {
        if (newPos != null) _driverPos = newPos;
        _driverOnline = online;
        _lastUpdate = ts?.toDate();
      });

      if (newPos != null) {
        if (_managersReady && _styleLoaded) {
          _updateDriverMarker(newPos);
        } else {
          _pendingDriverPos = newPos;
        }
      }
    });
  }

  // ── Stream status armada ──────────────────────────────────
  void _listenFleet() {
    _fleetSub = FirebaseFirestore.instance
        .collection('fleets')
        .doc(widget.fleetId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final d = doc.data();
      setState(() {
        _tripStatus = d?['tripStatus'] ?? 'menunggu';
      });
    });
  }

  // ── Inisialisasi annotation managers ──────────────────────
  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _pointAnnotationManager =
        await map.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await map.annotations.createPolylineAnnotationManager();
    _managersReady = true;

    // Setelah managers siap, coba draw jika style sudah loaded
    _tryDrawRoute();
    _tryDrawPendingDriver();
  }

  // ── Style loaded ──────────────────────────────────────────
  void _onStyleLoaded(_) {
    if (_styleLoaded) return;
    _styleLoaded = true;

    _tryDrawRoute();
    _tryDrawPendingDriver();
  }

  // ── Draw route jika semua kondisi terpenuhi ───────────────
  void _tryDrawRoute() {
    if (_routeDrawn) return;
    if (!_managersReady || !_styleLoaded) return;
    if (_routePoints.isEmpty) return;
    if (_originIconBytes == null || _destIconBytes == null) return;
    _routeDrawn = true;
    _drawRoute();
  }

  // ── Draw pending driver position ─────────────────────────
  void _tryDrawPendingDriver() {
    if (!_managersReady || !_styleLoaded) return;
    final pos = _pendingDriverPos;
    if (pos != null) {
      _pendingDriverPos = null;
      _updateDriverMarker(pos);
    }
  }

  // ── Gambar polyline + marker origin/destination ───────────
  Future<void> _drawRoute() async {
    if (_routePoints.isEmpty) return;
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null) return;

    // Polyline
    final coords = _routePoints.map((p) => Position(p.lng, p.lat)).toList();
    await _polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coords),
        lineColor: _C.primary.toARGB32(),
        lineWidth: 5.0,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await _polylineAnnotationManager!.setLineCap(LineCap.ROUND);

    // Origin marker
    final origin = _routePoints.first;
    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(origin.lng, origin.lat)),
        image: _originIconBytes,
        iconSize: 0.5,
        textField: widget.origin,
        textOffset: [0.0, 2.0],
        textSize: 11.0,
        textColor: _C.textPrimary.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.5,
      ),
    );

    // Destination marker
    final dest = _routePoints.last;
    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(dest.lng, dest.lat)),
        image: _destIconBytes,
        iconSize: 0.5,
        textField: widget.destination,
        textOffset: [0.0, 2.0],
        textSize: 11.0,
        textColor: _C.textPrimary.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.5,
      ),
    );

    _fitBounds();

    // Kalau ada pending driver dari sebelum route drawn
    _tryDrawPendingDriver();
  }

  // ── Update/create marker sopir (realtime) ─────────────────
  Future<void> _updateDriverMarker(LngLat pos) async {
    if (_pointAnnotationManager == null) return;

    if (_driverAnnotation != null) {
      // Update posisi yang ada
      _driverAnnotation!.geometry =
          Point(coordinates: Position(pos.lng, pos.lat));
      await _pointAnnotationManager!.update(_driverAnnotation!);
    } else {
      // Buat marker baru dengan icon mobil
      final imgBytes = _driverIconBytes;
      _driverAnnotation = await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(pos.lng, pos.lat)),
          image: imgBytes,
          iconSize: 0.55,
          textField: widget.fleetName,
          textOffset: [0.0, 2.0],
          textSize: 11.0,
          textColor: const Color(0xFF1A6BB5).toARGB32(),
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.5,
        ),
      );
    }
    _fitBounds();
  }

  // ── Hitung center ─────────────────────────────────────────
  LngLat _calcCenter(List<LngLat> pts) {
    if (pts.isEmpty) return const LngLat(101.5, -0.5);
    double s = pts.first.lat, n = pts.first.lat;
    double w = pts.first.lng, e = pts.first.lng;
    for (final p in pts) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    return LngLat((w + e) / 2, (s + n) / 2);
  }

  // ── Hitung zoom ───────────────────────────────────────────
  double _calcZoom(List<LngLat> pts) {
    if (pts.length < 2) return 5.0;
    double s = pts.first.lat, n = pts.first.lat;
    double w = pts.first.lng, e = pts.first.lng;
    for (final p in pts) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    final maxDiff = (n - s) > (e - w) ? (n - s) : (e - w);
    if (maxDiff <= 0) return 10.0;
    return (12.0 - maxDiff * 1.5).clamp(4.0, 12.0);
  }

  // ── Fit camera ke semua titik ─────────────────────────────
  void _fitBounds() {
    if (_mapboxMap == null || _routePoints.isEmpty) return;
    final all = List<LngLat>.from(_routePoints);
    if (_driverPos != null) all.add(_driverPos!);
    final center = _calcCenter(all);
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(center.lng, center.lat)),
        zoom: _calcZoom(all),
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  @override
  void dispose() {
    _locationSub.cancel();
    _fleetSub.cancel();
    _mapboxMap?.dispose();
    super.dispose();
  }

  // ── Posisi default awal camera (tengah Indonesia) ─────────
  LngLat get _initialCenter {
    if (_routePoints.isNotEmpty) return _calcCenter(_routePoints);
    return const LngLat(117.0, -2.5); // tengah Indonesia
  }

  double get _initialZoom {
    if (_routePoints.isNotEmpty) return _calcZoom(_routePoints);
    return 4.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              fleetName: widget.fleetName,
              tripStatus: _tripStatus,
            ),
            Expanded(
              child: _error != null
                  ? _ErrorView(message: _error!)
                  : Stack(
                      children: [
                        // ── Mapbox selalu tampil, route + marker dioverlay setelah siap ──
                        MapWidget(
                          key: const ValueKey('tracking_map'),
                          mapOptions: MapOptions(
                            pixelRatio:
                                MediaQuery.of(context).devicePixelRatio,
                            constrainMode: ConstrainMode.HEIGHT_ONLY,
                            orientation: NorthOrientation.UPWARDS,
                          ),
                          viewport: CameraViewportState(
                            center: Point(
                              coordinates: Position(
                                _initialCenter.lng,
                                _initialCenter.lat,
                              ),
                            ),
                            zoom: _initialZoom,
                          ),
                          styleUri: 'mapbox://styles/mapbox/streets-v12',
                          onMapCreated: _onMapCreated,
                          onStyleLoadedListener: _onStyleLoaded,
                        ),

                        // ── Loading overlay saat route belum siap ──
                        if (_routePoints.isEmpty && _error == null)
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _C.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Memuat rute...',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _C.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // ── Driver online pulse indicator ──
                        if (_driverOnline)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _PulseIndicator(),
                          ),

                        // ── Status panel bawah ──
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _StatusPanel(
                            tripStatus: _tripStatus,
                            driverOnline: _driverOnline,
                            driverPos: _driverPos,
                            lastUpdate: _lastUpdate,
                            result: _routeResult,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  Error view
// ────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 56, color: _C.textTertiary),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: _C.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  Pulse indicator untuk driver online
// ────────────────────────────────────────────────────────
class _PulseIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _C.success,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.success.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}

// ────────────────────────────────────────────────────────
//  App Bar
// ────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String fleetName;
  final String tripStatus;
  const _AppBar({required this.fleetName, required this.tripStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 14),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lacak Armada',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                Text(
                  fleetName,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _C.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tripStatus == 'berangkat'
                  ? _C.success.withValues(alpha: 0.1)
                  : _C.borderLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tripStatus == 'berangkat' ? 'Berangkat' : 'Menunggu',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tripStatus == 'berangkat'
                    ? _C.success
                    : _C.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  Status Panel bawah
// ────────────────────────────────────────────────────────
class _StatusPanel extends StatelessWidget {
  final String tripStatus;
  final bool driverOnline;
  final LngLat? driverPos;
  final DateTime? lastUpdate;
  final DijkstraResult? result;

  const _StatusPanel({
    required this.tripStatus,
    required this.driverOnline,
    this.driverPos,
    this.lastUpdate,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id_ID');
    final isActive = tripStatus == 'berangkat' || driverOnline;

    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _C.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? _C.success : _C.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isActive
                            ? 'Armada sedang dalam perjalanan'
                            : 'Armada belum mulai',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _C.success : _C.textTertiary,
                        ),
                      ),
                    ),
                    if (lastUpdate != null)
                      Text(
                        'Update: ${DateFormat('HH:mm').format(lastUpdate!.toLocal())}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _C.textTertiary,
                        ),
                      ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat(
                        Iconsax.routing_2,
                        '${f.format(result!.totalDistance.toInt())} km',
                        'Jarak',
                      ),
                      const SizedBox(width: 8),
                      _stat(
                        Iconsax.clock,
                        result!.formattedDuration,
                        'Durasi',
                      ),
                      const SizedBox(width: 8),
                      _stat(
                        Iconsax.map_1,
                        '${result!.path.length} kota',
                        'Rute',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: _C.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, color: _C.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
