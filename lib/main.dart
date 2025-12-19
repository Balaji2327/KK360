import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Authentication/role_selection.dart';
import 'nav_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const KK360App());
}

class KK360App extends StatelessWidget {
  const KK360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KK 360',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // 👈 Set your custom font family name here
        // textTheme: const TextTheme(
        //   bodyLarge: TextStyle(),
        //   bodyMedium: TextStyle(),
        //   bodySmall: TextStyle(),
        // ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
