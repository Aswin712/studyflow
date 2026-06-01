import 'package:flutter/material.dart';

enum ThemePreset {
  indigo,
  ocean,
  emerald,
  rose,
  midnight,
}

extension ThemePresetExtension on ThemePreset {
  String get name {
    switch (this) {
      case ThemePreset.indigo:
        return 'Indigo';
      case ThemePreset.ocean:
        return 'Ocean Blue';
      case ThemePreset.emerald:
        return 'Emerald Green';
      case ThemePreset.rose:
        return 'Rose Pink';
      case ThemePreset.midnight:
        return 'Midnight Orange';
    }
  }

  Color get primaryLight {
    switch (this) {
      case ThemePreset.indigo:
        return const Color(0xFF4F46E5);
      case ThemePreset.ocean:
        return const Color(0xFF0284C7);
      case ThemePreset.emerald:
        return const Color(0xFF059669);
      case ThemePreset.rose:
        return const Color(0xFFE11D48);
      case ThemePreset.midnight:
        return const Color(0xFFEA580C);
    }
  }

  Color get primaryDark {
    switch (this) {
      case ThemePreset.indigo:
        return const Color(0xFF6366F1);
      case ThemePreset.ocean:
        return const Color(0xFF38BDF8);
      case ThemePreset.emerald:
        return const Color(0xFF34D399);
      case ThemePreset.rose:
        return const Color(0xFFFB7185);
      case ThemePreset.midnight:
        return const Color(0xFFFB923C);
    }
  }
}
