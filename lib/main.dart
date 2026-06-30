import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Matikan persistence/cache lokal khusus platform Web agar data langsung ditembak ke Cloud
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // Temporary reset call
  await _resetDatabase();

  // Initialize locale data for intl package
  Intl.defaultLocale = 'id_ID';
  await initializeDateFormatting('id_ID', null);

  // Set system UI overlay style for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait mode for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  MapboxOptions.setAccessToken(
    'pk.eyJ1IjoiY29kZWluMjEiLCJhIjoiY21jMW53a21iMGV3ajJrczd2bTR3b25mciJ9.VufbKuZE1e18mU4zCbvVyw',
  );

  runApp(const MinangTravelApp());
}

Future<void> _resetDatabase() async {
  final db = FirebaseFirestore.instance;
  final collections = [
    'bookings',
    'seat_locks',
    'fleets',
    'driver_locations',
    'routes',
    'promo_codes',
    'shipments'
  ];
  for (final col in collections) {
    try {
      final snap = await db.collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      print('>>> RESET DATABASE: Deleted collection: $col (${snap.docs.length} docs)');
    } catch (e) {
      print('>>> RESET DATABASE: Error deleting collection $col: $e');
    }
  }
}

class MinangTravelApp extends StatelessWidget {
  const MinangTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
