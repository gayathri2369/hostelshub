import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Product condition detected by Gemini Vision
enum ProductCondition { newItem, old, broken }

/// Result of Gemini Vision product condition detection
class ProductConditionResult {
  final ProductCondition condition;
  final bool isBroken;
  final double confidence;
  final String reason;

  ProductConditionResult({
    required this.condition,
    required this.isBroken,
    required this.confidence,
    required this.reason,
  });

  factory ProductConditionResult.fromJson(Map<String, dynamic> json) {
    final conditionStr = (json['condition'] as String).toUpperCase();
    ProductCondition condition;
    switch (conditionStr) {
      case 'NEW':
        condition = ProductCondition.newItem;
        break;
      case 'BROKEN':
        condition = ProductCondition.broken;
        break;
      case 'OLD':
      default:
        condition = ProductCondition.old;
        break;
    }

    return ProductConditionResult(
      condition: condition,
      isBroken: json['is_broken'] == true,
      confidence: (json['confidence'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  String get conditionLabel {
    switch (condition) {
      case ProductCondition.newItem:
        return 'NEW';
      case ProductCondition.old:
        return 'OLD';
      case ProductCondition.broken:
        return 'BROKEN';
    }
  }
}

/// Gemini Vision service for product condition detection
class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  static const String _prompt = '''You are an expert product condition inspector analyzing a photo for a student marketplace. Your job is to classify the item's condition accurately.

IMPORTANT GUIDELINES:
- NEW: Item appears unused, pristine, with original packaging/tags, no visible wear or marks
- OLD: Item shows signs of use - scratches, wear, fading, stains, but is still functional and usable
- BROKEN: Item has severe damage - cracks, missing parts, torn, completely non-functional, or major defects

BE ACCURATE:
- If you see ANY signs of wear, marks, or use → classify as OLD (not NEW)
- Only classify as NEW if the item looks completely unused and pristine
- Only classify as BROKEN if there's serious damage that makes it unusable
- When in doubt between NEW and OLD → choose OLD
- When in doubt between OLD and BROKEN → choose OLD

Respond with ONLY valid JSON (no markdown, no extra text):
{"condition": "NEW" | "OLD" | "BROKEN", "is_broken": true | false, "confidence": 0.0-1.0, "reason": "brief explanation"}

Examples:
- Phone with scratches → OLD
- Book with bent corners → OLD  
- Clothes with slight fading → OLD
- Electronics with dents → OLD
- Furniture with scuffs → OLD
- Completely unused item in box → NEW
- Cracked screen/broken parts → BROKEN''';

  /// Detect product condition from image file
  static Future<ProductConditionResult> detectCondition(String imagePath) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not configured. Set GEMINI_API_KEY environment variable.',
      );
    }

    debugPrint('🔍 Gemini Vision: Analyzing product condition...');
    debugPrint('Image: $imagePath');

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Read and encode image
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Determine mime type from file extension
    final extension = imagePath.toLowerCase().split('.').last;
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    // Build request body
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.2,
      }
    });

    try {
      // Make API request
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'x-goog-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      // Handle rate limit / service unavailable with single retry
      if (response.statusCode == 429 || response.statusCode == 503) {
        debugPrint('⚠️  Gemini rate limit/overloaded (${response.statusCode}), retrying...');
        await Future.delayed(const Duration(seconds: 2));

        final retryResponse = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'x-goog-api-key': _apiKey,
            'Content-Type': 'application/json',
          },
          body: requestBody,
        ).timeout(const Duration(seconds: 30));

        if (retryResponse.statusCode != 200) {
          throw Exception(
            'Gemini API error after retry: ${retryResponse.statusCode}\n${retryResponse.body}',
          );
        }

        return _parseResponse(retryResponse.body);
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error: ${response.statusCode}\n${response.body}',
        );
      }

      return _parseResponse(response.body);
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Network error: Cannot reach Gemini API. Check your internet connection.');
      }
      rethrow;
    }
  }

  /// Parse Gemini API response
  static ProductConditionResult _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;

      if (candidates.isEmpty) {
        throw Exception('Gemini returned no candidates');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;

      if (parts.isEmpty) {
        throw Exception('Gemini returned no parts');
      }

      final text = parts[0]['text'] as String;
      final resultJson = jsonDecode(text) as Map<String, dynamic>;

      final result = ProductConditionResult.fromJson(resultJson);

      debugPrint('✅ Gemini result: ${result.conditionLabel}');
      debugPrint('   Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
      debugPrint('   Reason: ${result.reason}');
      debugPrint('   Broken: ${result.isBroken}');

      return result;
    } catch (e) {
      debugPrint('❌ Failed to parse Gemini response: $e');
      debugPrint('Raw response: $responseBody');
      throw Exception('Failed to parse Gemini response: $e');
    }
  }

  /// Check if service is configured
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// List available Gemini models (for debugging)
  static Future<void> listAvailableModels() async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ Cannot list models: API key not configured');
      return;
    }

    try {
      debugPrint('\n🔍 Fetching available Gemini models...');
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
        headers: {'x-goog-api-key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to list models: ${response.statusCode}');
        debugPrint(response.body);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>;

      debugPrint('\n✅ Available Gemini models that support generateContent:');
      for (final model in models) {
        final modelData = model as Map<String, dynamic>;
        final name = modelData['name'] as String;
        final supportedMethods = modelData['supportedGenerationMethods'] as List<dynamic>?;

        if (supportedMethods != null && supportedMethods.contains('generateContent')) {
          // Extract just the model ID from the full name (e.g., "models/gemini-pro" -> "gemini-pro")
          final modelId = name.replaceFirst('models/', '');
          debugPrint('  • $modelId');
        }
      }
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error listing models: $e');
    }
  }
}
