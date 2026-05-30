/// Region type for Indonesian administrative divisions.
/// Indonesia memiliki 514 daerah: 38 Provinsi, 98 Kota, 416 Kabupaten.
enum RegionType { kota, kabupaten }

/// Represents a region node in the route graph.
///
/// Supports all Indonesian administrative regions.
/// Backward compatible — alias: [RegionNode].
class CityNode {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final RegionType type;
  final String province;

  const CityNode({
    required this.id,
    required this.name,
    this.latitude = 0,
    this.longitude = 0,
    this.type = RegionType.kota,
    this.province = '',
  });

  /// Display name with region type prefix (e.g., "Kota Bandung", "Kab. Magelang").
  String get fullName {
    switch (type) {
      case RegionType.kota:
        return 'Kota $name';
      case RegionType.kabupaten:
        return 'Kab. $name';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityNode && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Alias — new code should prefer [RegionNode].
typedef RegionNode = CityNode;

/// Represents a route edge between two cities
class RouteEdge {
  final String fromCityId;
  final String toCityId;
  final double distance; // in km
  final int price; // in IDR
  final int duration; // in minutes

  const RouteEdge({
    required this.fromCityId,
    required this.toCityId,
    required this.distance,
    required this.price,
    required this.duration,
  });
}

/// Represents a search result from Dijkstra
class RouteResult {
  final List<CityNode> path;
  final double totalDistance;
  final int totalPrice;
  final int totalDuration;
  final bool isDirect;
  final List<RouteEdge> edges;

  const RouteResult({
    required this.path,
    required this.totalDistance,
    required this.totalPrice,
    required this.totalDuration,
    required this.isDirect,
    required this.edges,
  });

  int get transitCount => path.length - 2;
  String get routeSummary => path.map((c) => c.name).join(' → ');
}

/// Seat model
enum SeatStatus { available, selected, occupied, driver }

class SeatModel {
  final int number;
  final SeatStatus status;
  final String? passengerName;

  const SeatModel({
    required this.number,
    this.status = SeatStatus.available,
    this.passengerName,
  });

  SeatModel copyWith({SeatStatus? status, String? passengerName}) {
    return SeatModel(
      number: number,
      status: status ?? this.status,
      passengerName: passengerName ?? this.passengerName,
    );
  }
}

/// Schedule model
class ScheduleModel {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final RouteResult route;
  final DateTime departureTime;
  final int availableSeats;
  final List<SeatModel> seats;

  const ScheduleModel({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.route,
    required this.departureTime,
    required this.availableSeats,
    required this.seats,
  });
}
