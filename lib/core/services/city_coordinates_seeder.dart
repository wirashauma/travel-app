import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════
///  CITY COORDINATES SEEDER
///  Menyuntikkan field `lat` dan `lng` ke setiap dokumen di collection
///  `routes`, berdasarkan nama kota field `from` dan `to`.
///
///  Juga membuat/update collection `city_coordinates` sebagai master
///  lookup agar widget peta bisa mengonversi nama kota → LatLng.
///
///  Koordinat: Pusat kota / ibukota kabupaten (aproksimasi).
///  Sumber: Google Maps / BPS / OpenStreetMap.
/// ═══════════════════════════════════════════════════════════════════════
class CityCoordinatesSeeder {
  CityCoordinatesSeeder._();

  static final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────
  //  MASTER DATA KOORDINAT — Semua kota di rute Sumatera
  // ─────────────────────────────────────────────────────
  static const Map<String, Map<String, double>> _coordinates = {
    // ══════════════════════════════════════════
    //  ACEH
    // ══════════════════════════════════════════
    'Banda Aceh':       {'lat': 5.5483,   'lng': 95.3238},
    'Meulaboh':         {'lat': 4.1360,   'lng': 96.1285},
    'Lhokseumawe':      {'lat': 5.1801,   'lng': 97.1507},
    'Langsa':           {'lat': 4.4683,   'lng': 97.9683},
    'Tapaktuan':        {'lat': 3.2640,   'lng': 97.1840},
    'Kutacane':         {'lat': 3.5153,   'lng': 97.8045},

    // ══════════════════════════════════════════
    //  SUMATERA UTARA
    // ══════════════════════════════════════════
    'Medan':            {'lat': 3.5952,   'lng': 98.6722},
    'Binjai':           {'lat': 3.6001,   'lng': 98.4854},
    'Tebing Tinggi':    {'lat': 3.3267,   'lng': 99.1567},
    'Pematang Siantar': {'lat': 2.9536,   'lng': 99.0489},
    'Parapat':          {'lat': 2.6640,   'lng': 98.9410},
    'Tarutung':         {'lat': 2.0150,   'lng': 98.9640},
    'Sibolga':          {'lat': 1.7427,   'lng': 98.7792},
    'Rantau Prapat':    {'lat': 2.1050,   'lng': 99.8450},
    'Kisaran':          {'lat': 2.9840,   'lng': 99.6250},
    'Padang Sidempuan': {'lat': 1.3795,   'lng': 99.2735},
    'Mandailing Natal': {'lat': 0.8500,   'lng': 99.4500},

    // ══════════════════════════════════════════
    //  SUMATERA BARAT
    // ══════════════════════════════════════════
    'Bukittinggi':      {'lat': -0.3056,  'lng': 100.3692},
    'Padang':           {'lat': -0.9471,  'lng': 100.4172},
    'Payakumbuh':       {'lat': -0.2167,  'lng': 100.6333},
    'Solok':            {'lat': -0.7890,  'lng': 100.6530},
    'Painan':           {'lat': -1.3460,  'lng': 100.5780},
    'Muaro Sijunjung':  {'lat': -0.7000,  'lng': 101.0000},
    'Dharmasraya':      {'lat': -1.0500,  'lng': 101.5200},
    // ── 10 Kota/Kab Sumbar yang sebelumnya hilang (fix Google Maps blank) ──
    'Batusangkar':      {'lat': -0.4619,  'lng': 100.5752},
    'Lubuk Basung':     {'lat': -0.3169,  'lng': 100.0508},
    'Pariaman':         {'lat': -0.6267,  'lng': 100.1164},
    'Pasaman':          {'lat': 0.0839,   'lng': 100.0667},
    'Pasaman Barat':    {'lat': 0.0833,   'lng': 99.6500},
    'Padang Panjang':   {'lat': -0.4657,  'lng': 100.4101},
    'Pesisir Selatan':  {'lat': -1.8606,  'lng': 100.9339},
    'Sawahlunto':       {'lat': -0.6801,  'lng': 100.7776},
    'Sijunjung':        {'lat': -0.6922,  'lng': 100.9669},
    'Solok Selatan':    {'lat': -1.7000,  'lng': 101.3833},


    // ══════════════════════════════════════════
    //  RIAU
    // ══════════════════════════════════════════
    'Pekanbaru':            {'lat': 0.5071,   'lng': 101.4478},
    'Bangkinang':           {'lat': 0.3300,   'lng': 101.0500},
    'Dumai':                {'lat': 1.6667,   'lng': 101.4500},
    'Siak Sri Indrapura':   {'lat': 1.1000,   'lng': 102.0000},
    'Rengat':               {'lat': -0.3500,  'lng': 102.1500},
    'Tembilahan':           {'lat': -0.3200,  'lng': 103.1700},

    // ══════════════════════════════════════════
    //  KEPULAUAN RIAU
    // ══════════════════════════════════════════
    'Tanjung Balai Karimun': {'lat': 1.0142,  'lng': 103.3947},
    'Batam':                 {'lat': 1.0456,  'lng': 104.0305},
    'Tanjung Pinang':        {'lat': 0.9186,  'lng': 104.4467},

    // ══════════════════════════════════════════
    //  JAMBI
    // ══════════════════════════════════════════
    'Muara Bungo':      {'lat': -1.4500,  'lng': 102.1000},
    'Jambi':            {'lat': -1.6101,  'lng': 103.6131},
    'Muara Tebo':       {'lat': -1.3500,  'lng': 102.5500},
    'Sungai Penuh':     {'lat': -2.0560,  'lng': 101.3917},

    // ══════════════════════════════════════════
    //  BENGKULU
    // ══════════════════════════════════════════
    'Bengkulu':         {'lat': -3.7928,  'lng': 102.2608},
    'Manna':            {'lat': -4.4500,  'lng': 102.9000},
    'Curup':            {'lat': -3.4700,  'lng': 102.5300},
    'Lubuk Linggau':    {'lat': -3.2972,  'lng': 102.8611},
    'Krui':             {'lat': -5.2000,  'lng': 104.0500},

    // ══════════════════════════════════════════
    //  SUMATERA SELATAN
    // ══════════════════════════════════════════
    'Palembang':        {'lat': -2.9761,  'lng': 104.7754},
    'Prabumulih':       {'lat': -3.4250,  'lng': 104.2333},
    'Baturaja':         {'lat': -4.1290,  'lng': 104.1670},
    'Kayuagung':        {'lat': -3.3720,  'lng': 104.8560},
    'Muara Enim':       {'lat': -3.6500,  'lng': 103.7500},
    'Lahat':            {'lat': -3.8000,  'lng': 103.5500},
    'Pagar Alam':       {'lat': -4.0167,  'lng': 103.2500},

    // ══════════════════════════════════════════
    //  BANGKA BELITUNG
    // ══════════════════════════════════════════
    'Pangkal Pinang':   {'lat': -2.1290,  'lng': 106.1160},
    'Tanjung Pandan':   {'lat': -2.7220,  'lng': 107.6420},

    // ══════════════════════════════════════════
    //  LAMPUNG
    // ══════════════════════════════════════════
    'Bandar Lampung':   {'lat': -5.3971,  'lng': 105.2668},
    'Metro':            {'lat': -5.1180,  'lng': 105.3100},
    'Pringsewu':        {'lat': -5.3580,  'lng': 104.9830},
    'Bakauheni':        {'lat': -5.8700,  'lng': 105.7500},
  };

