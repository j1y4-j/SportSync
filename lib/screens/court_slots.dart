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
      appBar: AppBar(title: Text(courtName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('courts')
            .doc(courtId)
            .collection('slots')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final status = slot['status'];

              Color color;
              if (status == 'free') {
                color = Colors.green;
              } else if (status == 'booked') {
                color = Colors.orange;
              } else {
                color = Colors.red;
              }

              return GestureDetector(
                onTap: () async {
                  if (status == 'free') {
                    await slot.reference.update({
                      'status': 'booked',
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "${slot['startTime']} - ${slot['endTime']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
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
}
