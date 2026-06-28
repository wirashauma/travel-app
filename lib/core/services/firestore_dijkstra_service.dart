import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Edge in the route graph loaded from Firestore `routes` collection.
class _Edge {
  final String from;
  final String to;
  final double distance; // km
  final int price; // Rp
  final int durationMinutes;

  const _Edge({
    required this.from,
    required this.to,
    required this.distance,
    required this.price,
    required this.durationMinutes,
  });
}

/// Result of a Dijkstra path search.
class DijkstraResult {
  final List<String> path;
  final double totalDistance;
  final int totalPrice;
  final int totalDurationMinutes;

  const DijkstraResult({
    required this.path,
    required this.totalDistance,
    required this.totalPrice,
    required this.totalDurationMinutes,
  });

  String get routeSummary => path.join(' → ');

  String get formattedDuration {
    final h = totalDurationMinutes ~/ 60;
    final m = totalDurationMinutes % 60;
    if (h == 0) return '$m menit';
    if (m == 0) return '$h jam';
    return '$h jam $m menit';
  }

  @override
  String toString() =>
      'DijkstraResult(path: $routeSummary, dist: ${totalDistance}km, '
      'price: Rp $totalPrice, dur: $formattedDuration)';
}

/// Dijkstra service that reads edges from Firestore `routes` collection.
///
/// Firestore document fields expected:
/// - `from`     : String  (city name)
/// - `to`       : String  (city name)
/// - `distance` : num     (km)
/// - `price`    : num     (Rp)
/// - `duration` : String  (e.g. "5 jam 30 menit")
///
/// All edges are treated as **bidirectional**.
class FirestoreDijkstraService {
  FirestoreDijkstraService._();
  static final instance = FirestoreDijkstraService._();

  final _routesRef = FirebaseFirestore.instance.collection('routes');

  // ─────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────

  /// Find cheapest path (by price).
  Future<DijkstraResult?> findCheapestPath(String start, String end) async {
    final edges = await _fetchEdges();
    return _run(edges, start, end, (e) => e.price.toDouble());
  }

  /// Find shortest path (by distance).
  Future<DijkstraResult?> findShortestPath(String start, String end) async {
    final edges = await _fetchEdges();
    return _run(edges, start, end, (e) => e.distance);
  }

  /// Find fastest path (by duration).
  Future<DijkstraResult?> findFastestPath(String start, String end) async {
    final edges = await _fetchEdges();
    return _run(edges, start, end, (e) => e.durationMinutes.toDouble());
  }

  /// Convenience — returns cheapest path (same as [findCheapestPath]).
  Future<DijkstraResult?> getShortestPath(
      String startNode, String endNode) async {
    return findCheapestPath(startNode, endNode);
  }

  /// Check if a package route (pkgOrigin → pkgDest) is covered by a fleet's route.
  /// Returns true only if both cities are on the path and pkgOrigin comes before pkgDest.
  Future<bool> isRouteCovered(String fleetOrigin, String fleetDest, String pkgOrigin, String pkgDest) async {
    final edges = await _fetchEdges();
    final result = _run(edges, fleetOrigin, fleetDest, (e) => e.distance);
    if (result == null) return false;
    final oIdx = result.path.indexOf(pkgOrigin);
    final dIdx = result.path.indexOf(pkgDest);
    return oIdx != -1 && dIdx != -1 && oIdx < dIdx;
  }

  /// Get all unique city names from the routes collection.
  Future<List<String>> getAllCities() async {
    final edges = await _fetchEdges();
    final cities = <String>{};
    for (final e in edges) {
      cities.add(e.from);
      cities.add(e.to);
    }
    final list = cities.toList()..sort();
    return list;
  }

