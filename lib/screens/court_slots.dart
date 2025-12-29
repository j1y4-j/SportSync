import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class CourtSlotsScreen extends StatelessWidget {
  final String courtId;
  final String courtName;

  const CourtSlotsScreen({
    super.key,
    required this.courtId,
    required this.courtName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(courtName), elevation: 2),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('courts')
            .doc(courtId)
            .collection('slots')
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = snapshot.data!.docs;

          if (slots.isEmpty) {
            return const Center(
              child: Text(
                "No slots available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final slotData = slot.data() as Map<String, dynamic>;
              final status = slotData['status'];

              Color getSlotColor(String status) {
                switch (status) {
                  case 'free':
                    return Colors.green.shade400;
                  case 'booked':
                    return Colors.orange.shade400;
                  case 'inuse':
                    return Colors.red.shade400;
                  default:
                    return Colors.grey.shade400;
                }
              }

              return GestureDetector(
                onTap: () async {
                  if (status == 'free') {
                    await slot.reference.update({'status': 'booked'});
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getSlotColor(status),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${slotData['startTime']} - ${slotData['endTime']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
