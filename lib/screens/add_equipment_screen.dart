import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String category = 'Badminton';
  int price = 0;
  String imageUrl = '';
  String durationType = 'per_hour';

  bool isLoading = false;

  final List<String> categories = [
    'Badminton',
    'Cricket',
    'Football',
    'Gym',
  ];

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('equipment').add({
        'title': title,
        'category': category,
        'price': price,
        'durationType': durationType,
        'imageUrl': imageUrl.isEmpty
            ? 'https://via.placeholder.com/300'
            : imageUrl,
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'User',
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Equipment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Equipment Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter title' : null,
                onSaved: (v) => title = v!.trim(),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: category,
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
                decoration:
                    const InputDecoration(labelText: 'Category'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter price' : null,
                onSaved: (v) => price = int.parse(v!),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: durationType,
                items: const [
                  DropdownMenuItem(
                    value: 'per_hour',
                    child: Text('Per Hour'),
                  ),
                  DropdownMenuItem(
                    value: 'per_day',
                    child: Text('Per Day'),
                  ),
                ],
                onChanged: (v) => setState(() => durationType = v!),
                decoration:
                    const InputDecoration(labelText: 'Duration Type'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Image URL (optional)'),
                onSaved: (v) => imageUrl = v!.trim(),
              ),

              const SizedBox(height: 24),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submit,
                      child: const Text('Add Equipment'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
