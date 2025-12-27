import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/slot_card.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String? selectedCourtId;
  String? selectedCourtName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play"),
      ),
      body: Column(
        children: [
          // ---------------- COURTS LIST ----------------
          SizedBox(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading courts"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courts = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    final data =
                        court.data() as Map<String, dynamic>;

                    final isSelected =
                        court.id == selectedCourtId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCourtId = court.id;
                          selectedCourtName = data['name'];
                        });
                      },
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['name'] ?? 'Unnamed Court',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['sport'] ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54,
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
          ),

          const Divider(),

          // ---------------- SLOTS ----------------
          Expanded(
            child: selectedCourtId == null
                ? const Center(
                    child: Text(
                      "Select a court to view slots",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('courts')
                        .doc(selectedCourtId!)
                        .collection('slots')
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text("Error loading slots"));
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final slots = snapshot.data!.docs;

                      if (slots.isEmpty) {
                        return const Center(
                          child: Text("No slots available"),
                        );
                      }

                      return ListView.builder(
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slotDoc = slots[index];
                          final slot =
                              slotDoc.data() as Map<String, dynamic>;

                          return SlotCard(
                            slotId: slotDoc.id,
                            courtId: selectedCourtId!,
                            startTime: slot['startTime'],
                            endTime: slot['endTime'],
                            status: slot['status'],
                            bookedBy: slot['bookedBy'],
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
