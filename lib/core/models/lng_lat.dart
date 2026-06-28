class LngLat {
  final double lng;
  final double lat;
  const LngLat(this.lng, this.lat);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LngLat && lng == other.lng && lat == other.lat;

  @override
  int get hashCode => lng.hashCode ^ lat.hashCode;
}
