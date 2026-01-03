import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_screen.dart';
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
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['equipmentName']),
                  subtitle: Text("Requested by ${data['renterName']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          userId: data['renterId'],
                        ),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _accept(doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _reject(doc.id),
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

  static Future<void> _accept(String requestId, Map data) async {
    final batch = FirebaseFirestore.instance.batch();

    final requestRef =
        FirebaseFirestore.instance.collection('rent_requests').doc(requestId);
    final equipmentRef =
        FirebaseFirestore.instance.collection('equipment').doc(data['equipmentId']);

    batch.update(requestRef, {'status': 'accepted'});
    batch.update(equipmentRef, {
      'available': false,
      'rentedBy': data['renterId'],
    });

    await batch.commit();
  }

  static Future<void> _reject(String requestId) async {
    await FirebaseFirestore.instance
        .collection('rent_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }
}
