import 'dart:collection';

// ═══════════════════════════════════════════════════════════
//  DIJKSTRA SERVICE — Pure Dart, Sumatera Barat Only
//
//  Graf statis kota-kota Sumatera Barat dengan bobot jarak
//  (km) dan estimasi durasi. Menggunakan SplayTreeSet
//  sebagai Priority Queue untuk performa O((V+E) log V).
//
//  Fungsi utama:
//  • getShortestRoute(start, end) → List<String> path
//  • calculateTotalDistance(start, end) → int km
//  • getRouteDetail(start, end) → DijkstraRouteResult?
//  • getAllCities() → List<String>
// ═══════════════════════════════════════════════════════════

/// Hasil pencarian rute Dijkstra.
class DijkstraRouteResult {
  final List<String> path;
  final int totalDistanceKm;
  final int estimatedDurationMinutes;

  const DijkstraRouteResult({
    required this.path,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
  });

  String get routeSummary => path.join(' → ');

  String get formattedDuration {
    final h = estimatedDurationMinutes ~/ 60;
    final m = estimatedDurationMinutes % 60;
    if (h == 0) return '$m menit';
    if (m == 0) return '$h jam';
    return '$h jam $m menit';
  }
}

/// Edge pada graf rute.
class _Edge {
  final String to;
  final int distanceKm;
  final int durationMinutes;

