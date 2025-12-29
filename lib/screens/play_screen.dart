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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Play"), elevation: 2),
      body: Column(
        children: [
          // ---------------- COURTS LIST ----------------
          SizedBox(
            height: 130,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final courts = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    final data = court.data() as Map<String, dynamic>;
                    final isSelected = court.id == selectedCourtId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCourtId = court.id;
                          selectedCourtName = data['name'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(16),
                        width: 180,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade200,
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
                              data['name'] ?? 'Unnamed Court',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['sport'] ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 14,
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

          const Divider(thickness: 1),

          // ---------------- SLOTS ----------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
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
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

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
                            final slot = slotDoc.data() as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: SlotCard(
                                slotId: slotDoc.id,
                                courtId: selectedCourtId!,
                                startTime: slot['startTime'],
                                endTime: slot['endTime'],
                                status: slot['status'],
                                bookedBy: slot['bookedBy'],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
