import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('to', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No booking requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: const Text("Booking Invite"),
                  subtitle: Text("Court: ${req['courtId']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleRequest(req, accept: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleRequest(req, accept: false),
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

  Future<void> _handleRequest(
    QueryDocumentSnapshot req, {
    required bool accept,
  }) async {
    final db = FirebaseFirestore.instance;
    final slotRef = db
        .collection('courts')
        .doc(req['courtId'])
        .collection('slots')
        .doc(req['slotId']);

    await db.runTransaction((tx) async {
      final slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists) return;

      final data = slotSnap.data()!;
      List bookedBy = List.from(data['bookedBy'] ?? []);
      List invited = List.from(data['invitedUsers'] ?? []);
      final maxPlayers = data['maxPlayers'] ?? 4;

      if (accept) {
        if (bookedBy.length >= maxPlayers) {
          throw Exception("Slot full");
        }
        bookedBy.add(req['to']);
      }

      invited.remove(req['to']);

      tx.update(slotRef, {'bookedBy': bookedBy, 'invitedUsers': invited});

      tx.update(req.reference, {'status': accept ? 'accepted' : 'rejected'});
    });
  }
}
