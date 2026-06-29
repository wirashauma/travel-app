import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DriverTrackingService {
  DriverTrackingService._();

  static final _db = FirebaseFirestore.instance;
  static Timer? _timer;
  static Position? _lastPosition;
  static String? _activeFleetId;

  static bool get isTracking => _timer != null && _timer!.isActive;

  /// Start publishing location to Firestore every [intervalSeconds].
  static Future<void> startTracking({
    required String fleetId,
    int intervalSeconds = 5,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User tidak terautentikasi');

    _activeFleetId = fleetId;

    // Request location permission
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak. Izinkan akses lokasi di pengaturan.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan lokasi di pengaturan perangkat.',
      );
    }

    // Set fleet trip status
    await _db.collection('fleets').doc(fleetId).update({
      'tripStatus': 'berangkat',
      'tripStartedAt': FieldValue.serverTimestamp(),
    });

    // Initial location
    try {
      _lastPosition = await Geolocator.getCurrentPosition();
      await _publishLocation(_lastPosition!, uid);
    } catch (_) {}

    // Periodic updates
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        try {
          final pos = await Geolocator.getCurrentPosition();
          _lastPosition = pos;
          await _publishLocation(pos, uid);
        } catch (_) {}
      },
    );
  }

  static Future<void> _publishLocation(Position pos, String uid) async {
    if (_activeFleetId == null) return;
    await _db.collection('driver_locations').doc(_activeFleetId).set({
      'fleetId': _activeFleetId,
      'driverId': uid,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'heading': pos.heading,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stop tracking and mark offline.
  static Future<void> stopTracking([String? fleetId]) async {
    _timer?.cancel();
    _timer = null;

    final targetFleetId = fleetId ?? _activeFleetId;
    if (targetFleetId != null) {
      try {
        await _db.collection('driver_locations').doc(targetFleetId).update({
          'isOnline': false,
        });
      } catch (_) {}
      
      await _db.collection('fleets').doc(targetFleetId).update({
        'tripStatus': 'selesai',
      });

      if (targetFleetId == _activeFleetId) {
        _activeFleetId = null;
      }
    }
    _lastPosition = null;
  }

}
