import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// REGISTER USER WITH EMAIL, PASSWORD, AND ROLL NUMBER
  Future<void> register(
    String email,
    String password,
    String rollNumber,
  ) async {
    // Create user in Firebase Auth
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCred.user!.uid;

    // Initialize Firestore user document
    await _db.collection('users').doc(uid).set({
      'email': email,
      'rollNumber': rollNumber,
      'friends': [],
      'skillLevel': 'NA', // optional, can be updated later
      'credibility': 100, // optional numeric field
      'trustScore': 100, // optional numeric field
      'borrowerScore': 100, // optional numeric field
      'totalBookings': 0,
      'noShows': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// LOGIN USER
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    // Ensure Firestore user doc exists to avoid "user data not found"
    await ensureUserDoc();
  }

  /// ENSURE USER DOCUMENT EXISTS
  Future<void> ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        'email': user.email,
        'rollNumber': '',
        'friends': [],
        'skillLevel': 'NA',
        'credibility': 100,
        'trustScore': 100,
        'borrowerScore': 100,
        'totalBookings': 0,
        'noShows': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
