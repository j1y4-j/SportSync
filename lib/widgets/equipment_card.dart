import 'package:flutter/material.dart';

class EquipmentCard extends StatelessWidget {
  final String equipmentId;
  final String title;
  final String imageUrl;
  final String ownerName;
  final int price;
  final String durationType;
  final bool available;
  final VoidCallback onRequest;

  const EquipmentCard({
    super.key,
    required this.equipmentId,
    required this.title,
    required this.imageUrl,
    required this.ownerName,
    required this.price,
    required this.durationType,
    required this.available,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  "Owner: $ownerName",
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 8),

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
