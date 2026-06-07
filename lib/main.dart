import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/game_provider.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xnlwdscfszfapqizzxej.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhubHdkc2Nmc3pmYXBxaXp6eGVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MTcwMTgsImV4cCI6MjA5NjI5MzAxOH0.2cxNRmFnf2eTOfwmprg0HT_tPe9bBQGpSTxrwd3RpX0',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XOXOXO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),     // Neon Cyan
          secondary: Color(0xFFFF007F),   // Neon Magenta
          background: Color(0xFF0F172A),  // Deep Slate Blue
          surface: Color(0xFF1E293B),     // Frosted Slate
        ),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}
