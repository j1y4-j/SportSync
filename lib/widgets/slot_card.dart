import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotCard extends StatefulWidget {
  final String slotId;
  final String courtId;
  final String startTime;
  final String endTime;
  final String status;
  final List<dynamic>? bookedBy; // array of UIDs

  const SlotCard({
    super.key,
    required this.slotId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookedBy,
  });

  @override
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.05,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Future<void> bookSlot() async {
    final slotRef = FirebaseFirestore.instance
        .collection('courts')
        .doc(widget.courtId)
        .collection('slots')
        .doc(widget.slotId);

    final slotSnap = await slotRef.get();
    final data = slotSnap.data() as Map<String, dynamic>;
    List<dynamic> bookedUsers = List.from(data['bookedBy'] ?? []);
    bookedUsers.removeWhere((uid) => uid == null || uid == '');

    if (bookedUsers.contains(currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already booked this slot")),
      );
      return;
    }

    if (bookedUsers.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slot is full (Max 4 players)")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text(
          "Do you want to book this slot?\n${widget.startTime} - ${widget.endTime}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    bookedUsers.add(currentUserId);
    await slotRef.update({'bookedBy': bookedUsers, 'status': 'booked'});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'totalBookings': FieldValue.increment(1)});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Slot booked successfully")));
  }

  @override
  Widget build(BuildContext context) {
    final bookedCount =
        widget.bookedBy?.where((uid) => uid != null && uid != '').length ?? 0;
    final isBookedByYou = widget.bookedBy?.contains(currentUserId) ?? false;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        bookSlot();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Material(
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          color: getSlotColor(widget.status),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: bookSlot,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Slot time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.startTime} - ${widget.endTime}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Status: ${widget.status}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Player info / "Booked by you"
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$bookedCount / 4 players",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (isBookedByYou)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Booked by you",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
