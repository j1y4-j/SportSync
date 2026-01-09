import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'KEY_NOT_FOUND',
  );
  late final GenerativeModel _model;
  DateTime? _lastRequestTime;
  static const _cooldownSeconds = 15; // Wait 15 seconds between requests

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // This is what you have quota for!
      apiKey: apiKey,
    );
  }

  Future<Map<String, dynamic>> analyzeEquipment({
    required Uint8List imageBytes,
    required String category,
  }) async {
    // Enforce cooldown to avoid hitting RPM limit
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inSeconds < _cooldownSeconds) {
        final waitTime = _cooldownSeconds - timeSinceLastRequest.inSeconds;
        print('⏳ Waiting ${waitTime}s to avoid rate limit...');
        await Future.delayed(Duration(seconds: waitTime + 1));
      }
    }

    try {
      _lastRequestTime = DateTime.now();

      final prompt =
          '''You are an expert equipment inspector. Analyze this $category equipment photo critically.

IMPORTANT: Be HONEST and STRICT about defects. User safety depends on accurate assessments.

Look carefully for:
- Cracks, breaks, or structural damage
- Fraying, tears, or worn materials  
- Rust, corrosion, or discoloration
- Loose or missing parts
- Signs of heavy use or neglect

Rate the condition honestly:
- Excellent: Perfect condition, like new, no defects
- Good: Light use, minor cosmetic marks only, fully safe to use
- Fair: Noticeable wear, some damage, usable but not ideal
- Poor: Significant damage, safety concerns, should not be rented

Provide:
1. Brand/Model: (if visible, otherwise "Generic")
2. Condition: Excellent/Good/Fair/Poor (be strict!)
3. Specific issues: List ALL defects you see, even minor ones
4. Safety assessment: Is this safe to rent out?

If the equipment looks damaged or worn, say so clearly.''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final analysisText = response.text ?? 'Analysis failed';

      String condition = 'Good';
      final lowerText = analysisText.toLowerCase();
      if (lowerText.contains('excellent')) {
        condition = 'Excellent';
      } else if (lowerText.contains('poor')) {
        condition = 'Poor';
      } else if (lowerText.contains('fair')) {
        condition = 'Fair';
      }

      return {
        'success': true,
        'analysis': analysisText,
        'condition': condition,
      };
    } catch (e) {
      print('Gemini AI Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'analysis': 'AI analysis unavailable',
        'condition': 'Good',
      };
    }
  }

  Future<Map<String, dynamic>> compareEquipmentCondition({
    required Uint8List originalImageBytes,
    required Uint8List returnImageBytes,
    required String equipmentTitle,
  }) async {
    // Same cooldown check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inSeconds < _cooldownSeconds) {
        final waitTime = _cooldownSeconds - timeSinceLastRequest.inSeconds;
        await Future.delayed(Duration(seconds: waitTime + 1));
      }
    }

    try {
      _lastRequestTime = DateTime.now();

      final prompt = '''Compare these two photos of $equipmentTitle carefully.

ORIGINAL PHOTO (when first listed):
[First image]

RETURN PHOTO (current condition):
[Second image]

Look for ANY new damage:
- New cracks, breaks, or dents
- Additional wear or fraying
- New stains or discoloration
- Missing parts or loosened components

Be honest and detailed:
1. Damage assessment: List ALL new damage (even minor scratches)
2. Condition change: Better/Same/Worse (be specific)
3. Severity: Minor/Moderate/Severe
4. Recommendation: Accept return? Yes/No with reasoning''';

      final content = [
        Content.multi([
          TextPart('ORIGINAL PHOTO:'),
          DataPart('image/jpeg', originalImageBytes),
          TextPart('RETURN PHOTO:'),
          DataPart('image/jpeg', returnImageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(content);
      final comparisonText = response.text ?? 'Comparison failed';

      final hasDamage = comparisonText.toLowerCase().contains('damage') ||
          comparisonText.toLowerCase().contains('worse') ||
          comparisonText.toLowerCase().contains('broken');

      final acceptReturn =
          !hasDamage || comparisonText.toLowerCase().contains('minor');

      return {
        'success': true,
        'comparison': comparisonText,
        'hasDamage': hasDamage,
        'acceptReturn': acceptReturn,
      };
    } catch (e) {
      print('Gemini AI Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'comparison': 'AI comparison unavailable',
        'hasDamage': false,
        'acceptReturn': true,
      };
    }
  }
}
