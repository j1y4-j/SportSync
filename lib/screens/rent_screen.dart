import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_equipment_screen.dart';
import '../../widgets/equipment_card.dart';
import 'rent_requests_screen.dart';
import 'create_rent_request.dart';
import 'my_rent_requests_screen.dart';
import 'return_equipment_screen.dart'; 


class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  String? selectedCategory;

  final List<String> categories = [
    'All',
    
    'Badminton',
    'Cricket',
    'Football',
    'Gym',
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rent"),
        elevation: 2,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rent_requests')
                .where('ownerId', isEqualTo: userId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RentRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyRentRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------------- CATEGORY LIST ----------------
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory ||
                    (selectedCategory == null && category == 'All');

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category == 'All' ? null : category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 1),

          // ---------------- EQUIPMENT LIST (SWIPEABLE) ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipment')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final equipmentDocs = snapshot.data!.docs;

                if (equipmentDocs.isEmpty) {
                  return const Center(
                    child: Text("No equipment available"),
                  );
                }

                // FILTER BY CATEGORY
                final filteredDocs = selectedCategory == null
                    ? equipmentDocs
                    : equipmentDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['category'] == selectedCategory;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No equipment in this category"),
                  );
                }

                return PageView.builder(
                  itemCount: filteredDocs.length,
                  padEnds: false,
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    final isBorrowedByMe =
                        data['currentBorrowerId'] == currentUserId;
                    final isOwnedByMe = data['ownerId'] == currentUserId;
                    final isAvailable = data['available'] ?? true;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      child: EquipmentCard(
                        equipmentId: filteredDocs[index].id,
                        title: data['title'] ?? 'Unknown',
                        imageUrl: data['imageUrl'] ?? '',
                        ownerId: data['ownerId'] ?? '',
                        price: data['price'] ?? 0,
                        durationType: data['durationType'] ?? 'per_hour',
                        available: isAvailable,
                        currentBorrowerId: data['currentBorrowerId'],
                        originalImageUrl:
                            data['originalImageUrl'] ?? data['imageUrl'],
                        aiAnalysis: data['aiAnalysis'], // Pass AI analysis
                        aiCondition: data['aiCondition'], // Pass AI condition
                        onRequest: () {
                          if (isOwnedByMe) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("You own this equipment")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateRentRequestScreen(
                                equipmentId: filteredDocs[index].id,
                                equipmentName: data['title'],
                                ownerId: data['ownerId'],
                              ),
                            ),
                          );
                        },
                        onReturn: isBorrowedByMe
                            ? () {
                                // Navigate to Return Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReturnEquipmentScreen(
                                      equipmentId: filteredDocs[index].id,
                                      equipmentTitle:
                                          data['title'] ?? 'Equipment',
                                      originalImageUrl:
                                          data['originalImageUrl'] ??
                                              data['imageUrl'] ??
                                              '',
                                      borrowerUserId: currentUserId,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh the list after returning
                                  setState(() {});
                                });
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEquipmentScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
