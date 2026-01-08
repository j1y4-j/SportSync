import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';

// Dark mode notifier
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
      builder: (context, currentTheme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentTheme,

          // ---------------- LIGHT THEME ----------------
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF2ECC71),
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 2,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.grey.shade100,
              selectedItemColor: const Color(0xFF2ECC71),
              unselectedItemColor: Colors.grey.shade600,
              type: BottomNavigationBarType.fixed,
            ),
          ),

          // ---------------- DARK THEME ----------------
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color.fromARGB(255, 66, 70, 68),
            scaffoldBackgroundColor: Colors.grey.shade900,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(255, 53, 54, 54),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 2,
            ),
            cardTheme: CardThemeData(
              color: Colors.grey.shade800,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 78, 78, 78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.grey.shade900,
              selectedItemColor: const Color.fromARGB(255, 57, 58, 57),
              unselectedItemColor: Colors.grey.shade400,
              type: BottomNavigationBarType.fixed,
            ),
          ),

          home: const AuthWrapper(),
        );
      },
    );
  }
}
