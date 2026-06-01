import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Satu-satunya class yang boleh menyentuh shared_preferences.
/// Repository memanggil class ini — bukan SharedPreferences langsung.
class LocalStorageService {
  static LocalStorageService? _instance;
  late SharedPreferences _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }


  // Theme
  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(AppConstants.keyThemeMode, isDark);
  }

  bool loadThemeMode() {
    return _prefs.getBool(AppConstants.keyThemeMode) ?? false;
  }

  // User name
  Future<void> saveUserName(String name) async {
    await _prefs.setString(AppConstants.keyUserName, name);
  }

  String loadUserName() {
    return _prefs.getString(AppConstants.keyUserName) ?? '';
  }

  // Use system theme flag
  Future<void> saveUseSystemTheme(bool useSystem) async {
    await _prefs.setBool(AppConstants.keyUseSystemTheme, useSystem);
  }

  bool loadUseSystemTheme() {
    return _prefs.getBool(AppConstants.keyUseSystemTheme) ?? true;
  }

  // First launch flag
  Future<void> saveIsFirstLaunch(bool isFirst) async {
    await _prefs.setBool(AppConstants.keyFirstLaunch, isFirst);
  }

  bool loadIsFirstLaunch() {
    // Default true jika belum pernah diset
    return _prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
  }

  // Theme preset
  Future<void> saveThemePreset(int index) async {
    await _prefs.setInt(AppConstants.keyThemePreset, index);
  }

  int loadThemePreset() {
    return _prefs.getInt(AppConstants.keyThemePreset) ?? 0;
  }

  // Clear semua data (untuk reset / testing)
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Backup & Restore — export settings
  Map<String, dynamic> exportSettings() {
    return {
      'userName': _prefs.getString(AppConstants.keyUserName) ?? '',
      'themeMode': _prefs.getBool(AppConstants.keyThemeMode) ?? false,
      'useSystemTheme': _prefs.getBool(AppConstants.keyUseSystemTheme) ?? true,
      'themePreset': _prefs.getInt(AppConstants.keyThemePreset) ?? 0,
      'isFirstLaunch': _prefs.getBool(AppConstants.keyFirstLaunch) ?? true,
    };
  }

  /// Import settings dari backup
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['userName'] != null) {
      await _prefs.setString(AppConstants.keyUserName, settings['userName'] as String);
    }
    if (settings['themeMode'] != null) {
      await _prefs.setBool(AppConstants.keyThemeMode, settings['themeMode'] as bool);
    }
    if (settings['useSystemTheme'] != null) {
      await _prefs.setBool(AppConstants.keyUseSystemTheme, settings['useSystemTheme'] as bool);
    }
    if (settings['themePreset'] != null) {
      await _prefs.setInt(AppConstants.keyThemePreset, settings['themePreset'] as int);
    }
    if (settings['isFirstLaunch'] != null) {
      await _prefs.setBool(AppConstants.keyFirstLaunch, settings['isFirstLaunch'] as bool);
    }
  }
}
