import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/analysis_result.dart';
import '../services/ai_legal_service.dart';
import '../services/storage_service.dart';

class LegalAnalysisProvider extends ChangeNotifier {
  final AILegalService _aiService = AILegalService();

  LegalAnalysisResult? _currentAnalysis;
  List<LegalAnalysisResult> _savedAnalyses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  LegalAnalysisResult? get currentAnalysis => _currentAnalysis;
  List<LegalAnalysisResult> get savedAnalyses => _savedAnalyses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await loadSavedAnalyses();
  }

  // Analyze legal problem
  Future<void> analyzeProblem({
    required String query,
    required String jurisdiction,
    String? userLocation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _aiService.analyzeLegalQuestion(
        question: query,
        jurisdiction: jurisdiction,
      );

      _currentAnalysis = result;

      // Auto-save the analysis
      await StorageService.saveAnalysis(result);
      await loadSavedAnalyses();
    } catch (e) {
      _setError('Failed to analyze legal problem: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load saved analyses
  Future<void> loadSavedAnalyses() async {
    try {
      _savedAnalyses = StorageService.getSavedAnalyses();
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load saved analyses: ${e.toString()}');
    }
  }

  // Delete analysis
  Future<void> deleteAnalysis(String id) async {
    try {
      await StorageService.deleteAnalysis(id);
      await loadSavedAnalyses();

      // Clear current analysis if it was deleted
      if (_currentAnalysis?.id == id) {
        _currentAnalysis = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete analysis: ${e.toString()}');
    }
  }

  // Clear all analyses
  Future<void> clearAllAnalyses() async {
    try {
      await StorageService.clearAllAnalyses();
      _savedAnalyses.clear();
      _currentAnalysis = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear analyses: ${e.toString()}');
    }
  }

  // Set current analysis (for viewing saved analysis)
  void setCurrentAnalysis(LegalAnalysisResult? analysis) {
    _currentAnalysis = analysis;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear current analysis
  void clearCurrentAnalysis() {
    _currentAnalysis = null;
    notifyListeners();
  }
}
