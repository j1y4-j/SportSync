import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(data['name'][0]),
                ),
                const SizedBox(height: 12),
                Text(
                  data['name'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text("Roll: ${data['rollNumber']}"),
                const Divider(),
                _row("Trust Score", data['trustScore']),
                _row("Credibility", data['credibility']),
                _row("Borrower Score", data['borrowerScore']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value?.toString() ?? "NA"),
    );
  }
}
