import 'package:flutter/material.dart';
import 'Authentication/role_selection.dart';

void main() {
  runApp(const KK360App());
}

class KK360App extends StatelessWidget {
  const KK360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KK 360',
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
