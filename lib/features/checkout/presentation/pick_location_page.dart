import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:http/http.dart' as http;

import '../../../core/services/city_coordinates_seeder.dart';

class _C {
  static const Color primary = Color(0xFF0F4C81);
  static const Color bg = Color(0xFFFAFBFD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color danger = Color(0xFFEF4444);
}

class PickLocationPage extends StatefulWidget {
  final String originCity;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const PickLocationPage({
    super.key,
    required this.originCity,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  late double _latitude;
  late double _longitude;
  late final TextEditingController _addressController;
  bool _isLocating = false;

  // Search Address State Variables
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Pin & Camera Sync State Variables
  Timer? _cameraDebounceTimer;
  bool _isProgrammaticMovement = false;

  // Pin Animation & Cache Variables
  late final AnimationController _pinAnimationController;
  bool _addressNeedsUpdate = false;
  Widget? _cachedMapWidget;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _pinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Setup initial coordinates
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitude = widget.initialLatitude!;
      _longitude = widget.initialLongitude!;
    } else {
      final coords = CityCoordinatesSeeder.getCoordinates(widget.originCity);
      if (coords != null) {
        _latitude = coords['lat']!;
        _longitude = coords['lng']!;
      } else {
        // Fallback to Padang
        _latitude = -0.9471;
        _longitude = 100.4172;
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _cameraDebounceTimer?.cancel();
    _pinAnimationController.dispose();
    _mapboxMap?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar(
          'Layanan lokasi dinonaktifkan. Silakan aktifkan GPS Anda.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Izin akses lokasi ditolak.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Izin lokasi ditolak permanen di pengaturan.');
      return;
    }

    setState(() => _isLocating = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      if (_mapboxMap != null) {
        _isProgrammaticMovement = true;
        await _mapboxMap!.setCamera(CameraOptions(
          center: Point(coordinates: Position(_longitude, _latitude)),
          zoom: 16.0,
        ));
      }

      await _reverseGeocode(_latitude, _longitude);
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil lokasi saat ini: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    // 1. Primary: OpenStreetMap Nominatim reverse geocoding API
    try {
      final osmUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=id');
      final osmRes = await http.get(
        osmUrl,
        headers: {
          'User-Agent': 'e_travel_app',
        },
      ).timeout(const Duration(seconds: 4));

      if (osmRes.statusCode == 200) {
        final data = jsonDecode(osmRes.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _addressController.text = displayName;
          });
          return; // Success, skip Mapbox fallback
        }
      }
    } catch (e) {
      debugPrint('OSM Nominatim reverse geocode error: $e');
    }

    // 2. Fallback: Mapbox Geocoding API
    try {
      final mapboxUrl = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
          '?access_token=pk.eyJ1IjoiY29kZWluMjEiLCJhIjoiY21jMW53a21iMGV3ajJrczd2bTR3b25mciJ9.VufbKuZE1e18mU4zCbvVyw'
          '&limit=1&types=address,poi,place,neighborhood');
      final res = await http.get(mapboxUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final placeName = features.first['place_name'] as String?;
          if (placeName != null) {
            setState(() {
              _addressController.text = placeName;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
    });

    try {
      // 1. Try Nominatim (OpenStreetMap) first for high accuracy POIs in Indonesia
      final url = Uri.parse('https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json'
          '&limit=6'
          '&countrycodes=id');

      final res = await http.get(url, headers: {
        'User-Agent': 'e_travel_app_flutter_client',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List?;
        if (data != null && data.isNotEmpty) {
          if (mounted) {
            setState(() {
              _searchResults = data.map((item) {
                final displayName = item['display_name'] as String? ?? '';
                final name = item['name'] as String? ?? '';
                final title =
                    name.isNotEmpty ? name : displayName.split(',').first;

                final double lat =
                    double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
                final double lon =
                    double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

                return {
                  'text': title,
                  'place_name': displayName,
                  'center': [lon, lat],
                };
              }).toList();
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim search error, falling back to Mapbox: $e');
    }

    // 2. Fallback to Mapbox Geocoding if Nominatim is empty or fails
    try {
      final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
          '?access_token=pk.eyJ1IjoiY29kZWluMjEiLCJhIjoiY21jMW53a21iMGV3ajJrczd2bTR3b25mciJ9.VufbKuZE1e18mU4zCbvVyw'
          '&country=id'
          '&proximity=$_longitude,$_latitude'
          '&limit=6');

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List?;
        if (features != null) {
          if (mounted) {
            setState(() {
              _searchResults = features
                  .map((f) => {
                        'text': f['text'] as String? ?? '',
                        'place_name': f['place_name'] as String? ?? '',
                        'center': f['center'] as List? ?? [],
                      })
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Fallback Mapbox Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> item) async {
    final center = item['center'] as List?;
    if (center != null && center.length >= 2) {
      final lng = center[0] as num;
      final lat = center[1] as num;

      _latitude = lat.toDouble();
      _longitude = lng.toDouble();

      if (_mapboxMap != null) {
        _isProgrammaticMovement = true;
        await _mapboxMap!.setCamera(CameraOptions(
          center: Point(coordinates: Position(_longitude, _latitude)),
          zoom: 16.0,
        ));
      }

      setState(() {
        _addressController.text = item['place_name'] ?? '';
        _searchResults = [];
        _searchController.clear();
      });

      _searchFocusNode.unfocus();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _C.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onCameraChange(CameraChangedEventData data) {
    final center = data.cameraState.center;
    final pos = center.coordinates;
    _longitude = pos.lng.toDouble();
    _latitude = pos.lat.toDouble();

    if (_isProgrammaticMovement) {
      _isProgrammaticMovement = false;
      _pinAnimationController.value = 0.0; // Immediately land
      setState(() {
        _addressNeedsUpdate = false;
      });
      return;
    }

    // Manual camera drag: lift pin up, mark address as needing updates
    if (!_addressNeedsUpdate) {
      setState(() {
        _addressNeedsUpdate = true;
      });
      _pinAnimationController.animateTo(1.0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Widget _buildMapWidget() {
    _cachedMapWidget ??= MapWidget(
      key: const ValueKey('pick_location_map'),
      mapOptions: MapOptions(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
        constrainMode: ConstrainMode.HEIGHT_ONLY,
        orientation: NorthOrientation.UPWARDS,
      ),
      viewport: CameraViewportState(
        center: Point(coordinates: Position(_longitude, _latitude)),
        zoom: 15.0,
      ),
      styleUri: 'mapbox://styles/mapbox/streets-v12',
      onMapCreated: _onMapCreated,
      onCameraChangeListener: _onCameraChange,
    );
    return _cachedMapWidget!;
  }

  void _confirmLocation() {
    final detailAddress = _addressController.text.trim();
    if (detailAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Silakan masukkan detail alamat penjemputan terlebih dahulu.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _C.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'address': detailAddress,
      'latitude': _latitude,
      'longitude': _longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Mapbox Map ──
          _buildMapWidget(),

          // ── Search Backdrop Overlay ──
          if (_searchResults.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _searchResults = [];
                  });
                  _searchFocusNode.unfocus();
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),

          // ── Centered Pin Icon with Landing Animation ──
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 92),
                child: LandingPin(
                  controller: _pinAnimationController,
                  showTooltip: _addressNeedsUpdate,
                  onTap: () {
                    if (_addressNeedsUpdate) {
                      _pinAnimationController
                          .animateTo(0.0,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeIn)
                          .then((_) {
                        if (mounted) {
                          _reverseGeocode(_latitude, _longitude);
                          setState(() {
                            _addressNeedsUpdate = false;
                          });
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ),

          // ── Back Button (floating top left) ──
          Positioned(
            top: topPadding + 16,
            left: 20,
            child: Material(
              color: _C.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Iconsax.arrow_left,
                      size: 20, color: _C.textPrimary),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── Search Bar ──
          Positioned(
            top: topPadding + 16,
            left: 76,
            right: 20,
            child: Material(
              color: _C.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Iconsax.search_normal_1,
                        size: 18, color: _C.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: _C.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari alamat / area...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: _C.textTertiary),
                          filled: true,
                          fillColor: Colors.transparent,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_C.primary),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.clear,
                            size: 18, color: _C.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── Search Results List Overlay ──
          if (_searchResults.isNotEmpty)
            Positioned(
              top: topPadding + 68,
              left: 76,
              right: 20,
              child: Material(
                color: _C.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return InkWell(
                        onTap: () => _selectSearchResult(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.location5,
                                  size: 14,
                                  color: _C.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['text'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _C.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['place_name'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: _C.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── Bottom Panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Alamat Rumah / Jemput',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Geser peta untuk menentukan titik jemput yang akurat.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Text Input
                  TextField(
                    controller: _addressController,
                    style:
                        GoogleFonts.inter(fontSize: 14, color: _C.textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Nama Jalan, No. Rumah, RT/RW, Patokan (cth: Pagar Hitam, Depan Warung)',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: _C.textTertiary),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      contentPadding: const EdgeInsets.fromLTRB(16, 14, 48, 14),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.map_1,
                            size: 20, color: _C.primary),
                        tooltip: 'Ambil alamat dari titik tengah peta',
                        onPressed: () => _reverseGeocode(_latitude, _longitude),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _C.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _confirmLocation,
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: Text(
                        'KONFIRMASI LOKASI JEMPUT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic),

          // ── GPS Button ──
          Positioned(
            right: 20,
            bottom: bottomPadding + 260,
            child: Material(
              color: _C.white,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _getCurrentLocation,
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_C.primary),
                          ),
                        )
                      : const Icon(Iconsax.gps, size: 24, color: _C.primary),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LANDING PIN WIDGET — Custom Drop & Squish Animation
// ─────────────────────────────────────────────────────────
class LandingPin extends StatefulWidget {
  final VoidCallback onTap;
  final bool showTooltip;
  final AnimationController controller;

  const LandingPin({
    super.key,
    required this.onTap,
    required this.showTooltip,
    required this.controller,
  });

  @override
  State<LandingPin> createState() => _LandingPinState();
}

class _LandingPinState extends State<LandingPin> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 200,
        height: 140,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Pin Shadow (drawn first, bottom-most)
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final value =
                    widget.controller.value; // 0.0 = landed, 1.0 = floating
                final shadowScale = 1.0 - (value * 0.4);
                final shadowOpacity = 0.35 - (value * 0.25);

                return Positioned(
                  bottom: 20,
                  child: Transform.scale(
                    scale: shadowScale,
                    child: Opacity(
                      opacity: shadowOpacity.clamp(0.0, 1.0),
                      child: Container(
                        width: 18,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. The Pin Icon (drawn middle)
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final value = widget.controller.value;

                double translateY = 0.0;
                double scaleX = 1.0;
                double scaleY = 1.0;

                if (value > 0.4) {
                  final t = (value - 0.4) / 0.6;
                  translateY = -12.0 - (t * 16.0); // up to -28
                } else if (value > 0.15) {
                  final t = (value - 0.15) / 0.25;
                  translateY = -12.0 * t;
                } else {
                  final t = value / 0.15;
                  translateY = 0.0;
                  scaleY = 0.72 + (t * 0.28);
                  scaleX = 1.20 - (t * 0.20);
                }

                return Positioned(
                  bottom: 24,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                      child: const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. Tooltip Bubble (drawn last, top-most so it overlays on top of the pin)
            if (widget.showTooltip)
              Positioned(
                bottom: 104, // Positioned safely above the floating pin icon
                child: Material(
                  color: const Color(0xFF0F4C81),
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.map_1,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Ketuk Pin untuk Pasang',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }
}
