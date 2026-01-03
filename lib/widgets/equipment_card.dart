import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentCard extends StatelessWidget {
  final String equipmentId;
  final String title;
  final String imageUrl;
  final String ownerId;
  final int price;
  final String durationType;
  final bool available;
  final VoidCallback onRequest;

  const EquipmentCard({
    super.key,
    required this.equipmentId,
    required this.title,
    required this.imageUrl,
    required this.ownerId,
    required this.price,
    required this.durationType,
    required this.available,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Equipment Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                /// Owner Name (fetched from users collection)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(ownerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text(
                        "Owner: ...",
                        style: TextStyle(fontSize: 12),
                      );
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final ownerName = data['name'] ?? 'Unknown';

                    return SizedBox(
                      height: 16, // 🔒 lock vertical height
                      child: Text(
                        "Owner: $ownerName",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                /// Price + Availability
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹$price / ${durationType == 'per_hour' ? 'hour' : 'day'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        available ? "Available" : "Unavailable",
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          available ? Colors.green : Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Request Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: available ? onRequest : null,
                    child: const Text("Request Rent"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
