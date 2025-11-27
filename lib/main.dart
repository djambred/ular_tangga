import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/level_selection_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/instructions_screen.dart';

void main() {
  runApp(const TBEducationGameApp());
}

class TBEducationGameApp extends StatelessWidget {
  const TBEducationGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Ular Tangga Edukasi TBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/level-selection': (context) => const LevelSelectionScreen(),
        '/main-navigation': (context) => const MainNavigationScreen(),
        '/instructions': (context) => const InstructionsScreen(),
      },
    );
  }
}
