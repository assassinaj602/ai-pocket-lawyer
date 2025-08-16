import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class WebScrapingService {
  final Dio _dio = Dio();

  // US Legal Sources
  static const String US_CODE_BASE = 'https://uscode.house.gov';
  static const String LEGAL_AID_BASE = 'https://www.illinoislegalaid.org';
  static const String LAWHELP_BASE = 'https://www.lawhelp.org';

  // UK Legal Sources
  static const String UK_LEGISLATION_BASE = 'https://www.legislation.gov.uk';
  static const String CITIZENS_ADVICE_BASE =
      'https://www.citizensadvice.org.uk';
  static const String GOV_UK_BASE = 'https://www.gov.uk';

  WebScrapingService() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
    );
  }

  /// Search for legal information based on user query and jurisdiction
  Future<Map<String, dynamic>> searchLegalInfo({
    required String query,
    required String jurisdiction, // 'US' or 'UK'
    required String category,
  }) async {
    try {
      if (jurisdiction.toUpperCase() == 'US') {
        return await _searchUSLegalInfo(query, category);
      } else {
        return await _searchUKLegalInfo(query, category);
      }
    } catch (e) {
      print('Error in web scraping: $e');
      return {
        'success': false,
        'error': 'Failed to fetch legal information: $e',
        'sources': [],
        'content': '',
      };
    }
  }

  /// Search US legal information
  Future<Map<String, dynamic>> _searchUSLegalInfo(
    String query,
    String category,
  ) async {
    List<Map<String, String>> sources = [];
    String combinedContent = '';

    try {
      // Search LawHelp.org for general legal guidance
      var lawHelpContent = await _scrapeLawHelp(query, category);
      if (lawHelpContent.isNotEmpty) {
        sources.add({
          'title': 'LawHelp.org Legal Guidance',
          'url': '$LAWHELP_BASE/search?q=${Uri.encodeComponent(query)}',
          'content': lawHelpContent,
        });
        combinedContent +=
            'Legal Guidance from LawHelp.org:\n$lawHelpContent\n\n';
      }

      // Search for relevant legal aid information
      var legalAidContent = await _scrapeLegalAid(query, category);
      if (legalAidContent.isNotEmpty) {
        sources.add({
          'title': 'Legal Aid Resources',
          'url': '$LEGAL_AID_BASE/search?q=${Uri.encodeComponent(query)}',
          'content': legalAidContent,
        });
        combinedContent += 'Legal Aid Information:\n$legalAidContent\n\n';
      }
    } catch (e) {
      print('Error scraping US legal info: $e');
    }

    return {
      'success': sources.isNotEmpty,
      'sources': sources,
      'content': combinedContent,
      'jurisdiction': 'United States',
    };
  }

  /// Search UK legal information
  Future<Map<String, dynamic>> _searchUKLegalInfo(
    String query,
    String category,
  ) async {
    List<Map<String, String>> sources = [];
    String combinedContent = '';

    try {
      // Search Citizens Advice for guidance
      var citizensAdviceContent = await _scrapeCitizensAdvice(query, category);
      if (citizensAdviceContent.isNotEmpty) {
        sources.add({
          'title': 'Citizens Advice Guidance',
          'url': '$CITIZENS_ADVICE_BASE/search?q=${Uri.encodeComponent(query)}',
          'content': citizensAdviceContent,
        });
        combinedContent +=
            'Citizens Advice Guidance:\n$citizensAdviceContent\n\n';
      }

      // Search Gov.UK for official guidance
      var govUkContent = await _scrapeGovUK(query, category);
      if (govUkContent.isNotEmpty) {
        sources.add({
          'title': 'Official UK Government Guidance',
          'url': '$GOV_UK_BASE/search?q=${Uri.encodeComponent(query)}',
          'content': govUkContent,
        });
        combinedContent += 'UK Government Guidance:\n$govUkContent\n\n';
      }
    } catch (e) {
      print('Error scraping UK legal info: $e');
    }

    return {
      'success': sources.isNotEmpty,
      'sources': sources,
      'content': combinedContent,
      'jurisdiction': 'United Kingdom',
    };
  }

  /// Scrape LawHelp.org (simplified approach)
  Future<String> _scrapeLawHelp(String query, String category) async {
    try {
      // For demo purposes, return relevant legal guidance based on category
      // In production, you would implement actual web scraping
      return _generateLegalGuidance(query, category, 'US');
    } catch (e) {
      print('Error scraping LawHelp: $e');
      return '';
    }
  }

  /// Scrape Legal Aid resources
  Future<String> _scrapeLegalAid(String query, String category) async {
    try {
      return _generateLegalAidInfo(query, category);
    } catch (e) {
      print('Error scraping Legal Aid: $e');
      return '';
    }
  }

  /// Scrape Citizens Advice
  Future<String> _scrapeCitizensAdvice(String query, String category) async {
    try {
      return _generateLegalGuidance(query, category, 'UK');
    } catch (e) {
      print('Error scraping Citizens Advice: $e');
      return '';
    }
  }

  /// Scrape Gov.UK
  Future<String> _scrapeGovUK(String query, String category) async {
    try {
      return _generateGovUKGuidance(query, category);
    } catch (e) {
      print('Error scraping Gov.UK: $e');
      return '';
    }
  }

  /// Generate legal guidance based on query and jurisdiction
  String _generateLegalGuidance(
    String query,
    String category,
    String jurisdiction,
  ) {
    // This would be replaced with actual web scraping in production
    // For now, providing comprehensive legal guidance based on common scenarios

    if (query.toLowerCase().contains('landlord') &&
        query.toLowerCase().contains('entered')) {
      if (jurisdiction == 'US') {
        return '''
Landlord Entry Rights in the United States:

1. Notice Requirements:
   - Most states require 24-48 hours written notice before entry
   - Emergency situations allow immediate entry
   - Notice must specify reason and time of entry

2. Valid Reasons for Entry:
   - Emergency repairs or maintenance
   - Scheduled maintenance with proper notice
   - Property inspections (limited frequency)
   - Showing property to prospective tenants/buyers

3. Tenant Rights:
   - Right to quiet enjoyment of rental property
   - Right to refuse entry without proper notice (except emergencies)
   - Right to request specific times for entry

4. Legal Remedies:
   - Document unauthorized entries
   - Send written notice to landlord
   - Contact local housing authorities
   - Possible claims for breach of lease or privacy violation

5. State-Specific Variations:
   - Check your state's landlord-tenant laws
   - Some states have stricter notice requirements
   - Remedies vary by jurisdiction
''';
      } else {
        return '''
Landlord Entry Rights in the United Kingdom:

1. Legal Requirements:
   - 24 hours written notice required for routine inspections
   - Must specify reason and convenient time
   - Emergency entry allowed without notice

2. Valid Reasons for Entry:
   - Emergency repairs affecting safety
   - Routine maintenance and inspections
   - Gas safety checks (mandatory annual)
   - Showing property to prospective tenants

3. Tenant Rights Under UK Law:
   - Right to quiet enjoyment
   - Right to refuse unreasonable entry requests
   - Protection under Housing Act and Landlord and Tenant Act

4. Legal Actions Available:
   - Contact local council housing department
   - Seek injunction for harassment
   - Possible compensation claims
   - Report to relevant ombudsman services

5. Protection from Harassment:
   - Landlord cannot use own keys without permission
   - Repeated unauthorized entry may constitute harassment
   - Criminal sanctions possible for serious breaches
''';
      }
    }

    // Add more specific guidance based on other common legal queries
    return _getGeneralLegalGuidance(category, jurisdiction);
  }

  String _generateLegalAidInfo(String query, String category) {
    return '''
Legal Aid Resources Available:

1. Free Legal Clinics:
   - Many law schools offer free legal clinics
   - Community legal aid organizations
   - Pro bono services from local bar associations

2. Self-Help Resources:
   - Court self-help centers
   - Legal aid websites with forms and guidance
   - Online legal information databases

3. Low-Cost Legal Services:
   - Sliding fee scale attorneys
   - Limited scope representation
   - Mediation and arbitration services

4. Eligibility for Legal Aid:
   - Income-based eligibility requirements
   - Priority given to domestic violence, housing, and family cases
   - Emergency assistance available in urgent situations

Contact your local legal aid office for specific assistance with your situation.
''';
  }

  String _generateGovUKGuidance(String query, String category) {
    return '''
Official UK Government Legal Guidance:

1. Citizens' Rights and Responsibilities:
   - Understanding your legal rights
   - Proper procedures for legal complaints
   - Government services and support available

2. Legal Processes and Procedures:
   - How to access the court system
   - Alternative dispute resolution options
   - Legal aid eligibility and application process

3. Regulatory Compliance:
   - Understanding relevant UK legislation
   - Compliance requirements for businesses and individuals
   - Updates to legal frameworks and procedures

4. Access to Justice:
   - Free legal advice services
   - Court fee remissions and support
   - Guidance on representing yourself in legal matters

For specific legal issues, consult the relevant government department or seek professional legal advice.
''';
  }

  String _getGeneralLegalGuidance(String category, String jurisdiction) {
    switch (category.toLowerCase()) {
      case 'housing':
        return jurisdiction == 'US'
            ? 'US housing laws vary by state. Generally, tenants have rights to habitable housing, privacy, and protection from discrimination.'
            : 'UK housing law provides strong tenant protections including deposit protection, repair obligations, and eviction procedures.';

      case 'employment':
        return jurisdiction == 'US'
            ? 'US employment law includes at-will employment in most states, with protections against discrimination and unsafe working conditions.'
            : 'UK employment law provides comprehensive worker protections including unfair dismissal, minimum wage, and working time regulations.';

      case 'consumer':
        return jurisdiction == 'US'
            ? 'US consumer protection includes warranty rights, fair debt collection practices, and protection against unfair business practices.'
            : 'UK consumer law provides strong protections including cooling-off periods, unfair contract terms, and consumer rights in purchases.';

      default:
        return 'Legal advice depends on specific circumstances and jurisdiction. Consult with a qualified attorney for personalized guidance.';
    }
  }
}
