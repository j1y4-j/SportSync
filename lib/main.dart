import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ must import
import '../services/login.dart'; // path to your login screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Pass the options from your firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          LoginScreen(), // ✅ do NOT use const here since LoginScreen has controllers
    );
  }
}
