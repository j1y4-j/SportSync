import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('slots').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          // Filter slots booked by current user
          final allSlots = snapshot.data!.docs;
          final userSlots = allSlots.where((slot) {
            final data = slot.data() as Map<String, dynamic>;
            final bookedUsers = List.from(data['bookedBy'] ?? []);
            bookedUsers.removeWhere((uid) => uid == null || uid == '');
            return bookedUsers.contains(userId);
          }).toList();

          if (userSlots.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          return ListView.builder(
            itemCount: userSlots.length,
            itemBuilder: (context, index) {
              final slot = userSlots[index];
              final data = slot.data() as Map<String, dynamic>;
              final bookedUsers = List.from(data['bookedBy'] ?? []);
              bookedUsers.removeWhere((uid) => uid == null || uid == '');

              final courtId = slot.reference.parent.parent!.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('courts')
                    .doc(courtId)
                    .get(),
                builder: (context, courtSnap) {
                  final courtName = courtSnap.hasData
                      ? (courtSnap.data!.data()
                                as Map<String, dynamic>)['name'] ??
                            'Court'
                      : 'Court';

                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text(courtName),
                      subtitle: Text(
                        "${data['startTime']} - ${data['endTime']} | ${data['status']} (${bookedUsers.length}/4)",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          // Confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Cancel Booking"),
                              content: Text(
                                "Do you want to cancel this booking for $courtName, ${data['startTime']} - ${data['endTime']}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("No"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Yes"),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          // Remove current user from bookedBy
                          bookedUsers.remove(userId);

                          // Decide new slot status
                          String newStatus;
                          if (bookedUsers.isEmpty) {
                            newStatus = 'free';
                          } else {
                            newStatus =
                                'booked'; // still booked if others remain
                          }

                          // Update slot in Firestore
                          await slot.reference.update({
                            'bookedBy': bookedUsers,
                            'status': newStatus,
                          });

                          // Decrement user's total bookings
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .update({
                                'totalBookings': FieldValue.increment(-1),
                              });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking cancelled")),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
