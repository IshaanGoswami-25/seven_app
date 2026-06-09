import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart'; // 👈 This links your main entry point to your gateway screen

void main() async {
  // Ensure the native Flutter platform frameworks are fully booted
  WidgetsFlutterBinding.ensureInitialized();

  // Connect directly to your cloud backend
  await Supabase.initialize(
    url: 'https://rwjufykmmnawfgorxrvt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3anVmeWttbW5hd2Znb3J4cnZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5OTczMDcsImV4cCI6MjA5NjU3MzMwN30.F4Tcl1_bJbcjIIDHhP0ohZf_kzJ6K8khdKANkffbs0Q',
  );

  runApp(const MyApp());
}

// Global handle to query database tables anywhere inside your app screens
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '7even Core',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F), // Premium dark theme
      ),
      // 👈 CHANGE THIS LINE: Set the landing page to the SplashScreen
      home: const SplashScreen(),
    );
  }
}
