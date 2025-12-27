import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateBookedBy() async {
  final db = FirebaseFirestore.instance;

  final courtsSnapshot = await db.collection('courts').get();

  for (final court in courtsSnapshot.docs) {
    final slotsSnapshot = await court.reference.collection('slots').get();

    for (final slot in slotsSnapshot.docs) {
      final data = slot.data();

      // If bookedBy is a STRING → convert to LIST
      if (data['bookedBy'] is String) {
        final String oldUser = data['bookedBy'];

        await slot.reference.update({
          'bookedBy': oldUser.isEmpty ? [] : [oldUser],
        });

        print("Fixed slot ${slot.id}");
      }

      // If bookedBy is null → set empty list
      if (!data.containsKey('bookedBy')) {
        await slot.reference.update({'bookedBy': []});
      }
    }
  }

  print("✅ Migration complete");
}
