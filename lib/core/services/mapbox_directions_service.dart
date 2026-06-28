import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lng_lat.dart';

class MapboxDirectionsService {
  MapboxDirectionsService._();
  static final instance = MapboxDirectionsService._();

  static const _accessToken =
      'pk.eyJ1IjoiY29kZWluMjEiLCJhIjoiY21jMW53a21iMGV3ajJrczd2bTR3b25mciJ9.VufbKuZE1e18mU4zCbvVyw';

  Future<List<LngLat>> getRoute(List<LngLat> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final coordsStr =
        waypoints.map((p) => '${p.lng},${p.lat}').join(';');
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/$coordsStr'
      '?geometries=geojson&overview=full&steps=true&access_token=$_accessToken',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Directions API error: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = body['routes'] as List;
    if (routes.isEmpty) throw Exception('No route found');

    final geometry = routes.first['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return coordinates
        .map((c) => LngLat(
              (c[0] as num).toDouble(),
              (c[1] as num).toDouble(),
            ))
        .toList();
  }
}
