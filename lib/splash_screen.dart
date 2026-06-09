import 'package:flutter/material.dart';
import 'main.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    // 💡 DEVELOPMENT BYPASS: Skips email authentication completely for local screen testing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Force routing directly to the Dashboard screen layout unconditionally
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(
        0xFF0B0B0F,
      ), // Matches the uniform 7even dark theme
      body: Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      ),
    );
  }
}
