import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/gemini_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _geminiService = GeminiService();

  // Cloudinary credentials - REPLACE WITH YOUR VALUES
  static const String cloudName = 'dhjhblduo';
  static const String uploadPreset = 'equipment_images';

  String title = '';
  String category = 'Badminton';
  int price = 0;
  String? imageUrl;
  XFile? _imageFile;
  Uint8List? _imageBytes; // Store bytes for preview
  String durationType = 'per_hour';

  String? aiAnalysis;
  String? aiCondition;

  bool isLoading = false;
  bool isAnalyzing = false;

  final List<String> categories = [
    'Badminton',
    'Cricket',
    'Football',
    'Gym',
  ];

  final ImagePicker _picker = ImagePicker();
  Future<void> testGeminiAPI() async {
    const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.isEmpty || apiKey == 'NOT_FOUND') {
      print(
          '❌ Error: API Key not found. Did you use --dart-define-from-file=secret.json?');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'}
              ]
            }
          ]
        }),
      );

      print('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Success: ${response.body}');
      } else {
        print('❌ Failed: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String?> _uploadToCloudinary(XFile imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      var request = http.MultipartRequest('POST', url);

      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'equipment_images';

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        final responseBody = await response.stream.bytesToString();
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        print('❌ Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      await testGeminiAPI();

      // Read bytes immediately for preview
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
        isAnalyzing = true;
        aiAnalysis = null;
        imageUrl = null; // Clear URL until uploaded
      });

      // Upload to Cloudinary
      final downloadUrl = await _uploadToCloudinary(pickedFile);

      if (downloadUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      setState(() {
        imageUrl = downloadUrl;
      });

      print('✅ Image uploaded to Cloudinary: $downloadUrl');

      // Analyze with Gemini AI
      print('🤖 Starting AI analysis...');
      print('Image size: ${bytes.length} bytes');
      print('Category: $category');

      final analysisResult = await _geminiService.analyzeEquipment(
        imageBytes: bytes,
        category: category,
      );

      print('AI Result: ${analysisResult['success']}');
      if (!analysisResult['success']) {
        print('❌ AI Error: ${analysisResult['error']}');
      }

      setState(() {
        isAnalyzing = false;
        if (analysisResult['success']) {
          aiAnalysis = analysisResult['analysis'];
          aiCondition = analysisResult['condition'];
        } else {
          aiAnalysis = 'AI analysis failed: ${analysisResult['error']}';
          aiCondition = 'Good';
        }
      });

      if (mounted && analysisResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ AI analysis complete!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Overall error: $e');
      setState(() {
        isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

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
        'aiAnalysis': aiAnalysis ?? 'No analysis',
        'aiCondition': aiCondition ?? 'Good',
        'originalImageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment added successfully! 🎉'),
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
      appBar: AppBar(
          title: const Text('Add Equipment'),
          backgroundColor: Color(0xFF2ECC71)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Upload Section
              GestureDetector(
                onTap: isAnalyzing ? null : _pickAndAnalyzeImage,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Take Photo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Color(0xFF2ECC71)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI will analyze quality',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    )
                                  : Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                            ),
                            if (isAnalyzing)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '🤖 AI Analyzing...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              // AI Analysis Display
              if (aiAnalysis != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              aiCondition!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        aiAnalysis!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Equipment Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
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
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
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
                        backgroundColor: Color(0xFF2ECC71),
                      ),
                      child: const Text(
                        'Add Equipment',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
