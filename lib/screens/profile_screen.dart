import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/cleanup.dart'; // 👈 where cleanupUserBookings lives
import '../screens/login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// USER EMAIL
                Text(
                  user.email ?? "No email",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// USER ROLL NUMBER
                Text(
                  "Roll Number: ${data['rollNumber'] ?? 'NA'}",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                /// SCORES
                _scoreTile("Trust Score", data['trustScore']),
                _scoreTile("Credibility", data['credibility']),
                _scoreTile("Borrower Score", data['borrowerScore']),
                _scoreTile("Total Bookings", data['totalBookings']),
                _scoreTile("No Shows", data['noShows']),

                const Spacer(),

                /// LOGOUT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text("Logout"),
                  ),
                ),

                const SizedBox(height: 12),

                /// DELETE ACCOUNT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Account"),
                          content: const Text(
                            "This will cancel all your bookings and permanently delete your account.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      // ✅ CLEAN UP BOOKINGS
                      await cleanupUserBookings(userId);

                      // ✅ DELETE USER DOC
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .delete();

                      // ✅ DELETE AUTH ACCOUNT
                      await FirebaseAuth.instance.currentUser!.delete();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text("Delete Account"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// SMALL HELPER WIDGET
  Widget _scoreTile(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value?.toString() ?? "NA"),
        ],
      ),
    );
  }
}
