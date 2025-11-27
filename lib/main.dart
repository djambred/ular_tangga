import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

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
    );
  }
}
