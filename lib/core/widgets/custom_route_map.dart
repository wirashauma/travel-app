import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/lng_lat.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textTertiary = Color(0xFF94A3B8);
}

// ── Cache global icon bytes (render sekali, pakai banyak) ──
class _IconCache {
  static Uint8List? origin;
  static Uint8List? dest;
  static Uint8List? dot;

  static Future<void> ensure() async {
    if (origin != null) return;
    origin = await _renderPin(const Color(0xFF059669));
    dest = await _renderPin(Colors.red);
    dot = await _renderDot(const Color(0xFFF59E0B));
  }

  static Future<Uint8List> _renderPin(Color color, {double size = 72}) async {
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

  static Future<Uint8List> _renderDot(Color color, {double size = 28}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, Paint()..color = color);
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
}

// ═══════════════════════════════════════════════════════
//  CustomRouteMap — Map widget untuk menampilkan rute
// ═══════════════════════════════════════════════════════
class CustomRouteMap extends StatefulWidget {
  final List<LngLat> cityPoints;
  final List<LngLat>? roadPoints;
  final String originName;
  final String destinationName;
  final double height;
  final double borderRadius;

  const CustomRouteMap({
    super.key,
    required this.cityPoints,
    this.roadPoints,
    required this.originName,
    required this.destinationName,
    this.height = 250,
    this.borderRadius = 16,
  });

  @override
  State<CustomRouteMap> createState() => _CustomRouteMapState();
}

class _CustomRouteMapState extends State<CustomRouteMap> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;

  bool _managersReady = false;
  bool _styleLoaded = false;
  bool _annotationsDrawn = false;

  // ── Build a unique key from route names ──
  static String _routeKey(String origin, String dest) {
    return '$origin>$dest';
  }

  @override
  void initState() {
    super.initState();
    _IconCache.ensure().then((_) {
      if (mounted) _tryDraw();
    });
  }

