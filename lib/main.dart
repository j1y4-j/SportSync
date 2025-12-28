import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';

/// GLOBAL THEME CONTROLLER
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,

          /// 🌤️ PLAYO-LIKE LIGHT THEME
          theme: _lightTheme(),

          /// 🌙 OPTIONAL DARK THEME
          darkTheme: _darkTheme(),

          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// ================= LIGHT THEME =================
/// Primary identity (Playo-like)
ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFFF6F7F9),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // Playo green
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );
}

/// ================= DARK THEME =================
/// Optional, calm, professional
ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFF121212),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF81C784),
      brightness: Brightness.dark,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