  const _Edge({
    required this.to,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

/// Service Dijkstra murni Dart untuk kota-kota Sumatera Barat.
class DijkstraService {
  DijkstraService._();
  static final instance = DijkstraService._();

  // ─────────────────────────────────────────────────────
  //  GRAPH — Adjacency List Kota Sumatera Barat
  //
  //  Setiap entry: kota → [ {tujuan, jarak_km, durasi_menit} ]
  //  Semua edge ditambahkan bidirectional di _buildGraph().
  //  Bobot jarak disesuaikan dengan kondisi jalan nyata.
  // ─────────────────────────────────────────────────────
  static const List<_RawEdge> _rawEdges = [
    // ── Padang hub ──
    _RawEdge('Padang', 'Padang Panjang', 70, 90),
    _RawEdge('Padang', 'Pariaman', 55, 70),
    _RawEdge('Padang', 'Solok', 64, 80),
    _RawEdge('Padang', 'Pesisir Selatan', 77, 100),

    // ── Padang Panjang hub ──
    _RawEdge('Padang Panjang', 'Bukittinggi', 20, 25),
    _RawEdge('Padang Panjang', 'Batusangkar', 40, 50),
    _RawEdge('Padang Panjang', 'Solok', 35, 45),

    // ── Bukittinggi hub ──
    _RawEdge('Bukittinggi', 'Payakumbuh', 37, 45),
    _RawEdge('Bukittinggi', 'Pasaman', 100, 130),
    _RawEdge('Bukittinggi', 'Pariaman', 65, 85),

    // ── Payakumbuh hub ──
    _RawEdge('Payakumbuh', 'Batusangkar', 30, 40),
    _RawEdge('Payakumbuh', 'Sijunjung', 100, 130),

    // ── Solok hub ──
    _RawEdge('Solok', 'Sawahlunto', 38, 50),
    _RawEdge('Solok', 'Solok Selatan', 90, 120),

    // ── Sawahlunto hub ──
    _RawEdge('Sawahlunto', 'Sijunjung', 30, 40),
    _RawEdge('Sawahlunto', 'Batusangkar', 55, 70),

    // ── Pesisir Selatan hub ──
    _RawEdge('Pesisir Selatan', 'Solok Selatan', 110, 140),

    // ── Pasaman hub ──
    _RawEdge('Pasaman', 'Pasaman Barat', 50, 65),

    // ── Pariaman ──
    _RawEdge('Pariaman', 'Pasaman Barat', 115, 150),

    // ── Sijunjung - Dharmasraya corridor ──
    _RawEdge('Sijunjung', 'Dharmasraya', 80, 100),

    // ── Solok Selatan - Dharmasraya ──
    _RawEdge('Solok Selatan', 'Dharmasraya', 95, 120),

    // ── Tanah Datar - Agam (alternative) ──
    _RawEdge('Batusangkar', 'Bukittinggi', 45, 55),

    // ── Agam - Lima Puluh Kota ──
    _RawEdge('Bukittinggi', 'Lubuk Basung', 25, 35),
    _RawEdge('Lubuk Basung', 'Pariaman', 50, 65),
    _RawEdge('Lubuk Basung', 'Pasaman Barat', 90, 115),
  ];

  /// Lazy-init adjacency list (bidirectional).
  late final Map<String, List<_Edge>> _graph = _buildGraph();

  Map<String, List<_Edge>> _buildGraph() {
    final g = <String, List<_Edge>>{};
    for (final raw in _rawEdges) {
      g.putIfAbsent(raw.from, () => []).add(
            _Edge(to: raw.to, distanceKm: raw.km, durationMinutes: raw.min),
          );
      g.putIfAbsent(raw.to, () => []).add(
            _Edge(
                to: raw.from, distanceKm: raw.km, durationMinutes: raw.min),
          );
    }
    return g;
  }

  // ─────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────

  /// Daftar semua kota yang tersedia dalam graf.
  List<String> getAllCities() {
    final cities = _graph.keys.toList()..sort();
    return cities;
  }

  /// Mengembalikan list nama kota dari [start] ke [end]
  /// menggunakan Dijkstra (bobot: jarak km).
  /// Mengembalikan list kosong jika tidak ada jalur.
  List<String> getShortestRoute(String start, String end) {
    final result = getRouteDetail(start, end);
    return result?.path ?? [];
  }

  /// Menghitung total jarak terpendek (km) dari [start] ke [end].
  /// Mengembalikan -1 jika tidak ada jalur.
  int calculateTotalDistance(String start, String end) {
    final result = getRouteDetail(start, end);
    return result?.totalDistanceKm ?? -1;
  }

  /// Mendapatkan detail lengkap rute terpendek.
  DijkstraRouteResult? getRouteDetail(String start, String end) {
    if (!_graph.containsKey(start) || !_graph.containsKey(end)) return null;
    if (start == end) {
      return DijkstraRouteResult(
        path: [start],
        totalDistanceKm: 0,
        estimatedDurationMinutes: 0,
      );
    }

    // ── Dijkstra with SplayTreeSet as priority queue ──
    final dist = <String, int>{};
    final dur = <String, int>{};
    final prev = <String, String?>{};
    final visited = <String>{};

    for (final node in _graph.keys) {
      dist[node] = _maxInt;
      dur[node] = _maxInt;
      prev[node] = null;
    }
    dist[start] = 0;
    dur[start] = 0;

    // Priority queue sorted by (distance, cityName)
    final pq = SplayTreeSet<MapEntry<int, String>>((a, b) {
      final cmp = a.key.compareTo(b.key);
      return cmp != 0 ? cmp : a.value.compareTo(b.value);
    });
    pq.add(MapEntry(0, start));

    while (pq.isNotEmpty) {
      final curr = pq.first;
      pq.remove(curr);
      final u = curr.value;

      if (visited.contains(u)) continue;
      visited.add(u);
      if (u == end) break; // early termination

      for (final edge in (_graph[u] ?? [])) {
        final v = edge.to;
        if (visited.contains(v)) continue;

        final int altDist = (dist[u]! + edge.distanceKm).toInt();
        if (altDist < (dist[v] ?? _maxInt)) {
          // decrease-key
          pq.remove(MapEntry(dist[v] ?? _maxInt, v));
          dist[v] = altDist;
          dur[v] = (dur[u]! + edge.durationMinutes).toInt();
          prev[v] = u;
          pq.add(MapEntry(altDist, v));
        }
      }
    }

    // No path found
    if (dist[end] == _maxInt) return null;

    // Reconstruct path
    final path = <String>[];
    String? current = end;
    while (current != null) {
      path.insert(0, current);
      current = prev[current];
    }

    return DijkstraRouteResult(
      path: path,
      totalDistanceKm: dist[end]!,
      estimatedDurationMinutes: dur[end]!,
    );
  }

  static const int _maxInt = 0x7FFFFFFF; // ~2.1 billion
}

/// Raw edge data for the graph definition.
class _RawEdge {
  final String from;
  final String to;
  final int km;
  final int min;

  const _RawEdge(this.from, this.to, this.km, this.min);
}