  /// Getter publik agar service lain bisa mengakses koordinat
  static Map<String, Map<String, double>> get coordinates => _coordinates;

  // ─────────────────────────────────────────────────────
  //  SEED CITY COORDINATES
  //  Membuat/update collection `city_coordinates` untuk lookup peta
  // ─────────────────────────────────────────────────────
  static Future<int> seedCityCoordinates() async {
    final ref = _db.collection('city_coordinates');
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    int count = 0;

    for (final entry in _coordinates.entries) {
      final cityName = entry.key;
      final coords = entry.value;
      // Use sanitized city name as doc ID
      final docId = cityName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      batch.set(
        ref.doc(docId),
        {
          'name': cityName,
          'lat': coords['lat'],
          'lng': coords['lng'],
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      count++;
    }

    await batch.commit();
    return count;
  }

  // ─────────────────────────────────────────────────────
  //  UPDATE EXISTING ROUTES WITH lat/lng
  //  Menambahkan fromLat, fromLng, toLat, toLng ke setiap
  //  dokumen `routes` yang sudah ada di Firestore.
  // ─────────────────────────────────────────────────────
  static Future<int> updateRoutesWithCoordinates() async {
    final routesRef = _db.collection('routes');
    final snap = await routesRef.get();
    int updatedCount = 0;

    // Process in batches of 500 (Firestore limit)
    final List<List<QueryDocumentSnapshot>> chunks = [];
    for (var i = 0; i < snap.docs.length; i += 400) {
      chunks.add(
        snap.docs.sublist(
          i,
          i + 400 > snap.docs.length ? snap.docs.length : i + 400,
        ),
      );
    }

    for (final chunk in chunks) {
      final batch = _db.batch();
      for (final doc in chunk) {
        final data = doc.data() as Map<String, dynamic>;
        final from = data['from'] as String? ?? '';
        final to = data['to'] as String? ?? '';

        final fromCoords = _coordinates[from];
        final toCoords = _coordinates[to];

        if (fromCoords != null && toCoords != null) {
          batch.update(doc.reference, {
            'fromLat': fromCoords['lat'],
            'fromLng': fromCoords['lng'],
            'toLat': toCoords['lat'],
            'toLng': toCoords['lng'],
          });
          updatedCount++;
        }
      }
      await batch.commit();
    }

    return updatedCount;
  }

  // ─────────────────────────────────────────────────────
  //  FULL SEED — Runs both operations
  // ─────────────────────────────────────────────────────
  static Future<({int cities, int routes})> seedAll() async {
    final cities = await seedCityCoordinates();
    final routes = await updateRoutesWithCoordinates();
    return (cities: cities, routes: routes);
  }

  /// Fetch coordinates for a city name from the local map (case-insensitive).
  /// Returns null if city not found.
  static Map<String, double>? getCoordinates(String cityName) {
    final lowerName = cityName.trim().toLowerCase();
    // Try exact first
    if (_coordinates.containsKey(cityName)) {
      return _coordinates[cityName];
    }
    // Try case-insensitive search
    for (final entry in _coordinates.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    return null;
  }

  /// Fetch coordinates from Firestore `city_coordinates` collection (case-insensitive).
  /// Useful if new cities were added via Super Admin.
  static Future<Map<String, double>?> fetchCoordinatesFromFirestore(
      String cityName) async {
    final docId = cityName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final snap = await _db.collection('city_coordinates').doc(docId).get();
    if (!snap.exists) {
      // Fallback query case-insensitive search on 'name' if docId doesn't exist
      final querySnap = await _db
          .collection('city_coordinates')
          .where('name', isEqualTo: cityName)
          .limit(1)
          .get();
      if (querySnap.docs.isEmpty) return null;
      final d = querySnap.docs.first.data();
      return {
        'lat': (d['lat'] as num?)?.toDouble() ?? 0,
        'lng': (d['lng'] as num?)?.toDouble() ?? 0,
      };
    }
    final d = snap.data();
    if (d == null) return null;
    return {
      'lat': (d['lat'] as num?)?.toDouble() ?? 0,
      'lng': (d['lng'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Build a full coordinate map from Firestore (for runtime use).
  static Future<Map<String, Map<String, double>>> fetchAllCoordinates() async {
    final snap = await _db.collection('city_coordinates').get();
    final result = <String, Map<String, double>>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final name = d['name'] as String? ?? '';
      if (name.isNotEmpty) {
        result[name] = {
          'lat': (d['lat'] as num?)?.toDouble() ?? 0,
          'lng': (d['lng'] as num?)?.toDouble() ?? 0,
        };
      }
    }
    return result;
  }
}
