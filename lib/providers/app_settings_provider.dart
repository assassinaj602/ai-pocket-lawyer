import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  String _jurisdiction = 'us';
  String? _userLocation;
  bool _isFirstTimeUser = true;
  bool _isLocationEnabled = false;
  ThemeMode _themeMode = ThemeMode.system;

  // Available jurisdictions
  final List<Map<String, String>> _availableJurisdictions = [
    {'code': 'us', 'name': 'United States'},
    {'code': 'uk', 'name': 'United Kingdom'},
  ];

  // Getters
  String get jurisdiction => _jurisdiction;
  String? get userLocation => _userLocation;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get isLocationEnabled => _isLocationEnabled;
  ThemeMode get themeMode => _themeMode;
  List<Map<String, String>> get availableJurisdictions =>
      _availableJurisdictions;

  // Get jurisdiction display text
  String get jurisdictionDisplayText {
    final jurisdiction = _availableJurisdictions.firstWhere(
      (j) => j['code'] == _jurisdiction,
      orElse: () => {'code': 'us', 'name': 'United States'},
    );
    return jurisdiction['name'] ?? 'United States';
  }

  // Initialize settings
  Future<void> initialize() async {
    await _loadSettings();
    await _checkLocationPermission();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      _jurisdiction = StorageService.getJurisdiction();
      _userLocation = StorageService.getUserLocation();
      _isFirstTimeUser = StorageService.isFirstTimeUser();

      // Load theme mode from storage
      String? savedTheme = StorageService.getThemeMode();
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }

      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Set jurisdiction
  Future<void> setJurisdiction(String jurisdiction) async {
    _jurisdiction = jurisdiction;
    await StorageService.setJurisdiction(jurisdiction);
    notifyListeners();
  }

  // Set user location
  Future<void> setUserLocation(String? location) async {
    _userLocation = location;
    if (location != null) {
      await StorageService.setUserLocation(location);
    }
    notifyListeners();
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await StorageService.setThemeMode(themeString);
    notifyListeners();
  }

  // Mark as not first time user
  Future<void> setNotFirstTimeUser() async {
    _isFirstTimeUser = false;
    await StorageService.setFirstTimeUser(false);
    notifyListeners();
  }

  // Check location permission
  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      _isLocationEnabled =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      notifyListeners();
    } catch (e) {
      print('Error checking location permission: $e');
      _isLocationEnabled = false;
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      _isLocationEnabled =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      notifyListeners();
      return _isLocationEnabled;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Get current location
  Future<String?> getCurrentLocation() async {
    if (!_isLocationEnabled) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = '';

        if (place.locality?.isNotEmpty == true) {
          location += place.locality!;
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          if (location.isNotEmpty) location += ', ';
          location += place.administrativeArea!;
        }
        if (place.country?.isNotEmpty == true) {
          if (location.isNotEmpty) location += ', ';
          location += place.country!;
        }

        await setUserLocation(location);
        return location;
      }
    } catch (e) {
      print('Error getting current location: $e');
    }

    return null;
  }

  // Update location automatically if enabled
  Future<void> updateLocationIfEnabled() async {
    if (_isLocationEnabled) {
      await getCurrentLocation();
    }
  }
}
