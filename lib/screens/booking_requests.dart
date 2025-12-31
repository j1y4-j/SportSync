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

              final senderRoll = req.data().toString().contains('fromRoll')
                  ? req['fromRoll']
                  : 'Unknown';

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    "Invite from $senderRoll",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Court ID: ${req['courtId']}"),
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
    if (req['status'] != 'pending') return;

    final db = FirebaseFirestore.instance;
    final toUserId = req['to'];

    final slotRef = db
        .collection('courts')
        .doc(req['courtId'])
        .collection('slots')
        .doc(req['slotId']);

    final userRef = db.collection('users').doc(toUserId);

    await db.runTransaction((tx) async {
      final slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists) {
        throw Exception("Slot not found");
      }

      final data = slotSnap.data()!;
      List<dynamic> bookedBy = List.from(data['bookedBy'] ?? []);
      List<dynamic> invited = List.from(data['invitedUsers'] ?? []);
      final int maxPlayers = data['maxPlayers'] ?? 4;

      if (accept) {
        if (bookedBy.contains(toUserId)) {
          throw Exception("Already booked");
        }

        if (bookedBy.length >= maxPlayers) {
          throw Exception("Slot full");
        }

        bookedBy.add(toUserId);

        // ✅ Increment totalBookings ONLY on accept
        tx.update(userRef, {'totalBookings': FieldValue.increment(1)});
      }

      invited.remove(toUserId);

      tx.update(slotRef, {
        'bookedBy': bookedBy,
        'invitedUsers': invited,
        'status': bookedBy.isEmpty ? 'free' : 'booked',
      });

      tx.update(req.reference, {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
