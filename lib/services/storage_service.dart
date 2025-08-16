import 'package:hive_flutter/hive_flutter.dart';
import '../models/analysis_result.dart';
import '../models/legal_models.dart';

class StorageService {
  static const String _analysisBoxName = 'legal_analysis';
  static const String _settingsBoxName = 'app_settings';

  static Box<LegalAnalysisResult>? _analysisBox;
  static Box? _settingsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LegalAnalysisResultAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LegalScenarioAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LegalAidContactAdapter());
    }

    // Open boxes
    _analysisBox = await Hive.openBox<LegalAnalysisResult>(_analysisBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Legal Analysis Storage
  static Future<void> saveAnalysis(LegalAnalysisResult analysis) async {
    await _analysisBox?.put(analysis.id, analysis);
  }

  static List<LegalAnalysisResult> getSavedAnalyses() {
    return _analysisBox?.values.toList().reversed.toList() ?? [];
  }

  static LegalAnalysisResult? getAnalysis(String id) {
    return _analysisBox?.get(id);
  }

  static Future<void> deleteAnalysis(String id) async {
    await _analysisBox?.delete(id);
  }

  static Future<void> clearAllAnalyses() async {
    await _analysisBox?.clear();
  }

  // Settings Storage
  static Future<void> setJurisdiction(String jurisdiction) async {
    await _settingsBox?.put('jurisdiction', jurisdiction);
  }

  static String getJurisdiction() {
    return _settingsBox?.get('jurisdiction', defaultValue: 'us') ?? 'us';
  }

  static Future<void> setUserLocation(String location) async {
    await _settingsBox?.put('user_location', location);
  }

  static String? getUserLocation() {
    return _settingsBox?.get('user_location');
  }

  static Future<void> setFirstTimeUser(bool isFirstTime) async {
    await _settingsBox?.put('first_time_user', isFirstTime);
  }

  static bool isFirstTimeUser() {
    return _settingsBox?.get('first_time_user', defaultValue: true) ?? true;
  }

  static Future<void> setApiKey(String apiKey) async {
    await _settingsBox?.put('openai_api_key', apiKey);
  }

  static String? getApiKey() {
    return _settingsBox?.get('openai_api_key');
  }

  static Future<void> close() async {
    await _analysisBox?.close();
    await _settingsBox?.close();
  }
}

// Hive Adapters - these would typically be generated with build_runner
// For now, providing manual implementations

class LegalAnalysisResultAdapter extends TypeAdapter<LegalAnalysisResult> {
  @override
  final int typeId = 0;

  @override
  LegalAnalysisResult read(BinaryReader reader) {
    return LegalAnalysisResult.fromJson(
      Map<String, dynamic>.from(reader.readMap()),
    );
  }

  @override
  void write(BinaryWriter writer, LegalAnalysisResult obj) {
    writer.writeMap(obj.toJson());
  }
}

class LegalScenarioAdapter extends TypeAdapter<LegalScenario> {
  @override
  final int typeId = 1;

  @override
  LegalScenario read(BinaryReader reader) {
    return LegalScenario.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, LegalScenario obj) {
    writer.writeMap(obj.toJson());
  }
}

class LegalAidContactAdapter extends TypeAdapter<LegalAidContact> {
  @override
  final int typeId = 2;

  @override
  LegalAidContact read(BinaryReader reader) {
    final map = reader.readMap();
    return LegalAidContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      areas: List<String>.from(map['areas'] ?? []),
    );
  }

  @override
  void write(BinaryWriter writer, LegalAidContact obj) {
    writer.writeMap({
      'name': obj.name,
      'phone': obj.phone,
      'website': obj.website,
      'description': obj.description,
      'areas': obj.areas,
    });
  }
}
