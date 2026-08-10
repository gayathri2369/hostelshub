import 'package:flutter/foundation.dart';
import 'gemini_vision_service.dart';

/// Result of product image analysis
class ProductAnalysisResult {
  final String brand;
  final String condition;
  final String productName;
  final String description;
  final List<String> features;
  final bool isBroken;
  final double confidence;
  final bool apiSuccess;

  ProductAnalysisResult({
    required this.brand,
    required this.condition,
    required this.productName,
    required this.description,
    required this.features,
    required this.isBroken,
    required this.confidence,
    this.apiSuccess = true,
  });

  factory ProductAnalysisResult.error(String errorMsg) {
    return ProductAnalysisResult(
      brand: 'Error',
      condition: 'ERROR',
      productName: 'API Failed',
      description: errorMsg,
      features: [],
      isBroken: false,
      confidence: 0.0,
      apiSuccess: false,
    );
  }
}

/// AI Service - Uses Google Gemini Vision for product condition detection
class MistralAIService {
  /// Analyze product image using Gemini Vision AI
  static Future<ProductAnalysisResult> analyzeProductImage(String imagePath) async {
    debugPrint('\n🔍 GEMINI VISION AI ANALYSIS...');

    if (!GeminiVisionService.isConfigured) {
      throw Exception(
        'Gemini API key not configured. Set GEMINI_API_KEY environment variable.',
      );
    }

    debugPrint('✅ Gemini Vision is configured');
    debugPrint('📸 Image: $imagePath');

    final result = await GeminiVisionService.detectCondition(imagePath);

    return ProductAnalysisResult(
      brand: 'Detected Brand',
      condition: result.conditionLabel,
      productName: 'Product',
      description: result.reason,
      features: [result.conditionLabel],
      isBroken: result.isBroken,
      confidence: result.confidence,
      apiSuccess: true,
    );
  }

  /// Check if AI service is configured
  static bool get isConfigured => GeminiVisionService.isConfigured;
}
