import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'models/game_provider.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (SupabaseConfig.url.isNotEmpty &&
        SupabaseConfig.anonKey.isNotEmpty &&
        SupabaseConfig.anonKey != 'YOUR_SUPABASE_ANON_KEY') {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      SupabaseConfig.isInitialized = true;
    } else {
      debugPrint('Supabase is not initialized: URL or Anon Key is missing or placeholder.');
    }
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }
  
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
