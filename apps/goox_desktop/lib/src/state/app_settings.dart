import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double fontSize;
  final FontWeight fontWeight;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'fontSize': fontSize,
      'fontWeight': fontWeight.value, // 100-900 in steps of 100
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: _parseThemeMode(json['themeMode']),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontWeight: _parseFontWeight(json['fontWeight']),
    );
  }

  static ThemeMode _parseThemeMode(dynamic value) {
    if (value is String) {
      return ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }
    return ThemeMode.system;
  }

  static FontWeight _parseFontWeight(dynamic value) {
    if (value is int && value >= 0 && value < FontWeight.values.length) {
      return FontWeight.values[value];
    }
    return FontWeight.normal;
  }
}
