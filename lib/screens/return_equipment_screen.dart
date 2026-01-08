import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/gemini_service.dart';

class ReturnEquipmentScreen extends StatefulWidget {
  final String equipmentId;
  final String equipmentTitle;
  final String originalImageUrl;
  final String borrowerUserId;

  const ReturnEquipmentScreen({
    super.key,
    required this.equipmentId,
    required this.equipmentTitle,
    required this.originalImageUrl,
    required this.borrowerUserId,
  });

  @override
  State<ReturnEquipmentScreen> createState() => _ReturnEquipmentScreenState();
}

class _ReturnEquipmentScreenState extends State<ReturnEquipmentScreen> {
  final _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  // Cloudinary credentials - REPLACE WITH YOUR VALUES
  static const String cloudName = 'dhjhblduo';
  static const String uploadPreset = 'equipment_images';

  XFile? _returnImage; // Changed from File to XFile
  String? _returnImageUrl; // Store Cloudinary URL
  String? _comparisonResult;
  bool _isAnalyzing = false;
  bool _isProcessing = false;
  bool? _hasDamage;
  bool? _acceptReturn;

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
      request.fields['folder'] = 'return_images';

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _takeReturnPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _returnImage = pickedFile;
        _isAnalyzing = true;
        _comparisonResult = null;
      });

      // Upload to Cloudinary first
      final returnUrl = await _uploadToCloudinary(pickedFile);

      if (returnUrl == null) {
        throw Exception('Failed to upload return image');
      }

      setState(() {
        _returnImageUrl = returnUrl;
      });

      // Download original image
      final response = await http.get(Uri.parse(widget.originalImageUrl));
      final originalImageBytes = response.bodyBytes;

      // Get return image bytes
      final returnImageBytes = await pickedFile.readAsBytes();

      // Compare with AI using bytes (works on web and mobile)
      final comparisonResult = await _geminiService.compareEquipmentCondition(
        originalImageBytes: originalImageBytes,
        returnImageBytes: returnImageBytes,
        equipmentTitle: widget.equipmentTitle,
      );

      setState(() {
        _isAnalyzing = false;
        if (comparisonResult['success']) {
          _comparisonResult = comparisonResult['comparison'];
          _hasDamage = comparisonResult['hasDamage'];
          _acceptReturn = comparisonResult['acceptReturn'];
        } else {
          _comparisonResult = 'AI comparison failed. Manual review needed.';
          _hasDamage = false;
          _acceptReturn = true;
        }
      });

      if (mounted && comparisonResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasDamage! ? '⚠️ Damage detected!' : '✅ No damage found!',
            ),
            backgroundColor: _hasDamage! ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _processReturn() async {
    if (_returnImage == null || _returnImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a return photo first')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update equipment document with Cloudinary URL
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(widget.equipmentId)
          .update({
        'available': true,
        'returnImageUrl': _returnImageUrl,
        'returnAnalysis': _comparisonResult,
        'returnDate': FieldValue.serverTimestamp(),
        'damageDuringRental': _hasDamage,
      });

      // Update borrower score
      if (_hasDamage == true) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.borrowerUserId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(userDoc);

          if (snapshot.exists) {
            double currentScore =
                (snapshot.data()?['borrowerScore'] ?? 5.0).toDouble();
            double newScore = (currentScore - 0.5).clamp(0.0, 5.0);

            transaction.update(userDoc, {
              'borrowerScore': newScore,
            });
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasDamage!
                  ? 'Return processed. Borrower score reduced.'
                  : 'Return accepted. Equipment available again!',
            ),
            backgroundColor: _hasDamage! ? Colors.orange : Colors.green,
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
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Equipment'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Returning: ${widget.equipmentTitle}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Original Photo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Original Photo:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.originalImageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Return Photo Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return Photo:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isAnalyzing ? null : _takeReturnPhoto,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: _returnImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text('Take Return Photo'),
                              const SizedBox(height: 4),
                              Text(
                                'AI will compare with original',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _returnImageUrl != null
                                    ? Image.network(
                                        _returnImageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : kIsWeb
                                        ? FutureBuilder<Uint8List>(
                                            future: _returnImage!.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                );
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(_returnImage!.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                              ),
                              if (_isAnalyzing)
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
                                          '🤖 AI Comparing...',
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
              ],
            ),

            // AI Comparison Result
            if (_comparisonResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasDamage! ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _hasDamage! ? Colors.orange[200]! : Colors.green[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasDamage! ? Icons.warning : Icons.check_circle,
                          color: _hasDamage!
                              ? Colors.orange[700]
                              : Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Comparison',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasDamage!
                                ? Colors.orange[700]
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _comparisonResult!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _processReturn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor:
                            _hasDamage! ? Colors.orange : Colors.green,
                      ),
                      child: Text(
                        _hasDamage!
                            ? 'Accept Return (Reduce Score)'
                            : 'Accept Return',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
