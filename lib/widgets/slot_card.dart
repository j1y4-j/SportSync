import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotCard extends StatefulWidget {
  final String slotId;
  final String courtId;
  final String startTime;
  final String endTime;
  final String status;
  final List<dynamic>? bookedBy;

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

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
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

  /// ---------- MATCH TYPE ----------
  Future<Map<String, dynamic>?> _selectMatchType() {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            "Choose Match Type",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Singles"),
            subtitle: const Text("Max 2 players"),
            onTap: () => Navigator.pop(context, {
              'matchType': 'singles',
              'maxPlayers': 2,
            }),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text("Doubles"),
            subtitle: const Text("Max 4 players"),
            onTap: () => Navigator.pop(context, {
              'matchType': 'doubles',
              'maxPlayers': 4,
            }),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// ---------- ENTER FRIENDS ----------
  Future<List<String>> _enterFriends(int remainingSlots) async {
    final controller = TextEditingController();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Book with friends"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter up to $remainingSlots roll number(s)"),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "e.g. 241CS230, 241CS216",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final rolls = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.pop(context, rolls);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );

    return result ?? [];
  }

  /// ---------- BOOK SLOT ----------
  Future<void> bookSlot() async {
    if (_isBooking) return;
    _isBooking = true;

    try {
      final db = FirebaseFirestore.instance;
      final slotRef = db
          .collection('courts')
          .doc(widget.courtId)
          .collection('slots')
          .doc(widget.slotId);

      // 1️⃣ READ SLOT DATA
      final slotSnap = await slotRef.get();
      if (!slotSnap.exists) throw "Slot not found";

      final data = slotSnap.data()!;
      List<dynamic> bookedBy = List.from(data['bookedBy'] ?? []);
      bookedBy.removeWhere((e) => e == null || e == '');

      if (bookedBy.contains(currentUserId)) {
        throw "You already booked this slot";
      }

      int maxPlayers = data['maxPlayers'] ?? 0;
      String? matchType = data['matchType'];

      // 2️⃣ FIRST USER → PICK MATCH TYPE
      if (bookedBy.isEmpty) {
        final selection = await _selectMatchType();
        if (selection == null) return;

        matchType = selection['matchType'];
        maxPlayers = selection['maxPlayers'];
      }

      if (bookedBy.length >= maxPlayers) {
        throw "Slot is full";
      }

      // 3️⃣ ASK FRIENDS ONLY IF MORE THAN 1 SLOT AVAILABLE
      List<String> invitedUserIds = [];
      final remainingSlots = maxPlayers - (bookedBy.length + 1);

      bool withFriends = false;
      if (remainingSlots > 0) {
        withFriends =
            await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Book with friends?"),
                content: Text(
                  "You can invite up to $remainingSlots friend(s).",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Solo"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            ) ??
            false;
      }

      if (withFriends) {
        final rolls = await _enterFriends(remainingSlots);

        for (final roll in rolls) {
          final userSnap = await db
              .collection('users')
              .where('rollNumber', isEqualTo: roll)
              .limit(1)
              .get();

          if (userSnap.docs.isNotEmpty) {
            invitedUserIds.add(userSnap.docs.first.id);
          }
        }
      }
      final senderSnap = await db.collection('users').doc(currentUserId).get();
      final senderRoll = senderSnap.data()?['rollNumber'] ?? 'Unknown';

      // 4️⃣ TRANSACTION → UPDATE SLOT SAFELY
      await db.runTransaction((tx) async {
        final freshSnap = await tx.get(slotRef);
        final freshData = freshSnap.data()!;
        List<dynamic> freshBooked = List.from(freshData['bookedBy'] ?? []);
        freshBooked.removeWhere((e) => e == null || e == '');

        if (freshBooked.contains(currentUserId)) {
          throw "You already booked this slot";
        }

        if (freshBooked.length + 1 + invitedUserIds.length > maxPlayers) {
          throw "Not enough slots available";
        }

        freshBooked.add(currentUserId);

        tx.update(slotRef, {
          'bookedBy': freshBooked,
          'status': 'booked',
          'matchType': matchType,
          'maxPlayers': maxPlayers,
          'invitedUsers': FieldValue.arrayUnion(invitedUserIds),
        });

        // 5️⃣ CREATE BOOKING REQUESTS FOR FRIENDS ONLY
        for (final uid in invitedUserIds) {
          final reqRef = db.collection('bookingRequests').doc();
          tx.set(reqRef, {
            'slotId': widget.slotId,
            'courtId': widget.courtId,
            'from': currentUserId,
            'fromRoll': senderRoll, // ✅ THIS IS KEY
            'to': uid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // 6️⃣ INCREMENT TOTAL BOOKINGS FOR CURRENT USER
      await db.collection('users').doc(currentUserId).update({
        'totalBookings': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Slot booked successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      _isBooking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookedCount = widget.bookedBy?.length ?? 0;
    final isBookedByYou = widget.bookedBy?.contains(currentUserId) ?? false;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Material(
          color: getSlotColor(widget.status),
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: bookSlot,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.startTime} - ${widget.endTime}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Status: ${widget.status}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$bookedCount players",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (isBookedByYou)
                        const Text(
                          "Booked by you",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
