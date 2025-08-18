import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/legal_models.dart';
import '../models/analysis_result.dart';
import 'legal_data_service.dart';
import 'web_scraping_service.dart';

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
      receiveTimeout: const Duration(
        minutes: 5,
      ), // Increased to 5 minutes for AI responses
      sendTimeout: const Duration(seconds: 30),
    );
  }

  /// Analyze legal question with real-time web data and AI enhancement
  Future<LegalAnalysisResult> analyzeLegalQuestion({
    required String question,
    required String jurisdiction,
    String? category,
  }) async {
    print('Starting legal analysis for: $question');

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
    final keyPreview = apiKey.length >= 6 ? apiKey.substring(0, 6) : apiKey;
    print('DEBUG: API Key starts with: $keyPreview...');
    final maskedKey =
        apiKey.length > 6 ? '${apiKey.substring(0, 6)}***' : apiKey;
    print('DEBUG: Attempting to call OpenRouter API with key: $maskedKey');
    aiEnhancedResponse = await _getAIEnhancedResponse(
      question: question,
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
      print('DEBUG: API URL: $_openRouterBaseUrl');
      print('DEBUG: API Key: ${apiKey.substring(0, 10)}...');

      final response = await _dio.post(
        _openRouterBaseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://ai-pocket-lawyer.com',
            'X-Title': 'AI Pocket Lawyer',
          },
          // Treat non-200 responses as non-throwing so we can handle fallback logic
          validateStatus: (status) => true,
          receiveTimeout: const Duration(
            minutes: 5,
          ), // 5 minutes for AI response
          sendTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': model, // Use model from environment configuration
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a senior legal advisor. Write like a human expert: clear, organized, and calm. Use clean Markdown with these exact sections and headings. Keep it concise (2–3 short lines per bullet) and avoid bold (**). Use '-' for bullets. For links, ALWAYS use standard Markdown link syntax [Title](https://example.com) with full https:// URLs:

## Legal Analysis
• 3–6 short bullets explaining the rule(s) that apply, thresholds, and any key deadlines.

## Your Rights
• 3–6 bullets describing what the person is entitled to or can demand.

## Recommended Actions
1. 5–10 practical steps in plain language using a numbered list (1., 2., 3.).

## Helpful Links
• 3–6 reputable links (official agencies, legal aid, trusted orgs) using Markdown links like: [Department of Labor overtime guidance](https://www.dol.gov/agencies/whd/overtime).

## Disclaimer
• One sentence clarifying this is general information only, not legal advice.

Style rules:
- Use Markdown headings (##) exactly as above and '-' for bullets, or 1. for steps.
- Never emit placeholder tokens like \$1, \$2, \${1}. Currency like \$15 must be preserved.
- Do not output stray numbers on lines by themselves (e.g., "1" or "1:").
- All links must be valid absolute URLs that start with https:// and be in [Text](URL) Markdown form.
- Keep sentences short and readable; avoid legalese.
- No bold (**), banners, code fences, or decorative separators.''',
            },
            {
              'role': 'user',
              'content':
                  'Question: $question\nJurisdiction: $jurisdiction\n\nPlease follow the exact section headings above. Keep it natural, specific, include links, and avoid any placeholder symbols.',
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
        final preview =
            content.length > 100 ? content.substring(0, 100) : content;
        print('DEBUG: Extracted AI Response preview: $preview...');
        print('DEBUG: AI Response length: ${content.length}');
        return content;
      } else {
        // Graceful fallback on non-200: try simplified request
        print('OpenRouter API non-200: ${response.statusCode}');
        print('Response data: ${response.data}');
        print('DEBUG: Falling back to simplified AI request...');
        return await _getSimplifiedAIResponse(
          question,
          jurisdiction,
          apiKey,
          model,
        );
      }
    } catch (e) {
      print('Error calling OpenRouter API: $e');
      print('Error type: ${e.runtimeType}');

      // If it's a timeout error, try with a simplified request
      if (e.toString().contains('timeout') ||
          e.toString().contains('receive timeout')) {
        print('DEBUG: Timeout detected, trying simplified request...');
        return await _getSimplifiedAIResponse(
          question,
          jurisdiction,
          apiKey,
          model,
        );
      }

      if (e is DioException) {
        print('DioException details: ${e.response?.data}');
        print('DioException status: ${e.response?.statusCode}');
        // Also fallback for known transient non-timeout Dio errors
        if ((e.response?.statusCode ?? 0) >= 400) {
          print(
            'DEBUG: DioException with status ${e.response?.statusCode}, trying simplified request...',
          );
          return await _getSimplifiedAIResponse(
            question,
            jurisdiction,
            apiKey,
            model,
          );
        }
      }
      rethrow;
    }
  }

  /// Simplified AI response for timeout fallback
  Future<String> _getSimplifiedAIResponse(
    String question,
    String jurisdiction,
    String apiKey,
    String model,
  ) async {
    try {
      print('DEBUG: Making simplified API call...');

      final response = await _dio.post(
        _openRouterBaseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://ai-pocket-lawyer.com',
            'X-Title': 'AI Pocket Lawyer',
          },
          receiveTimeout: const Duration(minutes: 2), // Shorter timeout
          sendTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a senior legal advisor. Write like a human expert: clear, organized, and calm. Use clean Markdown with these exact sections and headings. Keep it concise (2–3 short lines per bullet) and avoid bold (**). Use '-' for bullets. For links, ALWAYS use standard Markdown link syntax [Title](https://example.com) with full https:// URLs:

## Legal Analysis
- 3–6 short bullets explaining the rule(s) that apply, thresholds, and any key deadlines.

## Your Rights
- 3–6 bullets describing what the person is entitled to or can demand.

## Recommended Actions
1. 5–10 practical steps in plain language using a numbered list (1., 2., 3.).

## Helpful Links
- 3–6 reputable links (official agencies, legal aid, trusted orgs) using Markdown links like: [Department of Labor overtime guidance](https://www.dol.gov/agencies/whd/overtime).

## Disclaimer
- One sentence clarifying this is general information only, not legal advice.

Style rules:
- Use Markdown headings (##) exactly as above and '-' for bullets, or 1. for steps.
- Never emit placeholder tokens like \$1, \$2, \${1}. Currency like \$15 must be preserved.
- Do not output stray numbers on lines by themselves (e.g., "1" or "1:").
- All links must be valid absolute URLs that start with https:// and be in [Text](URL) Markdown form.
- Keep sentences short and readable; avoid legalese.
- No bold (**), banners, code fences, or decorative separators.''',
            },
            {
              'role': 'user',
              'content': '''Legal Question: $question
Jurisdiction: $jurisdiction

Please provide comprehensive legal guidance following the structured format.''',
            },
          ],
          'max_tokens': 2000, // Limit response size
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final dynamic content =
            response.data['choices']?[0]?['message']?['content'];
        final ok = (content is String) && content.trim().isNotEmpty;
        print('DEBUG: Simplified AI Response received: $ok');
        if (!ok) {
          throw Exception('AI simplified request returned empty content.');
        }
        return content;
      } else {
        print('Simplified API error: ${response.statusCode}');
        throw Exception(
          'OpenRouter API error (simplified): ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in simplified API call: $e');
      rethrow;
    }
  }

  /// Categorize the legal query with enhanced accuracy
  String _categorizeQuery(String question) {
    final lowerQuestion = question.toLowerCase();

    // Housing/Real Estate Law
    if (lowerQuestion.contains(
      RegExp(
        r'\b(landlord|tenant|rent|rental|evict|eviction|lease|deposit|housing|property|real estate|mortgage|foreclosure|homeowner|apartment|condo)\b',
      ),
    )) {
      return 'housing';
    }
    // Employment/Labor Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(employer|employee|work|job|fired|terminated|harassment|discrimination|wage|salary|overtime|benefits|unemployment|workers compensation|union)\b',
      ),
    )) {
      return 'employment';
    }
    // Consumer Protection Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(consumer|purchase|warranty|refund|scam|fraud|debt|credit|bankruptcy|contract|service|product|merchant|seller)\b',
      ),
    )) {
      return 'consumer';
    }
    // Family Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(family|divorce|custody|child support|alimony|marriage|domestic violence|adoption|parental rights|paternity)\b',
      ),
    )) {
      return 'family';
    }
    // Criminal Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(criminal|crime|arrest|police|court|trial|sentence|bail|probation|felony|misdemeanor|charges|lawyer|attorney)\b',
      ),
    )) {
      return 'criminal';
    }
    // Immigration Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(immigration|visa|green card|citizen|deportation|asylum|refugee|border|passport|work permit)\b',
      ),
    )) {
      return 'immigration';
    }
    // Personal Injury/Tort Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(injury|accident|medical malpractice|negligence|insurance claim|car accident|slip and fall|compensation|damages)\b',
      ),
    )) {
      return 'personal_injury';
    }
    // Business/Corporate Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(business|company|corporation|partnership|llc|contract|intellectual property|trademark|copyright|patent|lawsuit)\b',
      ),
    )) {
      return 'business';
    }
    // Estate/Probate Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(will|estate|inheritance|probate|trust|executor|beneficiary|power of attorney|guardianship)\b',
      ),
    )) {
      return 'estate';
    }
    // Tax Law
    else if (lowerQuestion.contains(
      RegExp(
        r'\b(tax|irs|audit|deduction|filing|income tax|property tax|tax return|tax debt)\b',
      ),
    )) {
      return 'tax';
    }

    return 'general';
  }

  /// Build combined context from local and web data
  String _buildCombinedContext(
    List<LegalScenario> localScenarios,
    Map<String, dynamic> webData,
  ) {
    StringBuffer context = StringBuffer();

    // Add local scenario data
    if (localScenarios.isNotEmpty) {
      context.writeln('=== RELEVANT LEGAL SCENARIOS ===');
      for (var scenario in localScenarios) {
        context.writeln('Problem: ${scenario.problem}');
        context.writeln('Applicable Law: ${scenario.applicableLaw}');
        context.writeln('Rights Summary: ${scenario.rightsSummary}');
        context.writeln('Suggested Actions: ${scenario.actions.join(', ')}');
        context.writeln('---');
      }
    }

    // Add web-scraped data
    if (webData['success'] == true) {
      context.writeln('\n=== CURRENT LEGAL INFORMATION ===');
      context.writeln('Jurisdiction: ${webData['jurisdiction']}');
      context.writeln('\nContent from Official Sources:');
      context.writeln(webData['content']);

      if (webData['sources'] != null) {
        context.writeln('\nSources:');
        for (var source in webData['sources']) {
          context.writeln('- ${source['title']}: ${source['url']}');
        }
      }
    }

    return context.toString();
  }

  /// Clean and format AI response for better readability with markdown support
  String _cleanAndFormatResponse(String response) {
    if (response.isEmpty) return '';

    // Remove excessive line breaks and clean up
    String cleaned = response.trim();

    // ULTRA AGGRESSIVE ARTIFACT REMOVAL BUT PRESERVE GOOD FORMATTING

    // 1. Remove standalone number artifacts like "1" on its own line
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+:\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\d+\s*\n'), '\n\n');

    // 2. Remove specific "1" patterns that break formatting
    cleaned = cleaned.replaceAll(RegExp(r'^\s*1\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*1\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*•\s*1\s*•\s*1.*$', multiLine: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'1\s*•\s*1\s*•\s*1'), '');
    cleaned = cleaned.replaceAll(RegExp(r'•\s*1\s*•\s*1'), '');

    // 3. Remove ONLY placeholder tokens like $1 or ${2}, but keep real currency like $10, $15, or $15.50
    // Remove braced placeholders like ${1} or ${12}
    cleaned = cleaned.replaceAll(RegExp(r'\$\{\s*\d+\s*\}'), '');
    // Remove bare $1..$9 tokens even when followed by letters (artifacts), while preserving real currency like $15 or $15.50
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\d)\$(?:[1-9])(?![\d\.])'), '');
    // Remove stray standalone $ lines
    cleaned = cleaned.replaceAll(RegExp(r'^\$\s*$', multiLine: true), '');

    // 4. Clean up broken patterns but preserve good numbered lists
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'^\d+\.\s*\*+\s*$', multiLine: true),
      '',
    );

    // 5. Remove excessive symbols but preserve markdown
    // Remove triple asterisks entirely (avoid adding bold markers)
    cleaned = cleaned.replaceAll(RegExp(r'\*{3,}'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*\*{1,2}\s*$', multiLine: true),
      '',
    );

    // 6. Clean up whitespace and ensure proper spacing
    cleaned = cleaned.replaceAll(RegExp(r'  +'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 7. Ensure proper spacing around headers
    cleaned = cleaned.replaceAll(
      RegExp(r'(##[^\n]+)\n([A-Za-z])'),
      r'$1\n\n$2',
    );
    cleaned = cleaned.replaceAll(RegExp(r'([.!?])\n(##)'), r'$1\n\n$2');

    // 8. Add clickable links for common legal resources
    cleaned = _addClickableLinks(cleaned);

    // 9. Ensure proper paragraph spacing
    cleaned = cleaned.replaceAll(RegExp(r'([.!?])\n([A-Z][a-z])'), r'$1\n\n$2');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*1\s*-\s*'), '• ');
    cleaned = cleaned.replaceAll(RegExp(r'[•\d\s]+•[•\d\s]+'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[•\d]+\s*[•\d\s]*$', multiLine: true),
      '',
    );
    // Avoid removing legitimate years/quantities; only collapse repeated bullets
    cleaned = cleaned.replaceAll(RegExp(r'(•\s*){3,}'), '• ');
    // Remove duplicated bullet clusters like "• • •"
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:^|\s)(?:•\s+){2,}', multiLine: true),
      ' • ',
    );
    // Avoid removing punctuation clusters that might include '://'
    // cleaned = cleaned.replaceAll(RegExp(r'([^\\w\\s]\\s*){3,}'), '');

    // 4. Remove excessive asterisks and broken markdown
    cleaned = cleaned.replaceAll(RegExp(r'\*{3,}'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*\*{1,2}\s*$', multiLine: true),
      '',
    );

    // 5. Remove broken bullet points and empty lines
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[•·-]\s*\*{0,2}\s*$', multiLine: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-–—]\s*$', multiLine: true), '');

    // 6. Remove lines that contain only symbols or numbers
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[\d\$\*\-•·]+\s*$', multiLine: true),
      '',
    );

    // 7. Clean up broken formatting artifacts
    cleaned = cleaned.replaceAll(RegExp(r'\*{2,}([^*\n]*)\*{2,}'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\*{1,2}\s+'), ' ');

    // 8. Remove broken section headers that are just symbols
    cleaned = cleaned.replaceAll(RegExp(r'^[#*\d:]+\s*$', multiLine: true), '');

    // 9. Normalize ordered lists to "1. Item" format (avoid weird spacing)
    cleaned = cleaned.replaceAll(
      RegExp(r'^(\d+)\s*[\.|\)]\s*', multiLine: true),
      r'$1. ',
    );

    // 9b. Remove stray leading single-digit artifacts at line start that stick to words (e.g., "1overtime")
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*([0-9])(?![\.)])(?=[A-Za-z])', multiLine: true),
      '',
    );

    // 10. Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'  +'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 11. Format emoji headers with proper markdown
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^([🔍🏛️⚖️🎯📋🌐💼📞]).{0,5}\*{0,2}(.+?)\*{0,2}\s*$',
        multiLine: true,
      ),
      r'## $1 **$2**',
    );

    // 12. Format bullet points properly (normalize to '- ')
    cleaned = cleaned.replaceAll(RegExp(r'^[-•]\s*', multiLine: true), '- ');

    // 13. Format section headers
    cleaned = cleaned.replaceAll(
      RegExp(r'^([^:\n]+):[ ]*$', multiLine: true),
      r'**$1:**',
    );

    // 14. Normalize and autolink URLs
    // 14a. Convert 'Label (https://example.com)' to '[Label](https://example.com)'
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^\n\[\]()]{2,}?)\s*\((https?://[^\s)]+)\)'),
      (m) {
        final label = (m.group(1) ?? '').trim();
        final url = m.group(2) ?? '';
        // If the label itself looks like a URL, keep original
        if (label.toLowerCase().startsWith('http')) return m.group(0) ?? '';
        return '[$label]($url)';
      },
    );
    // 14b. Wrap any remaining bare URLs with <> so flutter_markdown makes them clickable
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\]\()https?://[^\s)]+'),
      (m) => '<${m.group(0)!}>',
    );

    // 14c. Add clickable links for known resources by name
    cleaned = _addClickableLinks(cleaned);

    // 15. Clean up excessive spaces
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');

    // 16. Ensure proper paragraph spacing
    cleaned = cleaned.replaceAll(RegExp(r'\n([A-Z])'), r'\n\n$1');

    // 17. Fix any remaining artifacts (strip excessive asterisks)
    cleaned = cleaned.replaceAll(RegExp(r'\*{3,}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\*\*'), '');

    // 18. Final cleanup - remove stray $ not part of currency (keep $15 etc.)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(^|\s)\$(?=\s|$)', multiLine: true),
      (m) => m.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[\d:]+\s*$', multiLine: true),
      '',
    );

    return cleaned.trim();
  }

  /// Add clickable links to legal resources mentioned in the response
  String _addClickableLinks(String text) {
    // Add links for common legal resources
    text = text.replaceAll(
      RegExp(
        r'(legal aid societies|legal aid organizations)',
        caseSensitive: false,
      ),
      '[Legal Aid Organizations](https://www.lsc.gov/what-legal-aid/find-legal-aid)',
    );

    text = text.replaceAll(
      RegExp(
        r'(court self-help centers|self-help centers)',
        caseSensitive: false,
      ),
      '[Court Self-Help Centers](https://www.courts.ca.gov/selfhelp.htm)',
    );

    text = text.replaceAll(
      RegExp(r'(pro bono services|pro bono)', caseSensitive: false),
      '[Pro Bono Services](https://www.americanbar.org/groups/legal_aid_indigent_defense/)',
    );

    text = text.replaceAll(
      RegExp(r'(legal clinics|law school clinics)', caseSensitive: false),
      '[Legal Clinics](https://www.abafreelegalanswers.org/)',
    );

    text = text.replaceAll(
      RegExp(r'(ACLU)', caseSensitive: false),
      '[ACLU](https://www.aclu.org/)',
    );

    text = text.replaceAll(
      RegExp(r'(Better Business Bureau|BBB)', caseSensitive: false),
      '[Better Business Bureau](https://www.bbb.org/)',
    );

    text = text.replaceAll(
      RegExp(r'(Federal Trade Commission|FTC)', caseSensitive: false),
      '[Federal Trade Commission](https://www.ftc.gov/)',
    );

    text = text.replaceAll(
      RegExp(r'(small claims court)', caseSensitive: false),
      '[Small Claims Court](https://www.uscourts.gov/about-federal-courts/types-cases/civil-cases)',
    );

    return text;
  }

  /// Build comprehensive analysis result - AI ONLY
  LegalAnalysisResult _buildAnalysisResult({
    required String question,
    required String jurisdiction,
    required List<LegalScenario> localScenarios,
    required Map<String, dynamic> webData,
    required String aiResponse,
  }) {
    // Use ONLY AI response - no other sources
    String finalResponse = '';

    if (aiResponse.isNotEmpty) {
      print('DEBUG: Using AI response of length ${aiResponse.length}');

      // Clean and format the AI response
      finalResponse = _cleanAndFormatResponse(aiResponse);
    } else {
      print('DEBUG: No AI response - using fallback');
      finalResponse =
          '''I understand you're looking for legal guidance. While I don't have access to my AI analysis right now, I'd recommend consulting with a qualified attorney who can provide personalized advice for your specific situation.

You can find free legal help through:
• [Legal Aid Services](https://www.lsc.gov/what-legal-aid/find-legal-aid)
• [Court Self-Help Centers](https://www.courts.ca.gov/selfhelp.htm)
• [Pro Bono Legal Services](https://www.americanbar.org/groups/legal_aid_indigent_defense/)

For immediate help, you can also contact your local bar association for referrals to qualified attorneys in your area.''';
    }

    // Generate actions from AI response content
    List<String> actions = _extractActionsFromResponse(finalResponse);

    // Get contacts from local data
    List<LegalAidContact> contacts = [];
    try {
      contacts = LegalDataService.getLegalAidContacts(jurisdiction);
    } catch (e) {
      print('DEBUG: Error getting contacts: $e');
    }

    // Get letter template if available
    String? letterTemplate;
    if (localScenarios.isNotEmpty) {
      letterTemplate = localScenarios.first.letterTemplate;
    }

    return LegalAnalysisResult(
      userQuery: question,
      jurisdiction: jurisdiction,
      rightsSummary: finalResponse,
      stepByStepActions: actions,
      generatedLetter: letterTemplate,
      relevantContacts: contacts,
      matchingScenarios: localScenarios,
      timestamp: DateTime.now(),
      id: _uuid.v4(),
    );
  }

  /// Extract action items from AI response text
  List<String> _extractActionsFromResponse(String response) {
    List<String> actions = [];

    // Look for action-oriented sentences
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

    // Add some general actions if none found
    if (actions.isEmpty) {
      actions = [
        'Document all relevant facts and communications',
        'Gather supporting evidence and documents',
        'Consider consulting with a qualified attorney',
        'Check local legal aid organizations for assistance',
      ];
    }

    return actions.take(10).toList();
  }

  // Removed legacy _buildFallbackResult: AI-first flow now handles fallback text inline
}
