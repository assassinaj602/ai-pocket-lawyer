import 'package:uuid/uuid.dart';

class CaseAttachment {
  final String id;
  final String name;
  final String path; // Local path/URI or URL
  final DateTime addedAt;

  CaseAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.addedAt,
  });

  factory CaseAttachment.fromJson(Map<String, dynamic> json) {
    return CaseAttachment(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      addedAt: DateTime.parse(
        json['added_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'added_at': addedAt.toIso8601String(),
  };
}

class CaseDeadline {
  final String id;
  final String title;
  final DateTime dueDate;
  final bool completed;

  CaseDeadline({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
  });

  CaseDeadline copyWith({String? title, DateTime? dueDate, bool? completed}) {
    return CaseDeadline(
      id: id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
    );
  }

  factory CaseDeadline.fromJson(Map<String, dynamic> json) {
    return CaseDeadline(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? '',
      dueDate: DateTime.parse(
        json['due_date'] ?? DateTime.now().toIso8601String(),
      ),
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'due_date': dueDate.toIso8601String(),
    'completed': completed,
  };
}

class CaseRecord {
  final String id;
  final String title;
  final String category; // e.g., Housing, Employment, Consumer, etc.
  final String description; // short summary or main issue
  final String notes; // freeform notes
  final List<CaseDeadline> deadlines;
  final List<CaseAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.notes = '',
    this.deadlines = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  CaseRecord copyWith({
    String? title,
    String? category,
    String? description,
    String? notes,
    List<CaseDeadline>? deadlines,
    List<CaseAttachment>? attachments,
    DateTime? updatedAt,
  }) {
    return CaseRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      deadlines: deadlines ?? this.deadlines,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory CaseRecord.fromJson(Map<String, dynamic> json) {
    return CaseRecord(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      notes: json['notes'] ?? '',
      deadlines:
          (json['deadlines'] as List? ?? [])
              .map((e) => CaseDeadline.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      attachments:
          (json['attachments'] as List? ?? [])
              .map((e) => CaseAttachment.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'notes': notes,
    'deadlines': deadlines.map((d) => d.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
