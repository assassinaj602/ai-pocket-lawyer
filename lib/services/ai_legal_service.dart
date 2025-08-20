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
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 2),
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

        print('DEBUG: Image paths found: $imagePaths');

        if (imagePaths.isNotEmpty) {
          final ocrResults = await OCRService.extractTextFromImages(imagePaths);
          print('DEBUG: OCR results count: ${ocrResults.length}');

          if (ocrResults.isNotEmpty) {
            imageContext = '\n\n--- ATTACHED DOCUMENTS/IMAGES ---\n';
            ocrResults.forEach((fileName, extractedText) {
              print('DEBUG: Processing file: $fileName');
              imageContext += '\n**$fileName:**\n$extractedText\n';
            });
            imageContext += '--- END OF ATTACHED DOCUMENTS ---\n';
            print(
              'DEBUG: Image context created: ${imageContext.length} characters',
            );
          } else {
            print('DEBUG: No OCR results returned');
            imageContext =
                '\n\n[Note: Images were attached but OCR processing returned no results]\n';
          }
        } else {
          print('No valid image paths found');
          imageContext =
              '\n\n[Note: Images were selected but could not be accessed]\n';
        }
      } catch (e) {
        print('DEBUG: OCR processing failed: $e');
        print('DEBUG: Stack trace: ${StackTrace.current}');
        imageContext =
            '\n\n[Note: ${imageFiles.length} image(s) were attached but could not be processed due to access issues: ${e.toString()}]\n';
      }
    } else if (question.toLowerCase().contains('picture') ||
        question.toLowerCase().contains('image') ||
        question.toLowerCase().contains('photo') ||
        question.toLowerCase().contains('document') ||
        question.toLowerCase().contains('attached')) {
      // User mentions images but none were processed
      imageContext =
          '\n\n[Note: You mentioned attachments, but no images were successfully processed. Please describe the document content in your question or try again with the desktop version for full image analysis.]\n';
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

    try {
      aiEnhancedResponse = await _getAIEnhancedResponse(
        question: question + imageContext,
        context: combinedContext,
        jurisdiction: jurisdiction,
        apiKey: apiKey,
        model: model,
        imageContext: imageContext,
      );
    } catch (e) {
      print('DEBUG: AI service failed, providing fallback response: $e');
      // Provide a fallback response when AI service fails
      aiEnhancedResponse = _createFallbackResponse(
        question,
        jurisdiction,
        localScenarios,
      );
    }

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

  /// Get AI-enhanced response from OpenRouter with retry logic
  Future<String> _getAIEnhancedResponse({
    required String question,
    required String context,
    required String jurisdiction,
    required String apiKey,
    required String model,
    String imageContext = '',
  }) async {
    int retryCount = 0;
    const maxRetries = 2;
    const retryDelaySeconds = 3;

    while (retryCount <= maxRetries) {
      try {
        if (retryCount > 0) {
          print('DEBUG: Retry attempt $retryCount of $maxRetries...');
          await Future.delayed(
            Duration(seconds: retryDelaySeconds * retryCount),
          );
        } else {
          print('DEBUG: Making API call to OpenRouter...');
        }

        final response = await _dio.post(
          _openRouterBaseUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://ai-pocket-lawyer.com',
              'X-Title': 'AI Pocket Lawyer',
            },
            receiveTimeout: Duration(
              minutes: retryCount == 0 ? 8 : 12,
            ), // Increase timeout on retry
            sendTimeout: const Duration(minutes: 2),
          ),
          data: {
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    '''You are a professional legal advisor with expertise in document analysis and employment law. Provide clear, specific legal guidance using the EXACT format below. Be concrete and avoid generic responses.

IMPORTANT: When users attach legal documents (images), they will be described in detail in the user's question. Analyze these document descriptions carefully and provide specific legal guidance based on the document content described.

CRITICAL: Always directly answer the specific legal question being asked. If someone asks "Is X illegal?" provide a clear yes/no answer with explanation. If they ask about specific laws or violations, address those directly.

## Legal Analysis
• Specific legal rules, statutes, or regulations that apply to this situation
• Key thresholds, requirements, or criteria that determine legal outcomes  
• Important deadlines, time limits, or procedural requirements
• Analysis of any attached document content if provided
• Direct answer to the specific question asked

## Your Rights
• Specific rights the person has in this situation
• What they are legally entitled to demand or receive
• Legal protections available to them
• Rights related to any documents mentioned

## Recommended Actions
1. Immediate steps to take (within 24-48 hours)
2. Documentation to gather or preserve
3. People or agencies to contact
4. Forms to file or applications to submit
5. Legal consultations to seek if needed

## Helpful Links
• [Legal Aid Directory](https://www.lsc.gov/what-legal-aid/find-legal-aid)
• [State Bar Association](https://www.americanbar.org/groups/legal_aid_indigent_defense/resource_center_for_access_to_justice/ati-directory/)
• [Department of Labor - Wage and Hour Division](https://www.dol.gov/agencies/whd) (for employment issues)
• [Court Self-Help Resources](https://www.uscourts.gov/about-federal-courts/court-role-and-structure)

## Disclaimer
This is general legal information, not legal advice. Consult with a qualified attorney for your specific situation.

CRITICAL FORMATTING RULES:
- Use the exact headings shown above with ## 
- Use • for bullets and 1. 2. 3. for numbered lists
- NEVER use placeholder tokens or variables in responses
- Write actual dollar amounts as "fifteen dollars" or "fifteen dollar", never use currency symbols with numbers
- Make all links clickable using [Text](https://full-url.com) format
- Replace generic links above with specific, relevant government or legal aid websites
- Keep responses specific to the actual question asked
- If document details are provided, analyze them thoroughly
- Always provide a direct answer to questions like "Is X illegal?" or "What law applies?"
- End with: "What other aspects of this situation would you like me to clarify?"''',
              },
              {
                'role': 'user',
                'content':
                    'Question: $question\nJurisdiction: $jurisdiction\n\nContext: $context\n\n${imageContext.isNotEmpty ? "IMPORTANT: The user has attached legal document images that need analysis. The attached document details are provided in the question above. Please analyze the legal content from these attached documents carefully and provide specific guidance based on what you can determine from the document information provided." : "No documents were attached to this question."}\n\nPlease follow the exact section headings above. Keep it natural, specific, include relevant legal links, and avoid any placeholder symbols. End with a short line inviting follow-up questions so we can continue the conversation.',
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

        // Check if this is a timeout error and we can retry
        bool shouldRetry = false;
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
              shouldRetry = retryCount < maxRetries;
              break;
            case DioExceptionType.badResponse:
            case DioExceptionType.cancel:
            case DioExceptionType.connectionError:
            default:
              shouldRetry = false;
              break;
          }
        }

        if (shouldRetry) {
          retryCount++;
          print(
            'DEBUG: Will retry due to timeout (attempt $retryCount of $maxRetries)',
          );
          continue; // Continue the retry loop
        }

        // If not retryable or out of retries, provide user-friendly error messages
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.receiveTimeout:
              throw Exception(
                'The AI service is taking longer than expected. This might be due to a complex query or high server load. Please try again with a simpler question or try again later.',
              );
            case DioExceptionType.connectionTimeout:
              throw Exception(
                'Unable to connect to the AI service. Please check your internet connection and try again.',
              );
            case DioExceptionType.sendTimeout:
              throw Exception(
                'Failed to send your request to the AI service. Please check your internet connection and try again.',
              );
            case DioExceptionType.badResponse:
              throw Exception(
                'The AI service returned an error. This might be due to server issues. Please try again later.',
              );
            case DioExceptionType.cancel:
              throw Exception('Request was cancelled.');
            case DioExceptionType.connectionError:
              throw Exception(
                'Connection error. Please check your internet connection and try again.',
              );
            default:
              throw Exception('AI service error: ${e.message}');
          }
        }

        rethrow;
      }
    }

    // This should never be reached, but just in case
    throw Exception('Failed to get AI response after $maxRetries retries');
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
        lower.contains('job') ||
        lower.contains('overtime') ||
        lower.contains('wage') ||
        lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('hours') ||
        lower.contains('schedule') ||
        lower.contains('boss') ||
        lower.contains('supervisor') ||
        lower.contains('employer')) {
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

  /// Create a fallback response when AI service is unavailable
  String _createFallbackResponse(
    String question,
    String jurisdiction,
    List<LegalScenario> localScenarios,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('## Legal Analysis');
    buffer.writeln(
      '• AI service is currently unavailable, but here\'s what we found from our legal database:',
    );

    if (localScenarios.isNotEmpty) {
      final relevantScenario = localScenarios.first;
      buffer.writeln('• ${relevantScenario.applicableLaw}');
      buffer.writeln(
        '• This situation appears to be covered by the applicable legal framework',
      );
    } else {
      buffer.writeln('• Your question relates to $jurisdiction legal matters');
      if (question.toLowerCase().contains('overtime')) {
        buffer.writeln(
          '• Overtime laws typically require 1.5x pay for hours over 40 per week',
        );
        buffer.writeln(
          '• The Fair Labor Standards Act (FLSA) governs most overtime requirements',
        );
      } else if (question.toLowerCase().contains('employment') ||
          question.toLowerCase().contains('wage')) {
        buffer.writeln(
          '• Employment law protects workers\' rights regarding wages and working conditions',
        );
        buffer.writeln(
          '• Contact your state\'s Department of Labor for specific guidance',
        );
      }
    }

    buffer.writeln('\n## Your Rights');
    if (localScenarios.isNotEmpty) {
      buffer.writeln('• ${localScenarios.first.rightsSummary}');
    } else {
      buffer.writeln(
        '• You have the right to fair treatment under applicable employment laws',
      );
      buffer.writeln(
        '• You can file complaints with relevant government agencies',
      );
    }

    buffer.writeln('\n## Recommended Actions');
    buffer.writeln('1. Document all relevant details of your situation');
    buffer.writeln('2. Keep records of any communications or evidence');
    buffer.writeln('3. Contact a local legal aid organization');
    buffer.writeln('4. Consider consulting with an employment attorney');
    buffer.writeln(
      '5. File a complaint with the appropriate government agency if applicable',
    );

    buffer.writeln('\n## Helpful Links');
    buffer.writeln(
      '• [Legal Aid Directory](https://www.lsc.gov/what-legal-aid/find-legal-aid)',
    );
    buffer.writeln('• [Department of Labor](https://www.dol.gov/agencies/whd)');
    buffer.writeln(
      '• [State Bar Association](https://www.americanbar.org/groups/legal_aid_indigent_defense/resource_center_for_access_to_justice/ati-directory/)',
    );

    buffer.writeln('\n## Disclaimer');
    buffer.writeln(
      'This is general legal information, not legal advice. Consult with a qualified attorney for your specific situation.',
    );
    buffer.writeln(
      '\nThe AI service is temporarily unavailable. For more detailed analysis, please try again later.',
    );
    buffer.writeln(
      '\nWhat other aspects of this situation would you like me to clarify?',
    );

    return buffer.toString();
  }
}
