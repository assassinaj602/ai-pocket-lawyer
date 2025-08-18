import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/case_models.dart';
import '../services/storage_service.dart';

class CaseProvider extends ChangeNotifier {
  final List<CaseRecord> _cases = [];
  bool _loading = false;
  String? _error;

  List<CaseRecord> get cases => List.unmodifiable(_cases);
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    await loadCases();
  }

  Future<void> loadCases() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = CaseStorage.getAllCaseRecords();
      _cases
        ..clear()
        ..addAll(list.map((e) => CaseRecord.fromJson(e)));
    } catch (e) {
      _error = 'Failed to load cases: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addOrUpdateCase(CaseRecord record) async {
    try {
      await CaseStorage.saveCaseRecord(record.toJson());
      final idx = _cases.indexWhere((c) => c.id == record.id);
      if (idx >= 0) {
        _cases[idx] = record.copyWith(updatedAt: DateTime.now());
      } else {
        _cases.insert(0, record);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save case: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCase(String id) async {
    try {
      await CaseStorage.deleteCaseRecord(id);
      _cases.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete case: $e';
      notifyListeners();
    }
  }

  CaseRecord newBlankCase() {
    final id = const Uuid().v4();
    return CaseRecord(
      id: id,
      title: 'Untitled Case',
      category: 'General',
      description: '',
      notes: '',
      deadlines: const [],
      attachments: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
