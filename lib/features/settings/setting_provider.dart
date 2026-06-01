import 'package:flutter/material.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/theme_presets.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;
  ThemePreset _themePreset = ThemePreset.indigo;
  String _userName = '';

  SettingsProvider(this._storage) {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  ThemePreset get themePreset => _themePreset;
  String get userName => _userName;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  void _load() {
    final saved = _storage.loadThemeMode();
    final useSystem = _storage.loadUseSystemTheme();
    if (useSystem) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = saved ? ThemeMode.dark : ThemeMode.light;
    }
    _userName = _storage.loadUserName();
    final presetIndex = _storage.loadThemePreset();
    if (presetIndex >= 0 && presetIndex < ThemePreset.values.length) {
      _themePreset = ThemePreset.values[presetIndex];
    } else {
      _themePreset = ThemePreset.indigo;
    }
    notifyListeners();
  }

  /// Re-read settings dari storage (untuk restore/import)
  void reload() => _load();

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode == ThemeMode.dark);
    await _storage.saveUseSystemTheme(mode == ThemeMode.system);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    await _storage.saveUserName(_userName);
    notifyListeners();
  }

  Future<void> setThemePreset(ThemePreset preset) async {
    _themePreset = preset;
    await _storage.saveThemePreset(preset.index);
    notifyListeners();
  }
}
