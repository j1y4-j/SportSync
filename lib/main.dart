import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sports_sync/test.dart';
import 'firebase_options.dart'; // ✅ must import
// import '../services/login.dart'; // path to your login screen
import 'auth_wrapper.dart';

// import 'admin/addFriends.dart';
// import 'admin/migrate_bookedby.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white, // title + icons
          centerTitle: true,
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}
