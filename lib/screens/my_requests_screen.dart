/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rent_requests')
            .where('renterId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No requests yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              Color statusColor;
              if (data['status'] == 'accepted') {
                statusColor = Colors.green;
              } else if (data['status'] == 'rejected') {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.orange;
              }

              return ListTile(
                title: Text(data['equipmentName']),
                subtitle: Text("Status: ${data['status']}"),
                trailing: Icon(Icons.circle, color: statusColor, size: 12),
              );
            },
          );
        },
      ),
    );
  }
}
*/