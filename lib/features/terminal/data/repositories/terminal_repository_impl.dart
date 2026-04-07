import 'package:flutter/material.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of TerminalRepository using SharedPreferences
class TerminalRepositoryImpl implements TerminalRepository {
  /// Storage key for terminal visibility
  static const String _visibilityKey = 'terminal_visible';

  @override
  Future<bool> loadVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_visibilityKey) ?? false; // Default to hidden
    } on Exception catch (e) {
      debugPrint('Error loading terminal visibility: $e');
      return false;
    }
  }

  @override
  Future<void> saveVisibility({required bool isVisible}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_visibilityKey, isVisible);
    } on Exception catch (e) {
      debugPrint('Error saving terminal visibility: $e');
    }
  }
}
