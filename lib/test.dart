import 'package:cloud_firestore/cloud_firestore.dart';

/// Call this function before runApp in main.dart
Future<void> restoreUsers() async {
  final firestore = FirebaseFirestore.instance;

  // Step 1: Delete existing users collection (optional)
  final usersSnap = await firestore.collection('users').get();
  for (var doc in usersSnap.docs) {
    await doc.reference.delete();
  }
  print("Deleted existing users collection.");

  // Step 2: Get all unique user IDs from slots
  final slotsSnap = await firestore.collectionGroup('slots').get();
  final Set<String> userIds = {};

  for (var slot in slotsSnap.docs) {
    final bookedBy = List<String>.from(slot.data()['bookedBy'] ?? []);
    for (var uid in bookedBy) {
      if (uid != null && uid.isNotEmpty) {
        userIds.add(uid);
      }
    }
  }

  print("Found ${userIds.length} unique users in booked slots.");

  // Step 3: Create user documents with numeric defaults & friends array
  for (var uid in userIds) {
    await firestore.collection('users').doc(uid).set({
      'name': '',
      'skillLevel': 'NA',
      'credibility': 100,
      'trustScore': 100,
      'borrowerScore': 100,
      'totalBookings': 0, // will update next
      'noShows': 0,
      'friends': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("Created user document for UID: $uid");
  }

  // Step 4: Count booked slots per user
  final Map<String, int> bookingsCount = {};
  for (var slot in slotsSnap.docs) {
    final bookedBy = List<String>.from(slot.data()['bookedBy'] ?? []);
    for (var uid in bookedBy) {
      if (uid != null && uid.isNotEmpty) {
        bookingsCount[uid] = (bookingsCount[uid] ?? 0) + 1;
      }
    }
  }

  // Step 5: Update each user's totalBookings field
  for (var uid in userIds) {
    final total = bookingsCount[uid] ?? 0;
    await firestore.collection('users').doc(uid).update({
      'totalBookings': total,
    });
    print("Updated totalBookings for UID: $uid -> $total");
  }

  print("Restore users completed successfully!");
}
