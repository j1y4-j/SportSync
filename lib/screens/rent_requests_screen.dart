import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentRequestsScreen extends StatelessWidget {
  const RentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Rent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rent_requests')
            .where('ownerId', isEqualTo: ownerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No rent requests"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              return Card(
                child: ListTile(
                  title: Text(data['equipmentName']),
                  subtitle: Text("Requested by ${data['renterName']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _updateStatus(data.id, 'rejected'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(data),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String requestId, String status) {
    return FirebaseFirestore.instance
        .collection('rent_requests')
        .doc(requestId)
        .update({'status': status});
  }

  Future<void> _acceptRequest(QueryDocumentSnapshot request) async {
    final firestore = FirebaseFirestore.instance;

    // Update request
    await firestore.collection('rent_requests').doc(request.id).update({
      'status': 'accepted',
    });

    // Create chat
    await firestore.collection('chats').add({
      'equipmentId': request['equipmentId'],
      'ownerId': request['ownerId'],
      'renterId': request['renterId'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
