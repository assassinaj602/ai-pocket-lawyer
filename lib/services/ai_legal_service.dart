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

  // SECURITY: No hardcoded API keys for public repos
  static const String _fallbackModel = 'deepseek/deepseek-chat-v3-0324:free';

  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();
  final WebScrapingService _webScrapingService = WebScrapingService();

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
    try {
      print('Starting legal analysis for: $question');

      // Step 1: Get local legal data
      final localScenarios = LegalDataService.searchScenarios(
        question,
        jurisdiction,
      );

      // Step 2: Scrape real-time legal information
      final webData = await _webScrapingService.searchLegalInfo(
        query: question,
        jurisdiction: jurisdiction,
        category: category ?? _categorizeQuery(question),
      );

      // Step 3: Combine local and web data
      String combinedContext = _buildCombinedContext(localScenarios, webData);

      // Step 4: Get AI enhancement if API key is available
      String aiEnhancedResponse = '';

      // Use smart getters for redundancy (supports both .env and APK builds)
      String apiKey = _getApiKey();
      String model = _getModel();

      print('DEBUG: API Key available: ${apiKey.isNotEmpty ? 'Yes' : 'No'}');
      print('DEBUG: Model: $model');
      if (apiKey.isNotEmpty) {
        print('DEBUG: API Key starts with: ${apiKey.substring(0, 15)}...');
      }

      if (apiKey.isNotEmpty) {
        print('DEBUG: Attempting to call OpenRouter API...');
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
      } else {
        print('DEBUG: No valid API key available');
      }

      // Step 5: Build comprehensive response
      return _buildAnalysisResult(
        question: question,
        jurisdiction: jurisdiction,
        localScenarios: localScenarios,
        webData: webData,
        aiResponse: aiEnhancedResponse,
      );
    } catch (e) {
      print('Error in AI legal analysis: $e');

      // Fallback to local data only
      final localScenarios = LegalDataService.searchScenarios(
        question,
        jurisdiction,
      );

      return _buildFallbackResult(question, jurisdiction, localScenarios);
    }
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

      // Get category for enhanced prompting
      String category = _categorizeQuery(question);
      String categoryPrompt = _getCategorySpecificPrompt(
        category,
        jurisdiction,
      );

      final response = await _dio.post(
        _openRouterBaseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://ai-pocket-lawyer.com',
            'X-Title': 'AI Pocket Lawyer',
          },
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
                  '''You are a senior legal counsel and expert advisor specializing in $jurisdiction law with 20+ years of experience. Provide comprehensive, sophisticated legal guidance that demonstrates deep understanding of legal principles, procedures, and practical implications.

$categoryPrompt

ADVANCED RESPONSE STRUCTURE:

🏛️ **COMPREHENSIVE LEGAL ANALYSIS**
• Conduct thorough legal issue identification and characterization
• Analyze applicable statutory frameworks, regulations, and case law precedents
• Assess strength of legal position using legal standards and burden of proof
• Identify potential legal theories, claims, and defenses
• Evaluate jurisdictional considerations and venue requirements

⚖️ **DETAILED RIGHTS & LEGAL POSITION ASSESSMENT**
• Enumerate specific statutory and constitutional rights with citations
• Outline correlating legal duties and obligations of all parties
• Detail enforcement mechanisms and remedies available
• Specify critical deadlines, statutes of limitations, and procedural requirements
• Analyze potential damages, relief options, and equitable remedies

🎯 **STRATEGIC ACTION PLAN & PROCEDURAL ROADMAP**
• Immediate preservation actions (evidence, documentation, witness statements)
• Strategic communication protocols and documentation requirements
• Phased approach with timelines, priorities, and contingency planning
• Pre-litigation strategies and alternative dispute resolution options
• Court filing requirements, procedural steps, and jurisdictional considerations

� **AUTHORITATIVE LEGAL FRAMEWORK**
• Specific statute citations, regulation references, and relevant code sections
• Key case law precedents with distinguishing factors and holding analysis
• Recent legal developments, amendments, and emerging jurisprudence
• Administrative agency guidance, enforcement policies, and interpretive rules
• Professional conduct rules and ethical considerations

⚠️ **COMPREHENSIVE RISK ANALYSIS**
• Detailed assessment of legal exposure and potential adverse outcomes
• Strategic risks of various courses of action with mitigation strategies
• Cost-benefit analysis including attorney fees, court costs, and time investment
• Reputational, financial, and operational impact considerations
• Statute of limitations and procedural deadline risks

� **PROFESSIONAL RESOURCE ECOSYSTEM**
• Specialized attorney referrals by practice area and experience level
• Bar association resources, CLE programs, and professional networks
• Government agency contacts, ombudsman offices, and regulatory bodies
• Expert witness resources, forensic services, and investigative support
• Legal technology tools, research databases, and practice management resources

🔍 **INVESTIGATION & EVIDENCE DEVELOPMENT**
• Specific evidence collection protocols and preservation requirements
• Discovery strategies and information gathering techniques
• Expert witness identification and qualification requirements
• Document analysis, chain of custody, and authentication procedures
• Investigative resources and fact-finding methodologies

💰 **COST ANALYSIS & FUNDING OPTIONS**
• Detailed breakdown of potential legal costs and fee structures
• Contingency fee arrangements and alternative billing options
• Legal insurance coverage analysis and claim procedures
• Pro bono eligibility criteria and application processes
• Litigation financing options and third-party funding considerations

📋 **COMPLIANCE & REGULATORY CONSIDERATIONS**
• Industry-specific regulations and compliance requirements
• Reporting obligations and disclosure requirements
• Licensing, permitting, and regulatory approval processes
• Audit risks and regulatory enforcement considerations
• Best practices for ongoing compliance and risk management

ADVANCED GUIDELINES:
- Use EXACT formatting: Start each section with ## and emoji headers
- Provide nuanced analysis considering multiple legal theories and jurisdictional variations
- Include specific procedural requirements, filing deadlines, and court rules with statute citations
- Analyze potential outcomes using legal precedents and statistical likelihood
- Suggest strategic considerations for negotiation and settlement with cost estimates
- Consider tax implications, business impacts, and long-term consequences
- Reference authoritative legal sources, treatises, and practice guides with citations
- Address ethical considerations and professional responsibility issues

MANDATORY: Include a "🌐 **ESSENTIAL LEGAL RESOURCES & WEBSITES**" section with:
- Government websites (.gov) for forms, procedures, and official information
- Legal aid organization websites with eligibility criteria
- Court websites for filing procedures and local rules
- Bar association websites for attorney referrals
- Professional organization websites for specialized resources
- Free legal research websites (justia.com, findlaw.com, etc.)
- Provide actual website URLs when possible for $jurisdiction

RESPONSE FORMAT REQUIREMENTS:
- Start with a brief executive summary paragraph
- Use clear section headers like "Legal Analysis:", "Your Rights:", "Recommended Actions:", etc.
- Use numbered lists for step-by-step actions (1. 2. 3.)
- Use bullet points (•) for detailed information within sections
- Include specific dollar amounts for cost estimates where applicable
- Provide realistic timelines (days/weeks/months)
- Make sections distinct and well-spaced
- End with comprehensive legal disclaimer

Context from legal databases and official sources:
$context''',
            },
            {
              'role': 'user',
              'content':
                  '''I require comprehensive legal counsel and strategic guidance for this complex legal matter:

**Legal Issue:** $question

**Jurisdiction:** $jurisdiction

Please provide an exhaustive legal analysis following your advanced framework. I need:

**Immediate Requirements:**
- Complete legal issue characterization with all applicable legal theories
- Comprehensive rights analysis with specific statutory and case law citations
- Strategic action plan with detailed timelines and procedural requirements
- Risk assessment with quantified exposure analysis and mitigation strategies

**Strategic Considerations:**
- Multiple legal approach options with comparative analysis
- Negotiation strategies and settlement considerations
- Long-term implications and precedential impact
- Cost-benefit analysis including fee structures and funding options

**Professional Support Network:**
- Specialized attorney referrals with specific qualifications
- Expert witness requirements and qualification criteria
- Investigation and evidence development protocols
- Regulatory compliance and reporting obligations

**Advanced Analysis:**
- Procedural strategy and court filing requirements
- Discovery planning and evidence preservation protocols
- Alternative dispute resolution feasibility and strategies
- Appeal rights and post-judgment enforcement options

**Website Resources Required:**
- Government websites for official forms and procedures
- Legal aid websites with eligibility and application information
- Court websites for local filing requirements and procedures
- Bar association websites for attorney referral services
- Professional organization websites for specialized resources
- Free legal research and self-help websites

I understand this constitutes legal information for educational purposes and will seek qualified legal representation for formal legal advice and representation. Please format your response using proper markdown headers (##) and include comprehensive website resources.''',
            },
          ],
          'max_tokens': 4500,
          'temperature': 0.1,
          'top_p': 0.7,
        },
      );

      print('DEBUG: API Response status: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('DEBUG: Raw response data: ${response.data}');
        final aiResponse = response.data['choices']?[0]?['message']?['content'];
        print(
          'DEBUG: Extracted AI Response: ${aiResponse?.substring(0, 100) ?? 'null'}...',
        );
        print('DEBUG: AI Response length: ${aiResponse?.length ?? 0}');
        return aiResponse ?? '';
      } else {
        print('OpenRouter API error: ${response.statusCode}');
        print('Response data: ${response.data}');
        return '';
      }
    } catch (e) {
      print('Error calling OpenRouter API: $e');
      print('Error type: ${e.runtimeType}');

      // If it's a timeout error, try with a simplified request
      if (e.toString().contains('timeout') ||
          e.toString().contains('receive timeout')) {
        print('DEBUG: Timeout detected, trying simplified request...');
        return _getSimplifiedAIResponse(question, jurisdiction, apiKey, model);
      }

      if (e is DioException) {
        print('DioException details: ${e.response?.data}');
        print('DioException status: ${e.response?.statusCode}');
      }
      return '';
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
                  '''You are an expert legal advisor. Provide clear, comprehensive legal guidance in a professional format.

Use this structure:
## Legal Analysis
## Your Rights  
## Recommended Actions
## Important Resources
## Legal Disclaimer

Be thorough but concise. Include specific legal concepts, deadlines, and practical steps.''',
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
        final aiResponse = response.data['choices']?[0]?['message']?['content'];
        print(
          'DEBUG: Simplified AI Response received: ${aiResponse?.isNotEmpty ?? false}',
        );
        return aiResponse ?? '';
      } else {
        print('Simplified API error: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error in simplified API call: $e');
      return '';
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

    // Replace multiple line breaks with proper spacing
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Ensure emoji headers have proper markdown formatting
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^([🔍🏛️⚖️🎯📋🌐💼📞]).{0,5}\*{0,2}(.+?)\*{0,2}\s*$',
        multiLine: true,
      ),
      '## \$1 **\$2**',
    );

    // Format numbered lists with proper markdown
    cleaned = cleaned.replaceAll(RegExp(r'^(\d+)\.\s*'), '**\$1.** ');

    // Format bullet points with proper markdown
    cleaned = cleaned.replaceAll(RegExp(r'^[-•]\s*'), '• ');

    // Ensure bold formatting is preserved for section headers
    cleaned = cleaned.replaceAll(
      RegExp(r'^([^:\n]+):[ ]*$', multiLine: true),
      '**\$1:**',
    );

    // Clean up excessive spaces
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');

    // Ensure proper paragraph spacing
    cleaned = cleaned.replaceAll(RegExp(r'\n([A-Z])'), '\n\n\$1');

    // Fix any double asterisks that might have been created
    cleaned = cleaned.replaceAll(RegExp(r'\*{3,}'), '**');

    return cleaned.trim();
  }

  /// Build comprehensive analysis result
  LegalAnalysisResult _buildAnalysisResult({
    required String question,
    required String jurisdiction,
    required List<LegalScenario> localScenarios,
    required Map<String, dynamic> webData,
    required String aiResponse,
  }) {
    // Build comprehensive response with better formatting
    StringBuffer response = StringBuffer();

    if (aiResponse.isNotEmpty) {
      print(
        'DEBUG: Building result with AI response of length ${aiResponse.length}',
      );

      // Clean and format the AI response
      String cleanedResponse = _cleanAndFormatResponse(aiResponse);

      response.writeln('# 🤖 AI-Enhanced Legal Analysis\n');
      response.writeln(cleanedResponse);
      response.writeln('\n---\n');
    } else {
      print('DEBUG: No AI response - using local data only');
      response.writeln('# 📚 Legal Database Analysis\n');
    }

    // Add local scenario information with better formatting
    if (localScenarios.isNotEmpty) {
      response.writeln('## 📖 Related Legal Scenarios\n');

      for (var scenario in localScenarios.take(2)) {
        response.writeln('### ${scenario.problem}\n');
        response.writeln('**Applicable Law:** ${scenario.applicableLaw}\n');
        if (scenario.rightsSummary.isNotEmpty) {
          response.writeln('**Your Rights:** ${scenario.rightsSummary}\n');
        }
        response.writeln('---\n');
      }
    }

    // Add web data if available with better formatting
    if (webData['success'] == true && webData['content'] != null) {
      response.writeln('## 🌐 Real-Time Legal Information\n');
      String webContent = webData['content'].toString();
      // Clean and format web content
      webContent = _cleanAndFormatResponse(webContent);
      response.writeln(webContent);
      response.writeln('\n---\n');
    }

    response.writeln('## ⚖️ Important Legal Disclaimer\n');
    response.writeln(
      '> This information is provided for educational purposes only and does not constitute legal advice.',
    );
    response.writeln(
      '> Laws vary by jurisdiction and circumstances. For specific legal matters, please consult with a qualified attorney in your area.\n',
    );

    // Combine all actions
    List<String> allActions = [];
    for (var scenario in localScenarios) {
      allActions.addAll(scenario.actions);
    }

    // Add general next steps
    allActions.addAll([
      'Document all relevant facts and communications',
      'Gather supporting evidence and documents',
      'Consider consulting with a qualified attorney',
      'Check local legal aid organizations for assistance',
    ]);

    // Get contacts (for now, empty - you can implement this)
    List<LegalAidContact> contacts = [];

    // Get letter template
    String? letterTemplate;
    if (localScenarios.isNotEmpty) {
      letterTemplate = localScenarios.first.letterTemplate;
    }

    return LegalAnalysisResult(
      userQuery: question,
      jurisdiction: jurisdiction,
      rightsSummary: response.toString(),
      stepByStepActions: allActions.take(10).toList(),
      generatedLetter: letterTemplate,
      relevantContacts: contacts,
      matchingScenarios: localScenarios,
      timestamp: DateTime.now(),
      id: _uuid.v4(),
    );
  }

  /// Build fallback result when AI and web scraping fail
  LegalAnalysisResult _buildFallbackResult(
    String question,
    String jurisdiction,
    List<LegalScenario> scenarios,
  ) {
    LegalScenario? primaryScenario;
    if (scenarios.isNotEmpty) {
      primaryScenario = scenarios.first;
    }

    String response = '''
Based on our legal database, here's relevant information for your question:

${primaryScenario?.problem ?? 'We found some relevant legal information that may help with your situation.'}

Applicable Law: ${primaryScenario?.applicableLaw ?? 'Various applicable laws may apply.'}

${primaryScenario?.rightsSummary.isNotEmpty == true ? 'Your Rights:\n${primaryScenario!.rightsSummary}\n\n' : ''}

This information is provided for educational purposes only. Please consult with a qualified attorney for specific legal advice.
''';

    return LegalAnalysisResult(
      userQuery: question,
      jurisdiction: jurisdiction,
      rightsSummary: response,
      stepByStepActions:
          primaryScenario?.actions ??
          [
            'Consult with a qualified attorney',
            'Document your situation',
            'Research local laws and regulations',
          ],
      generatedLetter: primaryScenario?.letterTemplate,
      relevantContacts: [],
      matchingScenarios: scenarios,
      timestamp: DateTime.now(),
      id: _uuid.v4(),
    );
  }

  /// Get category-specific legal focus areas to enhance AI responses
  String _getCategorySpecificPrompt(String category, String jurisdiction) {
    switch (category) {
      case 'housing':
        return '''
ADVANCED HOUSING LAW EXPERTISE:
- Comprehensive landlord-tenant relationship analysis with warranty of habitability standards
- Rent stabilization laws, rent control ordinances, and just cause eviction protections
- Security deposit regulations including interest requirements and return procedures
- Habitability violations with code enforcement procedures and tenant remedies
- Lease interpretation using contract law principles and consumer protection statutes
- Housing discrimination analysis under Fair Housing Act and state/local ordinances
- Eviction defense strategies including procedural defenses and substantive challenges
- Tenant organizing rights, collective action protections, and retaliation prohibitions
- Mobile home park regulations, manufactured housing standards, and relocation assistance
- Subsidized housing regulations, Section 8 compliance, and public housing policies
''';

      case 'employment':
        return '''
ADVANCED EMPLOYMENT LAW EXPERTISE:
- Comprehensive wage and hour analysis including FLSA overtime, break requirements, and meal periods
- Workplace discrimination under Title VII, ADA, ADEA with intersectionality considerations
- Wrongful termination analysis including at-will exceptions, public policy violations, and implied contracts
- Workers' compensation claim procedures, medical treatment rights, and permanent disability assessments
- FMLA compliance, state family leave laws, and accommodation requirements
- Union organizing rights, collective bargaining protections, and labor relations
- Workplace safety analysis under OSHA with whistleblower protections and citation procedures
- Non-compete agreements, trade secret protection, and post-employment restrictions
- Executive compensation, severance negotiations, and employment contract interpretation
- Classification issues (employee vs. contractor) with economic realities and control tests
''';

      case 'consumer':
        return '''
CONSUMER PROTECTION FOCUS:
- Consumer warranty and return rights
- Debt collection practices
- Credit reporting and repair
- Fraud and scam protection
- Contract terms and unfair practices
- Lemon laws for vehicles
- Identity theft and privacy rights
''';

      case 'family':
        return '''
FAMILY LAW FOCUS:
- Child custody and visitation rights
- Child and spousal support calculations
- Divorce procedures and property division
- Domestic violence protection orders
- Adoption and parental rights
- Prenuptial and postnuptial agreements
- Guardianship and conservatorship
''';

      case 'criminal':
        return '''
CRIMINAL LAW FOCUS:
- Constitutional rights (Miranda, search/seizure)
- Bail and pretrial procedures
- Plea bargaining and sentencing
- Expungement and record sealing
- Victim rights and restitution
- Probation and parole conditions
- Appeal and post-conviction relief
''';

      case 'immigration':
        return '''
IMMIGRATION LAW FOCUS:
- Visa applications and renewals
- Green card and citizenship processes
- Deportation defense and removal proceedings
- Asylum and refugee status
- Work authorization and employment verification
- Family reunification petitions
- Immigration court procedures
''';

      case 'personal_injury':
        return '''
PERSONAL INJURY FOCUS:
- Negligence and liability standards
- Medical malpractice claims
- Auto accident compensation
- Slip and fall premises liability
- Product liability and defective products
- Insurance claim procedures
- Statute of limitations deadlines
''';

      case 'business':
        return '''
BUSINESS LAW FOCUS:
- Business formation and structure
- Contract drafting and disputes
- Intellectual property protection
- Employment law compliance
- Tax obligations and planning
- Regulatory compliance
- Merger and acquisition procedures
''';

      case 'estate':
        return '''
ESTATE PLANNING FOCUS:
- Will drafting and execution requirements
- Trust creation and administration
- Probate procedures and timelines
- Power of attorney documents
- Healthcare directives and living wills
- Estate tax planning
- Guardianship and conservatorship
''';

      case 'tax':
        return '''
TAX LAW FOCUS:
- Tax filing requirements and deadlines
- Deduction and credit eligibility
- Audit procedures and representation
- Tax debt resolution and payment plans
- Business tax obligations
- Estate and gift tax planning
- Tax penalty relief and abatement
''';

      default:
        return '''
GENERAL LEGAL FOCUS:
- Identify the specific area of law involved
- Determine applicable statutes and regulations
- Assess procedural requirements and deadlines
- Consider alternative dispute resolution options
- Evaluate potential costs and risks
- Identify necessary documentation and evidence
''';
    }
  }
}