  // ─────────────────────────────────────────────────────
  //  FETCH EDGES FROM FIRESTORE
  // ─────────────────────────────────────────────────────
  Future<List<_Edge>> _fetchEdges() async {
    final snap = await _routesRef.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return _Edge(
        from: d['from'] as String? ?? '',
        to: d['to'] as String? ?? '',
        distance: (d['distance'] as num?)?.toDouble() ?? 0,
        price: (d['price'] as num?)?.toInt() ?? 0,
        durationMinutes: _parseDuration(d['duration'] as String? ?? ''),
      );
    }).toList();
  }

  /// Parse duration string → minutes.
  ///
  /// Supported formats (case-insensitive):
  ///   "5 jam 30 menit"  → 330
  ///   "1.5 Jam"         → 90   (decimal hours)
  ///   "2.5 Jam"         → 150
  ///   "45 Menit"        → 45
  ///   "30 menit"        → 30
  static int _parseDuration(String raw) {
    if (raw.isEmpty) return 0;
    int minutes = 0;
    // Match decimal or integer hours, case-insensitive
    final jamMatch = RegExp(r'(\d+(?:\.\d+)?)\s*jam', caseSensitive: false)
        .firstMatch(raw);
    if (jamMatch != null) {
      final hours = double.tryParse(jamMatch.group(1)!) ?? 0;
      minutes += (hours * 60).round();
    }
    // Match minutes, case-insensitive
    final menitMatch =
        RegExp(r'(\d+)\s*menit', caseSensitive: false).firstMatch(raw);
    if (menitMatch != null) {
      minutes += int.parse(menitMatch.group(1)!);
    }
    return minutes;
  }

  // ─────────────────────────────────────────────────────
  //  DIJKSTRA CORE
  // ─────────────────────────────────────────────────────
  DijkstraResult? _run(
    List<_Edge> edges,
    String start,
    String end,
    double Function(_Edge) weightFn,
  ) {
    // Build bidirectional adjacency list
    final adj = <String, List<_Edge>>{};
    for (final e in edges) {
      adj.putIfAbsent(e.from, () => []).add(e);
      adj.putIfAbsent(e.to, () => []).add(_Edge(
            from: e.to,
            to: e.from,
            distance: e.distance,
            price: e.price,
            durationMinutes: e.durationMinutes,
          ));
    }

    // Check nodes exist
    if (!adj.containsKey(start) || !adj.containsKey(end)) return null;

    final dist = <String, double>{};
    final prev = <String, String?>{};
    final prevEdge = <String, _Edge?>{};
    final visited = <String>{};

    for (final node in adj.keys) {
      dist[node] = double.infinity;
      prev[node] = null;
      prevEdge[node] = null;
    }
    dist[start] = 0;

    // Priority queue: (weight, nodeName)
    final pq = SplayTreeSet<MapEntry<double, String>>((a, b) {
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
      if (u == end) break;

      for (final edge in (adj[u] ?? [])) {
        final v = edge.to;
        if (visited.contains(v)) continue;

        final alt = dist[u]! + weightFn(edge);
        if (alt < (dist[v] ?? double.infinity)) {
          pq.remove(MapEntry(dist[v] ?? double.infinity, v));
          dist[v] = alt;
          prev[v] = u;
          prevEdge[v] = edge;
          pq.add(MapEntry(alt, v));
        }
      }
    }

    // Reconstruct
    if (dist[end] == double.infinity || dist[end] == null) return null;

    final path = <String>[];
    final pathEdges = <_Edge>[];
    String? current = end;

    while (current != null) {
      path.insert(0, current);
      if (prevEdge[current] != null) pathEdges.insert(0, prevEdge[current]!);
      current = prev[current];
    }

    double totalDist = 0;
    int totalPrice = 0;
    int totalDur = 0;
    for (final e in pathEdges) {
      totalDist += e.distance;
      totalPrice += e.price;
      totalDur += e.durationMinutes;
    }

    return DijkstraResult(
      path: path,
      totalDistance: totalDist,
      totalPrice: totalPrice,
      totalDurationMinutes: totalDur,
    );
  }
}
