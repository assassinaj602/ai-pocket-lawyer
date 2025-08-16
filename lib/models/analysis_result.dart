import 'legal_models.dart';

class LegalAnalysisResult {
  final String userQuery;
  final String jurisdiction;
  final String rightsSummary;
  final List<String> stepByStepActions;
  final String? generatedLetter;
  final List<LegalAidContact> relevantContacts;
  final List<LegalScenario> matchingScenarios;
  final DateTime timestamp;
  final String id;

  LegalAnalysisResult({
    required this.userQuery,
    required this.jurisdiction,
    required this.rightsSummary,
    required this.stepByStepActions,
    this.generatedLetter,
    required this.relevantContacts,
    required this.matchingScenarios,
    required this.timestamp,
    required this.id,
  });

  factory LegalAnalysisResult.fromJson(Map<String, dynamic> json) {
    return LegalAnalysisResult(
      userQuery: json['user_query'] ?? '',
      jurisdiction: json['jurisdiction'] ?? '',
      rightsSummary: json['rights_summary'] ?? '',
      stepByStepActions: List<String>.from(json['step_by_step_actions'] ?? []),
      generatedLetter: json['generated_letter'],
      relevantContacts:
          (json['relevant_contacts'] as List? ?? [])
              .map((contact) => LegalAidContact.fromJson(contact))
              .toList(),
      matchingScenarios:
          (json['matching_scenarios'] as List? ?? [])
              .map((scenario) => LegalScenario.fromJson(scenario))
              .toList(),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_query': userQuery,
      'jurisdiction': jurisdiction,
      'rights_summary': rightsSummary,
      'step_by_step_actions': stepByStepActions,
      'generated_letter': generatedLetter,
      'relevant_contacts':
          relevantContacts
              .map(
                (c) => {
                  'name': c.name,
                  'phone': c.phone,
                  'website': c.website,
                  'description': c.description,
                  'areas': c.areas,
                },
              )
              .toList(),
      'matching_scenarios': matchingScenarios.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'id': id,
    };
  }
}
