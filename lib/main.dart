import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahan import Firestore
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Tambahan import kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase MANUAL khusus Web untuk bypass error CLI
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCl6bTfBCuzZwutFM0hKb7GAs3GOV6_zUo", 
      authDomain: "travelll-45e89.firebaseapp.com",
      projectId: "travelll-45e89",
      storageBucket: "travelll-45e89.firebasestorage.app",
      messagingSenderId: "430270320192",
      appId: "1:430270320192:web:d57d66902198762ee499a5",
    ),
  );

  // Matikan persistence/cache lokal khusus platform Web agar data langsung ditembak ke Cloud
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // Initialize locale data for intl package
  Intl.defaultLocale = 'id_ID';
  await initializeDateFormatting('id_ID', null);

  // Set system UI overlay style for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock to portrait mode for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ETravelApp());
}

class ETravelApp extends StatelessWidget {
  const ETravelApp({super.key});

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