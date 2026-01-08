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
  final String? currentBorrowerId;
  final String? originalImageUrl;
  final String? aiAnalysis;
  final String? aiCondition;
  final VoidCallback onRequest;
  final VoidCallback? onReturn;

  const EquipmentCard({
    super.key,
    required this.equipmentId,
    required this.title,
    required this.imageUrl,
    required this.ownerId,
    required this.price,
    required this.durationType,
    required this.available,
    this.currentBorrowerId,
    this.originalImageUrl,
    this.aiAnalysis,
    this.aiCondition,
    required this.onRequest,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final bool showReturnButton = onReturn != null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Equipment Image with AI Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 130,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),

              // AI Condition Badge
              if (aiCondition != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(aiCondition!),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          aiCondition!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final ownerName = data?['name'] ?? 'Unknown';

                    return SizedBox(
                      height: 16,
                      child: Text(
                        "Owner: $ownerName",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                // AI Analysis Preview (if available)
                if (aiAnalysis != null && aiAnalysis!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            aiAnalysis!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[800],
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: available ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Action Buttons
                if (available)
                  // Request Rent Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Request Rent"),
                    ),
                  )
                else if (showReturnButton)
                  // Return Equipment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.assignment_return, size: 18),
                      label: const Text("Return Equipment"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  // Unavailable Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      child: const Text("Unavailable"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
