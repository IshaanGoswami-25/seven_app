import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';
import 'profile_view_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // 📄 PASTE YOUR ACTUAL SUPABASE URL HERE (e.g., https://xyz.supabase.co)
    url: 'https://rwjufykmmnawfgorxrvt.supabase.co',

    // 🔑 PASTE YOUR ACTUAL ANON KEY HERE (The super long string)
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3anVmeWttbW5hd2Znb3J4cnZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5OTczMDcsImV4cCI6MjA5NjU3MzMwN30.F4Tcl1_bJbcjIIDHhP0ohZf_kzJ6K8khdKANkffbs0Q',
  );

  runApp(const SevenApp());
}

final supabase = Supabase.instance.client;

class SevenApp extends StatelessWidget {
  const SevenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '7even',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050507),
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'p') {
          final username = uri.pathSegments.last;
          return MaterialPageRoute(
            builder: (_) => ProfileViewScreen(username: username),
          );
        }

        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}
