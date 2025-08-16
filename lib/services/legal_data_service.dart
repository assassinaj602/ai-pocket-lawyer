import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/legal_models.dart';

class LegalDataService {
  static Map<String, dynamic>? _usLegalData;
  static Map<String, dynamic>? _ukLegalData;
  static Map<String, dynamic>? _letterTemplates;

  static Future<void> initialize() async {
    await _loadLegalData();
  }

  static Future<void> _loadLegalData() async {
    try {
      // Load US legal data
      final usData = await rootBundle.loadString(
        'assets/data/us_legal_data.json',
      );
      _usLegalData = json.decode(usData);

      // Load UK legal data
      final ukData = await rootBundle.loadString(
        'assets/data/uk_legal_data.json',
      );
      _ukLegalData = json.decode(ukData);

      // Load letter templates
      final templatesData = await rootBundle.loadString(
        'assets/data/letter_templates.json',
      );
      _letterTemplates = json.decode(templatesData);
    } catch (e) {
      print('Error loading legal data: $e');
    }
  }

  static List<LegalScenario> searchScenarios(
    String query,
    String jurisdiction,
  ) {
    final data =
        jurisdiction.toLowerCase() == 'us' ? _usLegalData : _ukLegalData;
    if (data == null) return [];

    final commonLaws = data['common_laws'] as Map<String, dynamic>?;
    if (commonLaws == null) return [];

    List<LegalScenario> matchingScenarios = [];
    final queryLower = query.toLowerCase();

    for (final category in commonLaws.values) {
      final scenarios = category['scenarios'] as List<dynamic>? ?? [];
      for (final scenarioJson in scenarios) {
        final scenario = LegalScenario.fromJson(scenarioJson);

        // Simple keyword matching
        if (scenario.problem.toLowerCase().contains(queryLower) ||
            scenario.rightsSummary.toLowerCase().contains(queryLower) ||
            scenario.applicableLaw.toLowerCase().contains(queryLower)) {
          matchingScenarios.add(scenario);
        }
      }
    }

    return matchingScenarios;
  }

  static List<LegalAidContact> getLegalAidContacts(
    String jurisdiction, {
    String? region,
  }) {
    final data =
        jurisdiction.toLowerCase() == 'us' ? _usLegalData : _ukLegalData;
    if (data == null) return [];

    final legalAidData = data['legal_aid_contacts'] as Map<String, dynamic>?;
    if (legalAidData == null) return [];

    List<LegalAidContact> contacts = [];

    // Add national contacts
    final national = legalAidData['national'] as List<dynamic>? ?? [];
    for (final contactJson in national) {
      contacts.add(LegalAidContact.fromJson(contactJson));
    }

    // Add regional contacts if region specified
    if (region != null) {
      final regionalKey =
          jurisdiction.toLowerCase() == 'us' ? 'by_state' : 'by_region';
      final regional = legalAidData[regionalKey] as Map<String, dynamic>? ?? {};
      final regionContacts =
          regional[region.toLowerCase()] as List<dynamic>? ?? [];

      for (final contactJson in regionContacts) {
        contacts.add(LegalAidContact.fromJson(contactJson));
      }
    }

    return contacts;
  }

  static String? getLetterTemplate(String templateId, String jurisdiction) {
    if (_letterTemplates == null) return null;

    final templates =
        jurisdiction.toLowerCase() == 'us'
            ? _letterTemplates!['us_templates'] as Map<String, dynamic>?
            : _letterTemplates!['uk_templates'] as Map<String, dynamic>?;

    if (templates == null) return null;

    final template = templates[templateId] as Map<String, dynamic>?;
    return template?['template'] as String?;
  }

  static List<String> getAvailableCategories(String jurisdiction) {
    final data =
        jurisdiction.toLowerCase() == 'us' ? _usLegalData : _ukLegalData;
    if (data == null) return [];

    final commonLaws = data['common_laws'] as Map<String, dynamic>? ?? {};
    return commonLaws.keys.toList();
  }

  static LegalCategory? getCategory(String categoryId, String jurisdiction) {
    final data =
        jurisdiction.toLowerCase() == 'us' ? _usLegalData : _ukLegalData;
    if (data == null) return null;

    final commonLaws = data['common_laws'] as Map<String, dynamic>? ?? {};
    final categoryData = commonLaws[categoryId] as Map<String, dynamic>?;

    if (categoryData == null) return null;

    return LegalCategory.fromJson(categoryData);
  }
}
