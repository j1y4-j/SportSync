import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: const Color(0xFF27AE60),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('slots').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No bookings yet", style: TextStyle(fontSize: 16)),
            );
          }

          final allSlots = snapshot.data!.docs;

          final userSlots = allSlots.where((slot) {
            final data = slot.data() as Map<String, dynamic>;
            final bookedUsers = List.from(data['bookedBy'] ?? []);
            bookedUsers.removeWhere((uid) => uid == null || uid == '');
            return bookedUsers.contains(userId);
          }).toList();

          if (userSlots.isEmpty) {
            return const Center(
              child: Text("No bookings yet", style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
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

                  Color getStatusColor(String status) {
                    switch (status) {
                      case 'free':
                        return const Color(0xFF27AE60);
                      case 'booked':
                        return const Color(0xFFF39C12);
                      case 'inuse':
                        return const Color(0xFFE74C3C);
                      default:
                        return Colors.grey;
                    }
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(data['status']).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        courtName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${data['startTime']} - ${data['endTime']} | ${data['status']} (${bookedUsers.length})",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Cancel Booking"),
                              content: Text(
                                "Cancel booking for $courtName, ${data['startTime']} - ${data['endTime']}?",
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

                          final wasBookedByUser = bookedUsers.contains(userId);

                          bookedUsers.remove(userId);

                          // Determine new status
                          String newStatus = bookedUsers.isEmpty
                              ? 'free'
                              : 'booked';

                          // Update slot in Firestore
                          await slot.reference.update({
                            'bookedBy': bookedUsers,
                            'status': newStatus,
                          });

                          // Decrement totalBookings only if user actually had a booking
                          if (wasBookedByUser) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .update({
                                  'totalBookings': FieldValue.increment(-1),
                                });
                          }

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
