import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/legal_models.dart';
import '../models/analysis_result.dart';
import 'legal_data_service.dart';
import 'web_scraping_service.dart';
import 'storage_service.dart';
import 'ocr_service.dart';

class AILegalService {
  static const String _openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // SECURITY: No hardcoded API keys
  static const String _fallbackModel = 'deepseek/deepseek-chat-v3-0324:free';

  final Dio _dio = Dio();
  final WebScrapingService _webScrapingService = WebScrapingService();
  final _uuid = const Uuid();

  // Smart getter methods for redundancy (secure version)
  String _getApiKey() {
    try {
      // Try .env first (development)
      final envKey = dotenv.env['OPENROUTER_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // .env not available (APK build)
    }

    // Try persisted settings (user-entered key)
    try {
      final stored = StorageService.getApiKey();
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }
    } catch (_) {}

    // For APK builds, use dart-define (passed during build)
    return const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  }

  String _getModel() {
    try {
      final envModel = dotenv.env['OPENROUTER_MODEL'];
      if (envModel != null && envModel.isNotEmpty) {
        return envModel;
      }
    } catch (e) {
      // .env not available (APK build)
    }
    return _fallbackModel;
  }

  AILegalService() {
    _dio.options = BaseOptions(
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 30),
    );
  }

  /// Clean up AI response to remove placeholder tokens and fix formatting issues
  String _cleanUpResponse(String response) {
    String cleaned = response;

    // Remove common placeholder patterns
    cleaned = cleaned.replaceAll(
      RegExp(r'\\\$\{?\d+\}?'),
      '',
    ); // Remove ${1}, $1, etc.
    cleaned = cleaned.replaceAll(
      RegExp(r'\\\$\{[^}]*\}'),
      '',
    ); // Remove ${anything}
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*\d+\.\s*$', multiLine: true),
      '',
    ); // Remove standalone numbers
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*\d+\s*$', multiLine: true),
      '',
    ); // Remove standalone numbers

    // Fix broken links - ensure they're properly formatted
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (
      match,
    ) {
      final linkText = match.group(1) ?? '';
      final url = match.group(2) ?? '';
      if (!url.startsWith('http')) {
        return linkText; // Remove broken links, keep text
      }
      return '[$linkText]($url)';
    });

    // Remove extra whitespace and empty lines
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

    return cleaned.trim();
  }

  /// Analyze legal question with real-time web data and AI enhancement
  Future<LegalAnalysisResult> analyzeLegalQuestion({
    required String question,
    required String jurisdiction,
    String? category,
    List<File>? imageFiles,
  }) async {
    print('Starting legal analysis for: $question');

    // Step 0: Process images with OCR if provided
    String imageContext = '';
    if (imageFiles != null && imageFiles.isNotEmpty) {
      print('Processing ${imageFiles.length} images with OCR...');
      try {
        final imagePaths =
            imageFiles
                .where((file) => file.path.isNotEmpty)
                .map((file) => file.path)
                .toList();

        if (imagePaths.isNotEmpty) {
          final ocrResults = await OCRService.extractTextFromImages(imagePaths);

          if (ocrResults.isNotEmpty) {
            imageContext = '\n\n--- ATTACHED DOCUMENTS/IMAGES ---\n';
            ocrResults.forEach((fileName, extractedText) {
              imageContext += '\n**$fileName:**\n$extractedText\n';
            });
            imageContext += '--- END OF ATTACHED DOCUMENTS ---\n';
          }
        } else {
          print('No valid image paths found');
          imageContext =
              '\n\n[Note: Images were selected but could not be accessed]\n';
        }
      } catch (e) {
        print('DEBUG: OCR processing failed: $e');
        imageContext =
            '\n\n[Note: ${imageFiles.length} image(s) were attached but could not be processed due to access issues]\n';
      }
    }

    // Step 1: Get local legal data (non-fatal)
    List<LegalScenario> localScenarios = [];
    try {
      localScenarios = LegalDataService.searchScenarios(question, jurisdiction);
    } catch (e) {
      print('DEBUG: Error getting local scenarios: $e');
    }

    // Step 2: Get optional web info (non-fatal)
    Map<String, dynamic> webData = {
      'success': false,
      'sources': [],
      'content': '',
      'jurisdiction': jurisdiction,
    };
    try {
      webData = await _webScrapingService.searchLegalInfo(
        query: question,
        jurisdiction: jurisdiction,
        category: category ?? _categorizeQuery(question),
      );
    } catch (e) {
      print('DEBUG: Web info fetch failed: $e');
    }

    // Step 3: Build combined context safely
    String combinedContext = '';
    try {
      combinedContext = _buildCombinedContext(localScenarios, webData);
    } catch (e) {
      print('DEBUG: Error building context: $e');
    }

    // Step 4: AI call (preferred path)
    String aiEnhancedResponse = '';
    final apiKey = _getApiKey();
    final model = _getModel();
    print('DEBUG: API Key available: ${apiKey.isNotEmpty ? 'Yes' : 'No'}');
    print('DEBUG: Model: $model');
    if (apiKey.isEmpty) {
      print('DEBUG: No valid API key available');
      throw Exception(
        'Missing OPENROUTER_API_KEY. Add it to .env or pass with --dart-define.',
      );
    }

    aiEnhancedResponse = await _getAIEnhancedResponse(
      question: question + imageContext,
      context: combinedContext,
      jurisdiction: jurisdiction,
      apiKey: apiKey,
      model: model,
    );

    print(
      'DEBUG: AI Response received: ${aiEnhancedResponse.isNotEmpty ? 'Yes' : 'No'}',
    );
    print('DEBUG: AI Response length: ${aiEnhancedResponse.length}');
    if (aiEnhancedResponse.trim().isEmpty) {
      throw Exception('AI service returned no content.');
    }

    // Step 5: Build final result (AI-only)
    return _buildAnalysisResult(
      question: question,
      jurisdiction: jurisdiction,
      localScenarios: localScenarios,
      webData: webData,
      aiResponse: aiEnhancedResponse,
    );
  }

  /// Get AI-enhanced response from OpenRouter
  Future<String> _getAIEnhancedResponse({
    required String question,
    required String context,
    required String jurisdiction,
    required String apiKey,
    required String model,
  }) async {
    try {
      print('DEBUG: Making API call to OpenRouter...');

      final response = await _dio.post(
        _openRouterBaseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://ai-pocket-lawyer.com',
            'X-Title': 'AI Pocket Lawyer',
          },
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a professional legal advisor. Provide clear, specific legal guidance using the EXACT format below. Be concrete and avoid generic responses.

## Legal Analysis
• Specific legal rules, statutes, or regulations that apply to this situation
• Key thresholds, requirements, or criteria that determine legal outcomes  
• Important deadlines, time limits, or procedural requirements

## Your Rights
• Specific rights the person has in this situation
• What they are legally entitled to demand or receive
• Legal protections available to them

## Recommended Actions
1. Immediate steps to take (within 24-48 hours)
2. Documentation to gather or preserve
3. People or agencies to contact
4. Forms to file or applications to submit
5. Legal consultations to seek if needed

## Helpful Links
• [Legal Aid Directory](https://www.lsc.gov/what-legal-aid/find-legal-aid)
• [State Bar Association](https://www.americanbar.org/groups/legal_aid_indigent_defense/resource_center_for_access_to_justice/ati-directory/)
• [Court Self-Help Resources](https://www.uscourts.gov/about-federal-courts/court-role-and-structure)

## Disclaimer
This is general legal information, not legal advice. Consult with a qualified attorney for your specific situation.

CRITICAL FORMATTING RULES:
- Use the exact headings shown above with ## 
- Use • for bullets and 1. 2. 3. for numbered lists
- NEVER use placeholder tokens or variables in responses
- Write actual dollar amounts as "fifteen dollars" or "dollar15", never use currency symbols with numbers
- Make all links clickable using [Text](https://full-url.com) format
- Replace generic links above with specific, relevant government or legal aid websites
- Keep responses specific to the actual question asked
- End with: "What other aspects of this situation would you like me to clarify?"''',
            },
            {
              'role': 'user',
              'content':
                  'Question: $question\nJurisdiction: $jurisdiction\n\nContext: $context\n\nIf the question includes attached document descriptions or image file information, analyze the legal implications based on the provided context. For attached images, I will provide analysis context about the document type and content to help with your legal assessment.\n\nPlease follow the exact section headings above. Keep it natural, specific, include links, and avoid any placeholder symbols. End with a short line inviting follow-up questions so we can continue the conversation.',
            },
          ],
          'max_tokens': 1200,
          'temperature': 0.5,
          'top_p': 0.7,
        },
      );

      print('DEBUG: API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic content =
            response.data['choices']?[0]?['message']?['content'];
        if (content is! String || content.trim().isEmpty) {
          throw Exception(
            'AI responded with empty content or unexpected shape.',
          );
        }

        // Clean up any remaining placeholder tokens
        final cleanedContent = _cleanUpResponse(content);
        return cleanedContent;
      } else {
        throw Exception('OpenRouter API error: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: AI API call failed: $e');
      rethrow;
    }
  }

  // Helper methods for building context and analysis results
  String _buildCombinedContext(
    List<LegalScenario> scenarios,
    Map<String, dynamic> webData,
  ) {
    final buffer = StringBuffer();

    if (scenarios.isNotEmpty) {
      buffer.writeln('LEGAL SCENARIOS:');
      for (final scenario in scenarios.take(3)) {
        buffer.writeln('- ${scenario.problem}');
        buffer.writeln('  Law: ${scenario.applicableLaw}');
        buffer.writeln('  Rights: ${scenario.rightsSummary}');
      }
      buffer.writeln();
    }

    if (webData['success'] == true && webData['content'] != null) {
      buffer.writeln('WEB RESEARCH:');
      final content = webData['content'].toString();
      buffer.writeln(
        content.length > 500 ? content.substring(0, 500) : content,
      );
      buffer.writeln();
    }

    return buffer.toString();
  }

  LegalAnalysisResult _buildAnalysisResult({
    required String question,
    required String jurisdiction,
    required List<LegalScenario> localScenarios,
    required Map<String, dynamic> webData,
    required String aiResponse,
  }) {
    return LegalAnalysisResult(
      id: _uuid.v4(),
      userQuery: question,
      jurisdiction: jurisdiction,
      timestamp: DateTime.now(),
      rightsSummary: aiResponse,
      stepByStepActions: _extractActions(aiResponse),
      relevantContacts: [],
      matchingScenarios: localScenarios.take(3).toList(),
    );
  }

  String _categorizeQuery(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('employment') ||
        lower.contains('work') ||
        lower.contains('job')) {
      return 'employment';
    } else if (lower.contains('housing') ||
        lower.contains('rent') ||
        lower.contains('landlord')) {
      return 'housing';
    } else if (lower.contains('family') ||
        lower.contains('divorce') ||
        lower.contains('child')) {
      return 'family';
    } else if (lower.contains('contract') || lower.contains('agreement')) {
      return 'contract';
    } else if (lower.contains('criminal') ||
        lower.contains('arrest') ||
        lower.contains('police')) {
      return 'criminal';
    }
    return 'general';
  }

  List<String> _extractActions(String response) {
    final actions = <String>[];
    final sentences = response.split(RegExp(r'[.!?]'));
    for (String sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isNotEmpty &&
          (trimmed.toLowerCase().contains('should') ||
              trimmed.toLowerCase().contains('can') ||
              trimmed.toLowerCase().contains('contact') ||
              trimmed.toLowerCase().contains('document') ||
              trimmed.toLowerCase().contains('file') ||
              trimmed.toLowerCase().contains('write') ||
              trimmed.toLowerCase().contains('keep') ||
              trimmed.toLowerCase().contains('save'))) {
        actions.add(trimmed);
      }
    }
    return actions.take(5).toList();
  }
}
