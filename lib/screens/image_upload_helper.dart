import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows dialog to choose between camera or gallery
  static Future<String?> uploadImage(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload to Firebase Storage
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('equipment_images')
          .child('$userId\_$timestamp.jpg');

      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      return downloadUrl;
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Widget to show image picker button with preview
  static Widget buildImagePicker({
    required BuildContext context,
    String? currentImageUrl,
    required Function(String?) onImageSelected,
  }) {
    return Column(
      children: [
        if (currentImageUrl != null && currentImageUrl.isNotEmpty)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  currentImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () => onImageSelected(null),
                ),
              ),
            ],
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final url = await uploadImage(context);
            if (url != null) {
              onImageSelected(url);
            }
          },
          icon: const Icon(Icons.upload),
          label: Text(
            currentImageUrl != null ? 'Change Image' : 'Upload Image',
          ),
        ),
      ],
    );
  }
}

