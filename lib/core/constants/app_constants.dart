class AppConstants {
  // App Info
  static const String appName = 'E-Travel';
  static const String appTagline = 'Perjalanan Nyaman, Harga Teman';

  // Fleet Config
  static const int totalFleet = 10;
  static const int seatsPerVehicle = 8;

  // Dummy Cities (Sumatera Barat)
  static const List<String> cities = [
    'Padang',
    'Bukittinggi',
    'Payakumbuh',
    'Batusangkar',
    'Pariaman',
    'Padang Panjang',
    'Sawahlunto',
    'Solok',
    'Lubuk Basung',
    'Dharmasraya',
  ];

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(milliseconds: 3000);
}
