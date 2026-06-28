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
  final List<LngLat> routePoints;
  final String originName;
  final String destinationName;
  final double height;
  final double borderRadius;

  const CustomRouteMap({
    super.key,
    required this.routePoints,
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

  @override
  void initState() {
    super.initState();
    _IconCache.ensure();
  }

  @override
  void didUpdateWidget(covariant CustomRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routePoints != widget.routePoints ||
        oldWidget.originName != widget.originName ||
        oldWidget.destinationName != widget.destinationName) {
      _annotationsDrawn = false;
      _tryDraw();
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _pointManager = await map.annotations.createPointAnnotationManager();
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    _managersReady = true;
    _tryDraw();
  }

  void _onStyleLoaded(_) {
    if (_styleLoaded) return;
    _styleLoaded = true;
    _tryDraw();
  }

  void _tryDraw() {
    if (_annotationsDrawn) return;
    if (!_managersReady || !_styleLoaded) return;
    if (widget.routePoints.isEmpty) return;
    if (_IconCache.origin == null || _IconCache.dest == null || _IconCache.dot == null) return;
    _annotationsDrawn = true;
    _rebuildAnnotations();
    _fitBounds();
  }

  Future<void> _rebuildAnnotations() async {
    if (widget.routePoints.isEmpty) return;
    await _polylineManager?.deleteAll();
    await _pointManager?.deleteAll();

    final coords =
        widget.routePoints.map((p) => Position(p.lng, p.lat)).toList();

    // Polyline
    await _polylineManager?.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: coords),
      lineColor: _C.primary.toARGB32(),
      lineWidth: 4.5,
      lineJoin: LineJoin.ROUND,
    ));
    await _polylineManager?.setLineCap(LineCap.ROUND);

    // Origin marker
    final origin = widget.routePoints.first;
    await _pointManager?.create(PointAnnotationOptions(
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
    final dest = widget.routePoints.last;
    await _pointManager?.create(PointAnnotationOptions(
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
    if (widget.routePoints.length > 2) {
      for (int i = 1; i < widget.routePoints.length - 1; i++) {
        final p = widget.routePoints[i];
        await _pointManager?.create(PointAnnotationOptions(
          geometry: Point(coordinates: Position(p.lng, p.lat)),
          image: _IconCache.dot,
          iconSize: 0.4,
        ));
      }
    }

    if (mounted) setState(() {});
  }

  // ── Calc helpers ──────────────────────────────────────
  LngLat _calcCenter() {
    if (widget.routePoints.isEmpty) return const LngLat(117.0, -2.5);
    double s = widget.routePoints.first.lat, n = widget.routePoints.first.lat;
    double w = widget.routePoints.first.lng, e = widget.routePoints.first.lng;
    for (final p in widget.routePoints) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    return LngLat((w + e) / 2, (s + n) / 2);
  }

  double _calcZoom() {
    if (widget.routePoints.length < 2) return 5.0;
    double s = widget.routePoints.first.lat, n = widget.routePoints.first.lat;
    double w = widget.routePoints.first.lng, e = widget.routePoints.first.lng;
    for (final p in widget.routePoints) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    final maxDiff = (n - s) > (e - w) ? (n - s) : (e - w);
    if (maxDiff <= 0) return 10.0;
    return (12.0 - maxDiff * 1.5).clamp(4.0, 12.0);
  }

  void _fitBounds() {
    if (widget.routePoints.isEmpty || _mapboxMap == null) return;
    final center = _calcCenter();
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(center.lng, center.lat)),
        zoom: _calcZoom(),
      ),
      MapAnimationOptions(duration: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routePoints.isEmpty) {
      return _buildEmptyMap();
    }

    final center = _calcCenter();

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
            // ── Map tampil langsung, tanpa loading overlay ──
            MapWidget(
              key: const ValueKey('route_map'),
              mapOptions: MapOptions(
                pixelRatio: MediaQuery.of(context).devicePixelRatio,
                constrainMode: ConstrainMode.HEIGHT_ONLY,
                orientation: NorthOrientation.UPWARDS,
              ),
              viewport: CameraViewportState(
                center: Point(
                    coordinates: Position(center.lng, center.lat)),
                zoom: _calcZoom(),
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
                    if (widget.routePoints.length > 2) ...[
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
