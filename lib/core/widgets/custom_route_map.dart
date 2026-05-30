import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

/// ═══════════════════════════════════════════════════════════════════════
///  CUSTOM ROUTE MAP — Reusable Google Maps Widget
///
///  Menampilkan peta rute Dijkstra dengan:
///  • Custom silver/retro map style (tema Trust Blue)
///  • Polyline biru Trust Blue (width: 4)
///  • Custom Marker hijau (origin) & merah (destination)
///  • Auto-fit camera bounds (LatLngBounds + padding 50)
///  • Loading state handling
///
///  Usage:
///  ```dart
///  CustomRouteMap(
///    routePoints: [LatLng(3.59, 98.67), LatLng(-0.94, 100.41)],
///    originName: 'Medan',
///    destinationName: 'Padang',
///  )
///  ```
/// ═══════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────
//  COLORS
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
}

// ─────────────────────────────────────────────────────────
//  CUSTOM MAP STYLE — Silver/Retro Trust Blue Theme
//  Muted tones, subtle labels, elegant feel.
// ─────────────────────────────────────────────────────────
const String _kMapStyleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadada"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9d6e3"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  }
]
''';

class CustomRouteMap extends StatefulWidget {
  /// List of LatLng points forming the Dijkstra route path.
  final List<LatLng> routePoints;

  /// Display name for origin city.
  final String originName;

  /// Display name for destination city.
  final String destinationName;

  /// Height of the map widget.
  final double height;

  /// Border radius (default 16).
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
  final Completer<GoogleMapController> _controller = Completer();
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _buildMapElements();
  }

  @override
  void didUpdateWidget(covariant CustomRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routePoints != widget.routePoints ||
        oldWidget.originName != widget.originName ||
        oldWidget.destinationName != widget.destinationName) {
      _buildMapElements();
      _fitBounds();
    }
  }

  /// Build markers and polylines from route points.
  Future<void> _buildMapElements() async {
    if (widget.routePoints.isEmpty) return;

    final origin = widget.routePoints.first;
    final destination = widget.routePoints.last;

    // Create custom marker bitmaps
    final originIcon = await _createCustomMarkerBitmap(
      label: widget.originName,
      color: const Color(0xFF059669), // Green
      isOrigin: true,
    );
    final destIcon = await _createCustomMarkerBitmap(
      label: widget.destinationName,
      color: const Color(0xFFDC2626), // Red
      isOrigin: false,
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        icon: originIcon,
        infoWindow: InfoWindow(
          title: widget.originName,
          snippet: 'Titik Keberangkatan',
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: destIcon,
        infoWindow: InfoWindow(
          title: widget.destinationName,
          snippet: 'Titik Tujuan',
        ),
      ),
    };

    // Add transit markers for intermediate points
    for (int i = 1; i < widget.routePoints.length - 1; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('transit_$i'),
          position: widget.routePoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: 'Transit $i'),
        ),
      );
    }

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('dijkstra_route'),
        points: widget.routePoints,
        color: _C.primary, // Trust Blue
        width: 4,
        patterns: [],
        geodesic: true,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    }
  }

  /// Create a custom marker bitmap with colored pin.
  Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required String label,
    required Color color,
    required bool isOrigin,
  }) async {
    // Use default colored markers for reliability
    if (isOrigin) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// Fit camera bounds to show all route points.
  Future<void> _fitBounds() async {
    if (widget.routePoints.isEmpty) return;
    if (!_controller.isCompleted) return;

    final controller = await _controller.future;
    final bounds = _calculateBounds(widget.routePoints);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  /// Calculate LatLngBounds from a list of points.
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  // ── Initial camera — center of Indonesia (Sumatera focus)
  static const _initialCamera = CameraPosition(
    target: LatLng(0.5, 101.5), // Center of Sumatera
    zoom: 5,
  );

  @override
  Widget build(BuildContext context) {
    if (widget.routePoints.isEmpty) {
      return _buildEmptyMap();
    }

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
            // ── Google Map ──
            GoogleMap(
              initialCameraPosition: _initialCamera,
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              liteModeEnabled: false,
              onMapCreated: (GoogleMapController controller) async {
                _controller.complete(controller);
                // Apply custom map style
                await controller.setMapStyle(_kMapStyleJson);
                // Fit bounds after map is created
                if (widget.routePoints.length >= 2) {
                  final bounds = _calculateBounds(widget.routePoints);
                  await Future.delayed(const Duration(milliseconds: 300));
                  await controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 50.0),
                  );
                }
                if (mounted) setState(() => _isMapReady = true);
              },
            ),

            // ── Loading overlay ──
            if (!_isMapReady)
              Container(
                color: _C.bg,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _C.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Memuat peta...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _C.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Route label overlay (top-left) ──
            if (_isMapReady)
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

            // ── Legend (bottom-left) ──
            if (_isMapReady)
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
            Icon(
              Iconsax.map,
              size: 32,
              color: _C.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada data rute',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _C.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.future.then((c) => c.dispose());
    super.dispose();
  }
}
