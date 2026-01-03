import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRentRequestScreen extends StatelessWidget {
  final String equipmentId;
  final String equipmentName;
  final String ownerId;

  const CreateRentRequestScreen({
    super.key,
    required this.equipmentId,
    required this.equipmentName,
    required this.ownerId,
  });

  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get();

await FirebaseFirestore.instance.collection('rent_requests').add({
  'equipmentId': equipmentId,
  'equipmentName': equipmentName,
  'ownerId': ownerId,
  'renterId': user.uid,
  'renterName': userDoc.data()?['name'] ?? 'Unknown',
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
});


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rent request sent')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Rent")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendRequest(context),
          child: const Text("Send Rent Request"),
        ),
      ),
    );
  }
}




