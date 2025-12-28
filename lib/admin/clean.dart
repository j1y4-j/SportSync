import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteUserAndCleanup(String userId) async {
  final db = FirebaseFirestore.instance;

  // Get all slots where user is in bookedBy
  final slotsQuery = await db
      .collectionGroup('slots')
      .where('bookedBy', arrayContains: userId)
      .get();

  for (var slot in slotsQuery.docs) {
    List<dynamic> bookedUsers = List.from(slot['bookedBy'] ?? []);
    print("Slot ID: ${slot.id}, Original bookedBy: ${slot['bookedBy']}");

    // Remove only valid UID matches
    bookedUsers.removeWhere((uid) => uid == null || uid == '' || uid == userId);

    // Determine new slot status
    String newStatus;
    if (bookedUsers.isEmpty) {
      newStatus = 'free';
    } else if (bookedUsers.length == 1) {
      newStatus = 'booked';
    } else {
      newStatus = 'booked'; // booked until QR scan; do not set inuse here
    }

    // Update slot document
    await slot.reference.update({'bookedBy': bookedUsers, 'status': newStatus});
  }

  // Delete user document
  await db.collection('users').doc(userId).delete();

  print("✅ User $userId deleted and all their bookings cleaned up.");
}
