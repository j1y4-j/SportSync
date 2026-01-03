import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';


class MyRentRequestsScreen extends StatelessWidget {
  const MyRentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Rent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rent_requests')
            .where('renterId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data =
                  requests[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['equipmentName']),
                subtitle: Text("Status: ${data['status']}"),
                trailing: data['status'] == 'accepted' && data['chatId'] != null
                    ? ElevatedButton(
                        child: const Text("Chat"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: data['chatId'],
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              );

            },
          );
        },
      ),
    );
  }
}
