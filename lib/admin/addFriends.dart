import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addFriendsFieldToAllUsers() async {
  final usersRef = FirebaseFirestore.instance.collection('users');
  final usersSnap = await usersRef.get();

  for (var userDoc in usersSnap.docs) {
    final data = userDoc.data();
    if (!data.containsKey('friends')) {
      await userDoc.reference.update({'friends': []});
      print('Updated user: ${userDoc.id}');
    }
  }
}