  @override
  void didUpdateWidget(covariant CustomRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldKey = _routeKey(oldWidget.originName, oldWidget.destinationName);
    final newKey = _routeKey(widget.originName, widget.destinationName);
    
    if (oldKey != newKey) {
      // Re-trigger draw if route cities change
      _annotationsDrawn = false;
      _tryDraw();
    } else if (oldWidget.roadPoints != widget.roadPoints || oldWidget.cityPoints != widget.cityPoints) {
      // Trigger redraw instantly without map recreation if coordinates update
      _annotationsDrawn = false;
      _tryDraw();
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _managersReady = true;
    _tryDraw();
  }

  void _onStyleLoaded(_) {
    if (_styleLoaded) return;
    _styleLoaded = true;
    _tryDraw();
  }

  Future<void> _tryDraw({int attempt = 1}) async {
    if (_annotationsDrawn) return;
    if (!_managersReady || !_styleLoaded) return;
    if (widget.cityPoints.isEmpty) return;
    if (_IconCache.origin == null || _IconCache.dest == null || _IconCache.dot == null) return;
    if (_mapboxMap == null) return;

    _annotationsDrawn = true;

    try {
      // Create managers AFTER style is fully loaded to prevent layer/source eviction by Mapbox
      _pointManager ??= await _mapboxMap!.annotations.createPointAnnotationManager();
      _polylineManager ??= await _mapboxMap!.annotations.createPolylineAnnotationManager();
      
      await _rebuildAnnotations();
      await _fitBounds();
    } catch (e) {
      debugPrint('CustomRouteMap: tryDraw failed on attempt $attempt: $e');
      _annotationsDrawn = false; // Reset to allow retry

      // Retry up to 8 times with exponential backoff if initialization fails
      if (attempt < 8) {
        await Future.delayed(Duration(milliseconds: 100 * attempt));
        if (mounted) {
          _tryDraw(attempt: attempt + 1);
        }
      }
    }
  }

  Future<void> _rebuildAnnotations() async {
    if (widget.cityPoints.isEmpty) return;
    if (_polylineManager == null || _pointManager == null) {
      throw Exception('Polyline or Point Annotation Manager is not initialized.');
    }

    await _polylineManager!.deleteAll();
    await _pointManager!.deleteAll();

    // Polyline
    if (widget.roadPoints != null && widget.roadPoints!.isNotEmpty) {
      final coords =
          widget.roadPoints!.map((p) => Position(p.lng, p.lat)).toList();

      await _polylineManager!.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coords),
        lineColor: _C.primary.toARGB32(),
        lineWidth: 4.5,
        lineJoin: LineJoin.ROUND,
      ));
      await _polylineManager!.setLineCap(LineCap.ROUND);
    }

    // Origin marker
    final origin = widget.cityPoints.first;
    await _pointManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(origin.lng, origin.lat)),
      image: _IconCache.origin,
      iconSize: 0.45,
      textField: widget.originName,
      textOffset: [0.0, 2.2],
      textSize: 11.0,
      textColor: _C.textPrimary.toARGB32(),
      textHaloColor: Colors.white.toARGB32(),
      textHaloWidth: 1.5,
    ));

    // Destination marker
    final dest = widget.cityPoints.last;
    await _pointManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(dest.lng, dest.lat)),
      image: _IconCache.dest,
      iconSize: 0.45,
      textField: widget.destinationName,
      textOffset: [0.0, 2.2],
      textSize: 11.0,
      textColor: _C.textPrimary.toARGB32(),
      textHaloColor: Colors.white.toARGB32(),
      textHaloWidth: 1.5,
    ));

    // Waypoint transit (titik tengah)
    if (widget.cityPoints.length > 2) {
      for (int i = 1; i < widget.cityPoints.length - 1; i++) {
        final p = widget.cityPoints[i];
        await _pointManager!.create(PointAnnotationOptions(
          geometry: Point(coordinates: Position(p.lng, p.lat)),
          image: _IconCache.dot,
          iconSize: 0.4,
        ));
      }
    }

    if (mounted) setState(() {});
  }

  // ── Calc helpers ──────────────────────────────────────
  LngLat _calcCenter(List<LngLat> points) {
    if (points.isEmpty) return const LngLat(117.0, -2.5);
    double s = points.first.lat, n = points.first.lat;
    double w = points.first.lng, e = points.first.lng;
    for (final p in points) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    return LngLat((w + e) / 2, (s + n) / 2);
  }

  double _calcZoom(List<LngLat> points) {
    if (points.length < 2) return 5.0;
    double s = points.first.lat, n = points.first.lat;
    double w = points.first.lng, e = points.first.lng;
    for (final p in points) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    final maxDiff = (n - s) > (e - w) ? (n - s) : (e - w);
    if (maxDiff <= 0) return 11.0;
    // Mathematically calibrated formula to fit route bounds based on geographic distance
    return (12.2 - maxDiff * 5.0).clamp(4.0, 13.0);
  }

  Future<void> _fitBounds() async {
    final pointsToFit = (widget.roadPoints != null && widget.roadPoints!.isNotEmpty)
        ? widget.roadPoints!
        : widget.cityPoints;

    if (pointsToFit.isEmpty || _mapboxMap == null) return;
    
    // Allow Flutter layout tree a brief moment to calculate actual widget sizes
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    try {
      final points = pointsToFit
          .map((p) => Point(coordinates: Position(p.lng, p.lat)))
          .toList();

      final cameraOptions = await _mapboxMap!.cameraForCoordinatesPadding(
        points,
        CameraOptions(),
        MbxEdgeInsets(top: 55.0, left: 55.0, bottom: 55.0, right: 55.0),
        null,
        null,
      );

      await _mapboxMap!.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 800),
      );
    } catch (e) {
      debugPrint('CustomRouteMap: cameraForCoordinatesPadding failed, falling back to math: $e');
      final center = _calcCenter(pointsToFit);
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(center.lng, center.lat)),
          zoom: _calcZoom(pointsToFit),
        ),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cityPoints.isEmpty) {
      return _buildEmptyMap();
    }

    final pointsToFit = (widget.roadPoints != null && widget.roadPoints!.isNotEmpty)
        ? widget.roadPoints!
        : widget.cityPoints;
    final center = _calcCenter(pointsToFit);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            MapWidget(
              key: ValueKey(
                _routeKey(widget.originName, widget.destinationName),
              ),
              mapOptions: MapOptions(
                pixelRatio: MediaQuery.of(context).devicePixelRatio,
                constrainMode: ConstrainMode.HEIGHT_ONLY,
                orientation: NorthOrientation.UPWARDS,
              ),
              viewport: CameraViewportState(
                center: Point(
                    coordinates: Position(center.lng, center.lat)),
                zoom: _calcZoom(pointsToFit),
              ),
              styleUri: 'mapbox://styles/mapbox/streets-v12',
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
            ),

            // ── Label rute (overlay atas) ──────────────
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.routing_2, size: 13, color: _C.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.originName} → ${widget.destinationName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Legenda ───────────────────────────────
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(const Color(0xFF059669), 'Asal'),
                    const SizedBox(width: 10),
                    _legendDot(const Color(0xFFDC2626), 'Tujuan'),
                    if (widget.cityPoints.length > 2) ...[
                      const SizedBox(width: 10),
                      _legendDot(const Color(0xFFF59E0B), 'Transit'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: _C.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMap() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: _C.borderLight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.map,
                size: 32, color: _C.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'Tidak ada data rute',
              style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapboxMap?.dispose();
    super.dispose();
  }
}
