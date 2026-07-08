import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ReelsCounterApp());
}

class ReelsCounterApp extends StatelessWidget {
  const ReelsCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
