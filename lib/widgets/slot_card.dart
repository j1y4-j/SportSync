import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotCard extends StatelessWidget {
  final String slotId;
  final String courtId;
  final String startTime;
  final String endTime;
  final String status;
  final List<dynamic>? bookedBy; // array of UIDs

  const SlotCard({
    super.key,
    required this.slotId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookedBy,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    Color getSlotColor(String status) {
      switch (status) {
        case 'free':
          return Colors.green;
        case 'booked':
          return Colors.orange;
        case 'inuse':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () async {
        final slotRef = FirebaseFirestore.instance
            .collection('courts')
            .doc(courtId)
            .collection('slots')
            .doc(slotId);

        final slotSnap = await slotRef.get();
        final data = slotSnap.data() as Map<String, dynamic>;

        List<dynamic> bookedUsers = List.from(data['bookedBy'] ?? []);
        bookedUsers.removeWhere((uid) => uid == null || uid == '');

        // Already booked by user?
        if (bookedUsers.contains(currentUserId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You already booked this slot")),
          );
          return;
        }

        // Max players reached
        if (bookedUsers.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Slot is full (Max 4 players)")),
          );
          return;
        }

        // Confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Booking"),
            content: Text(
              "Do you want to book this slot?\n$startTime - $endTime",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // Add current user to bookedBy array
        bookedUsers.add(currentUserId);

        // Status stays 'booked' until actual play
        await slotRef.update({'bookedBy': bookedUsers, 'status': 'booked'});

        // Increment user's total bookings
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'totalBookings': FieldValue.increment(1)});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Slot booked successfully")),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: getSlotColor(status),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Slot time
            Text(
              "$startTime - $endTime",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Status + Player count + "Booked by you"
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$status (${bookedBy?.where((uid) => uid != null && uid != '').length ?? 0}/4)",
                  style: const TextStyle(color: Colors.white),
                ),
                if (bookedBy?.contains(currentUserId) == true)
                  const Text(
                    "Booked by you",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
