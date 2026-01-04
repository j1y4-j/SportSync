/*import 'package:flutter/material.dart';
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
*/




import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_upload_helper.dart'; // Import the helper

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
  String? imageUrl; // Changed to nullable
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

    // Check if image is uploaded
    if (imageUrl == null || imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an equipment image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('equipment').add({
        'title': title,
        'category': category,
        'price': price,
        'durationType': durationType,
        'imageUrl': imageUrl,
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'User',
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
              // Image Upload Section
              ImageUploadHelper.buildImagePicker(
                context: context,
                currentImageUrl: imageUrl,
                onImageSelected: (url) {
                  setState(() {
                    imageUrl = url;
                  });
                },
              ),

              const SizedBox(height: 24),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Equipment Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter title' : null,
                onSaved: (v) => title = v!.trim(),
              ),

              const SizedBox(height: 16),

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
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter price' : null,
                onSaved: (v) => price = int.parse(v!),
              ),

              const SizedBox(height: 16),

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
                decoration: const InputDecoration(
                  labelText: 'Duration Type',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'Add Equipment',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}