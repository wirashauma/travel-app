import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/models/lng_lat.dart';
import '../../../core/services/city_coordinates_seeder.dart';
import '../../../core/services/driver_tracking_service.dart';
import '../../../core/services/mapbox_directions_service.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
}

class DriverTripPage extends StatefulWidget {
  final String fleetId;
  final String fleetName;
  final String origin;
  final String destination;
  final String vehicleType;

  const DriverTripPage({
    super.key,
    required this.fleetId,
    required this.fleetName,
    required this.origin,
    required this.destination,
    required this.vehicleType,
  });

  @override
  State<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends State<DriverTripPage> {
  // Trip status
  late StreamSubscription<DocumentSnapshot> _tripSub;
  String _tripStatus = 'menunggu';
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;
  DateTime? _startTime;
  bool _isLoading = false;
  bool _isEnding = false;

  // Map
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;
  List<LngLat> _routePoints = [];
  bool _mapReady = false;

  // Driver marker
  StreamSubscription<DocumentSnapshot>? _locSub;
  LngLat? _driverPos;
  PointAnnotation? _driverAnnotation;

  // Pre-rendered icons
  Uint8List? _driverIconBytes;
  Uint8List? _originIconBytes;
  Uint8List? _destIconBytes;

  @override
  void initState() {
    super.initState();
    _renderIcons();
    _listenTrip();
    _loadRoute();
  }

  Future<void> _renderIcons() async {
    _driverIconBytes = await _renderCarIcon();
    _originIconBytes = await _renderPin(const Color(0xFF059669));
    _destIconBytes = await _renderPin(Colors.red);
    if (mounted) setState(() {});
  }

  Future<Uint8List> _renderCarIcon({double size = 48}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = _C.primary;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _renderPin(Color color, {double size = 72}) async {
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

  void _listenTrip() {
    _tripSub = FirebaseFirestore.instance
        .collection('fleets')
        .doc(widget.fleetId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data();
      final status = data?['tripStatus'] ?? 'menunggu';
      setState(() => _tripStatus = status);

      if (status == 'berangkat') {
        final ts = data?['tripStartedAt'] as Timestamp?;
        if (ts != null) {
          _startTime = ts.toDate();
          _elapsed = DateTime.now().difference(_startTime!);
        } else {
          _startTime ??= DateTime.now();
        }
        _elapsedTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsed = DateTime.now().difference(_startTime!));
        });
      }
    });

