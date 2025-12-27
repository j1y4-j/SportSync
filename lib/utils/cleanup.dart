import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cleanupUserBookings(String userId) async {
  final db = FirebaseFirestore.instance;

  final slots = await db
      .collectionGroup('slots')
      .where('bookedBy', arrayContains: userId)
      .get();

  for (final slot in slots.docs) {
    final data = slot.data();
    List<dynamic> users = List.from(data['bookedBy']);

    users.remove(userId);

    String newStatus;
    if (users.isEmpty) {
      newStatus = 'free';
    } else if (users.length == 1) {
      newStatus = 'booked';
    } else {
      newStatus = 'inuse';
    }

    await slot.reference.update({'bookedBy': users, 'status': newStatus});
  }
}
