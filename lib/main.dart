import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'nav_observer.dart';
import 'theme_manager.dart';
import 'Authentication/auth_gate.dart';
import 'services/hive_service.dart';

import 'widgets/responsive_wrapper.dart'; // Add import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (optional)
  try {
    await dotenv.load();
    debugPrint('✓ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠ .env file not found or error loading: $e');
    // Continue without .env - it's optional
  }

  // Initialize Hive
  try {
    await Hive.initFlutter();
    debugPrint('✓ Hive initialized');
  } catch (e) {
    debugPrint('❌ Hive initialization error: $e');
  }

  // Initialize Hive service with adapters
  try {
    await HiveService.init();
    debugPrint('✓ Hive service initialized');
  } catch (e) {
    debugPrint('❌ Hive service error: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✓ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const KK360App());
}

class KK360App extends StatelessWidget {
  const KK360App({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KK 360',
          navigatorObservers: [routeObserver],
          themeMode: themeManager.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4B3FA3),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xffF4F5F7),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4B3FA3),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
            ),
          ),
          // Use builder to wrap all screens in ResponsiveWrapper
          builder: (context, child) {
            return ResponsiveWrapper(child: child!);
          },
          home: const AuthGate(),
        );
      },
    );
  }
}
