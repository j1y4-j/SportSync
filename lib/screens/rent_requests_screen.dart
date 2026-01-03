import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_screen.dart';
import 'chat_screen.dart';

class RentRequestsScreen extends StatelessWidget {
  const RentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Rent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rent_requests')
            .where('ownerId', isEqualTo: ownerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['equipmentName']),
                  subtitle: Text("Status: ${data['status']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          userId: data['renterId'],
                        ),
                      ),
                    );
                  },
                  trailing: _buildTrailingWidget(context, doc.id, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, String docId, Map<String, dynamic> data) {
    if (data['status'] == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accepting request...')),
                );
                
                await _accept(docId, data);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request accepted! Chat created.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _reject(docId),
          ),
        ],
      );
    } else if (data['status'] == 'accepted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.blue),
            tooltip: 'Open Chat',
            onPressed: () {
              if (data['chatId'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: data['chatId'],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat not available'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          Text(
            "Accepted ✅",
            style: TextStyle(color: Colors.green),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.orange),
            tooltip: 'Cancel Rent',
            onPressed: () => _showCancelDialog(context, docId, data),
          ),
        ],
      );
    } else {
      return Text(
        "Rejected ❌",
        style: TextStyle(color: Colors.red),
      );
    }
  }

  static void _showCancelDialog(BuildContext context, String requestId, Map data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Rent"),
        content: Text(
          "Are you sure you want to cancel the rent for '${data['equipmentName']}'? This will make the equipment available again."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelRent(requestId, data);
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Future<String> _accept(String requestId, Map data) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final chatId = firestore.collection('chats').doc().id;

    final requestRef = firestore.collection('rent_requests').doc(requestId);
    final equipmentRef = firestore.collection('equipment').doc(data['equipmentId']);
    final chatRef = firestore.collection('chats').doc(chatId);

    batch.update(requestRef, {
      'status': 'accepted',
      'chatId': chatId,
    });

    batch.update(equipmentRef, {
      'available': false,
      'rentedBy': data['renterId'],
    });

    batch.set(chatRef, {
      'chatId': chatId,
      'equipmentId': data['equipmentId'],
      'equipmentName': data['equipmentName'], // Add equipment name for display
      'participants': [
        data['ownerId'],
        data['renterId'],
      ],
      'lastMessage': 'Chat created',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    
    // Debug: Print to console
    print('Chat created with ID: $chatId');
    
    return chatId;
  }

  static Future<void> _reject(String requestId) async {
    await FirebaseFirestore.instance
        .collection('rent_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  static Future<void> _cancelRent(String requestId, Map data) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final requestRef = firestore.collection('rent_requests').doc(requestId);
    final equipmentRef = firestore.collection('equipment').doc(data['equipmentId']);

    // Update request status to cancelled
    batch.update(requestRef, {
      'status': 'cancelled',
    });

    // Make equipment available again
    batch.update(equipmentRef, {
      'available': true,
      'rentedBy': FieldValue.delete(),
    });

    // Optional: Delete the chat or mark it as closed
    if (data['chatId'] != null) {
      final chatRef = firestore.collection('chats').doc(data['chatId']);
      batch.delete(chatRef);
      // OR mark as closed: batch.update(chatRef, {'closed': true});
    }

    await batch.commit();
  }
}
/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_screen.dart';
import 'chat_screen.dart';
class RentRequestsScreen extends StatelessWidget {
  const RentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Rent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rent_requests')
            .where('ownerId', isEqualTo: ownerId)
      
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['equipmentName']),
                  subtitle: Text("Status: ${data['status']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          userId: data['renterId'],
                        ),
                      ),
                    );
                  },
                  
                  trailing: data['status'] == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _accept(doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _reject(doc.id),
                            ),
                          ],
                        )
                      : Text(
                          data['status'] == 'accepted' ? "Accepted ✅" : "Rejected ❌",
                          style: TextStyle(
                            color: data['status'] == 'accepted' ? Colors.green : Colors.red,
                          ),
                        ),
                  

                ),
              );
            },
          );
        },
      ),
    );
  }

        static Future<String> _accept(String requestId, Map data) async {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final chatId = firestore.collection('chats').doc().id;

      final requestRef =
          firestore.collection('rent_requests').doc(requestId);

      final equipmentRef =
          firestore.collection('equipment').doc(data['equipmentId']);

      final chatRef =
          firestore.collection('chats').doc(chatId);

      batch.update(requestRef, {
        'status': 'accepted',
        'chatId': chatId,
      });

      batch.update(equipmentRef, {
        'available': false,
        'rentedBy': data['renterId'],
      });

      batch.set(chatRef, {
        'chatId': chatId,
        'equipmentId': data['equipmentId'],
        'participants': [
          data['ownerId'],
          data['renterId'],
        ],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return chatId; // 🔥 IMPORTANT
    }


  static Future<void> _reject(String requestId) async {
    await FirebaseFirestore.instance
        .collection('rent_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }
}
*/