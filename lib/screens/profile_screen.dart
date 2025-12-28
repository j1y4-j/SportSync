import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../utils/cleanup.dart';
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
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// USER INFO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email ?? "",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Roll No: ${data['rollNumber'] ?? 'NA'}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _statTile("Trust Score", data['trustScore']),
              _statTile("Credibility", data['credibility']),
              _statTile("Borrower Score", data['borrowerScore']),
              _statTile("Total Bookings", data['totalBookings']),
              _statTile("No Shows", data['noShows']),

              const SizedBox(height: 24),

              /// LOGOUT
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18, // ⬅ increase height
                    horizontal: 20, // ⬅ increase width
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17, // ⬅ text size
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    56,
                  ), // ⬅ fixed height
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),

              const SizedBox(height: 12),

              /// DELETE ACCOUNT
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Account"),
                onPressed: () async {
                  await cleanupUserBookings(userId);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .delete();
                  await FirebaseAuth.instance.currentUser!.delete();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String title, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value?.toString() ?? "0"),
      ),
    );
  }
}
