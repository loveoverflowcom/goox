import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seedColor = Color(0xFF264653);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    surface: const Color(0xFFF7F3EA),
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF3EFE4),
    textTheme: Typography.material2021().black.apply(
      bodyColor: const Color(0xFF18252C),
      displayColor: const Color(0xFF18252C),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFCF5),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    ),
    useMaterial3: true,
  );
}
