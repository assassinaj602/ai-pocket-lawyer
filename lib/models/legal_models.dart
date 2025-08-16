class LegalScenario {
  final String id;
  final String problem;
  final String applicableLaw;
  final String rightsSummary;
  final List<String> actions;
  final String letterTemplate;

  LegalScenario({
    required this.id,
    required this.problem,
    required this.applicableLaw,
    required this.rightsSummary,
    required this.actions,
    required this.letterTemplate,
  });

  factory LegalScenario.fromJson(Map<String, dynamic> json) {
    return LegalScenario(
      id: json['id'] ?? '',
      problem: json['problem'] ?? '',
      applicableLaw: json['applicable_law'] ?? '',
      rightsSummary: json['rights_summary'] ?? '',
      actions: List<String>.from(json['actions'] ?? []),
      letterTemplate: json['letter_template'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'problem': problem,
      'applicable_law': applicableLaw,
      'rights_summary': rightsSummary,
      'actions': actions,
      'letter_template': letterTemplate,
    };
  }
}

class LegalCategory {
  final String title;
  final String description;
  final List<LegalScenario> scenarios;

  LegalCategory({
    required this.title,
    required this.description,
    required this.scenarios,
  });

  factory LegalCategory.fromJson(Map<String, dynamic> json) {
    return LegalCategory(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      scenarios:
          (json['scenarios'] as List? ?? [])
              .map((scenario) => LegalScenario.fromJson(scenario))
              .toList(),
    );
  }
}

class LegalAidContact {
  final String name;
  final String phone;
  final String website;
  final String description;
  final List<String> areas;

  LegalAidContact({
    required this.name,
    required this.phone,
    required this.website,
    required this.description,
    this.areas = const [],
  });

  factory LegalAidContact.fromJson(Map<String, dynamic> json) {
    return LegalAidContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      description: json['description'] ?? '',
      areas: List<String>.from(json['areas'] ?? []),
    );
  }
}

class LetterTemplate {
  final String title;
  final String template;

  LetterTemplate({required this.title, required this.template});

  factory LetterTemplate.fromJson(Map<String, dynamic> json) {
    return LetterTemplate(
      title: json['title'] ?? '',
      template: json['template'] ?? '',
    );
  }
}