    _locSub = FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(widget.fleetId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final d = doc.data();
      if (d == null) return;
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      _driverPos = LngLat(lng, lat);
      _updateDriverMarker();
    });
  }

  Future<void> _loadRoute() async {
    try {
      final originCoords = CityCoordinatesSeeder.getCoordinates(widget.origin);
      final destCoords = CityCoordinatesSeeder.getCoordinates(widget.destination);
      if (originCoords == null || destCoords == null) return;
      final pts = [
        LngLat(originCoords['lng']!, originCoords['lat']!),
        LngLat(destCoords['lng']!, destCoords['lat']!),
      ];
      final road = await MapboxDirectionsService.instance.getRoute(pts);
      if (mounted) setState(() => _routePoints = road.isNotEmpty ? road : pts);
    } catch (_) {}
  }

  Future<void> _updateDriverMarker() async {
    if (_driverPos == null || _pointManager == null || !_mapReady) return;
    final pos = _driverPos!;
    try {
      if (_driverAnnotation != null) {
        _driverAnnotation!.geometry = Point(coordinates: Position(pos.lng, pos.lat));
        await _pointManager!.update(_driverAnnotation!);
      } else {
        _driverAnnotation = await _pointManager!.create(PointAnnotationOptions(
          geometry: Point(coordinates: Position(pos.lng, pos.lat)),
          image: _driverIconBytes,
          iconSize: 0.4,
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tripSub.cancel();
    _locSub?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTrip() async {
    setState(() => _isLoading = true);
    try {
      await DriverTrackingService.startTracking(fleetId: widget.fleetId);
      if (mounted) {
        _startTime ??= DateTime.now();
        _elapsedTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsed = DateTime.now().difference(_startTime!));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perjalanan dimulai!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memulai: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Akhiri Perjalanan?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Pastikan semua penumpang sudah turun.', style: GoogleFonts.inter(fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(color: _C.textTertiary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger, foregroundColor: _C.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Akhiri', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isEnding = true);
    try {
      await DriverTrackingService.stopTracking();
      if (mounted) {
        _elapsedTimer?.cancel();
        setState(() {
          _tripStatus = 'selesai';
          _isEnding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perjalanan selesai', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengakhiri: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _fmtElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _tripStatus == 'berangkat';
    final isDone = _tripStatus == 'selesai';

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(fleetName: widget.fleetName),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // ── Status card ──
                          _buildStatusCard(isActive, isDone),
                          const SizedBox(height: 16),

                          // ── Map ──
                          if (_routePoints.isNotEmpty)
                            _buildMap(isActive),

                          if (!isDone) ...[
                            const SizedBox(height: 16),

                            // ── Action button ──
                            _buildActionButton(isActive),

                            if (isActive) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Lokasi Anda diperbarui setiap 5 detik\ndan bisa dilihat oleh penumpang.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11, color: _C.textTertiary, height: 1.5),
                              ),
                            ],
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
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

  Widget _buildStatusCard(bool isActive, bool isDone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isActive ? _C.successBg : _C.borderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Iconsax.routing_2 : Iconsax.car,
              size: 36,
              color: isActive ? _C.success : _C.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isDone ? 'Perjalanan Selesai' : isActive ? 'Dalam Perjalanan' : 'Belum Berangkat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDone ? _C.textTertiary : isActive ? _C.success : _C.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Text(
              _fmtElapsed(_elapsed),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '${widget.origin} → ${widget.destination}',
            style: GoogleFonts.inter(fontSize: 13, color: _C.textSecondary),
          ),
          if (widget.vehicleType.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.vehicleType, style: GoogleFonts.inter(fontSize: 12, color: _C.textTertiary)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMap(bool isActive) {
    final pts = _routePoints;
    if (pts.isEmpty) return const SizedBox.shrink();
    final c = _calcCenter();
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          MapWidget(
            key: ValueKey('driver_map_${widget.fleetId}'),
            mapOptions: MapOptions(
              pixelRatio: MediaQuery.of(context).devicePixelRatio,
              constrainMode: ConstrainMode.HEIGHT_ONLY,
              orientation: NorthOrientation.UPWARDS,
            ),
            viewport: CameraViewportState(
              center: Point(coordinates: Position(c.lng, c.lat)),
              zoom: _calcZoom(),
            ),
            styleUri: 'mapbox://styles/mapbox/streets-v12',
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: (_) => _drawRoute(pts),
          ),
          if (isActive && _driverPos != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.location, size: 12, color: _C.success),
                    const SizedBox(width: 4),
                    Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _C.success)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  void _onMapCreated(MapboxMap map) async {
    _pointManager = await map.annotations.createPointAnnotationManager();
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    _mapReady = true;
  }

  Future<void> _drawRoute(List<LngLat> pts) async {
    if (_polylineManager == null || _pointManager == null) return;
    if (_driverIconBytes == null || _originIconBytes == null || _destIconBytes == null) return;

    // Route line
    await _polylineManager!.create(PolylineAnnotationOptions(
      lineColor: _C.primary.toARGB32(),
      lineWidth: 3,
      geometry: LineString(
        coordinates: pts.map((p) => Position(p.lng, p.lat)).toList(),
      ),
    ));

    // Origin
    final origin = pts.first;
    await _pointManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(origin.lng, origin.lat)),
      image: _originIconBytes,
      iconSize: 0.35,
    ));

    // Destination
    final dest = pts.last;
    await _pointManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(dest.lng, dest.lat)),
      image: _destIconBytes,
      iconSize: 0.35,
    ));

    // Driver marker if position exists
    if (_driverPos != null) {
      _driverAnnotation = await _pointManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(_driverPos!.lng, _driverPos!.lat)),
        image: _driverIconBytes,
        iconSize: 0.4,
      ));
    }
  }

  Widget _buildActionButton(bool isActive) {
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isEnding ? null : _endTrip,
          icon: _isEnding
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Icon(Iconsax.close_circle, size: 20),
          label: Text(
            _isEnding ? 'Mengakhiri...' : 'Akhiri Perjalanan',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.danger,
            foregroundColor: _C.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startTrip,
        icon: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Iconsax.routing_2, size: 20),
        label: Text(
          _isLoading ? 'Memulai...' : 'Mulai Perjalanan',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          foregroundColor: _C.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  LngLat _calcCenter() {
    final originCoords = CityCoordinatesSeeder.getCoordinates(widget.origin);
    final destCoords = CityCoordinatesSeeder.getCoordinates(widget.destination);
    if (originCoords == null || destCoords == null) return const LngLat(100.35, -0.9);
    return LngLat(
      (originCoords['lng']! + destCoords['lng']!) / 2,
      (originCoords['lat']! + destCoords['lat']!) / 2,
    );
  }

  double _calcZoom() {
    return 8.0;
  }
}

class _AppBar extends StatelessWidget {
  final String fleetName;
  const _AppBar({required this.fleetName});

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
            child: Text(
              fleetName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800, color: _C.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
