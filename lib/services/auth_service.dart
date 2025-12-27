import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Register a new user and initialize Firestore user document
  Future<void> register(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCred.user!.uid;

    // Initialize Firestore user document with proper numeric defaults
    await _db.collection('users').doc(uid).set({
      'name': '',
      'skillLevel': 'NA', // keep as string for display
      'credibility': 100, // numeric starting value
      'trustScore': 100, // numeric starting value
      'borrowerScore': 100, // numeric starting value
      'totalBookings': 0, // numeric
      'noShows': 0, // numeric
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Login an existing user
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}
