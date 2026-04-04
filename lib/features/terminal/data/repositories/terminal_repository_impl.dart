import 'package:flutter/material.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of TerminalRepository using SharedPreferences
class TerminalRepositoryImpl implements TerminalRepository {
  /// Storage key for terminal visibility
  static const String _visibilityKey = 'terminal_visible';

  /// Storage key for terminal height
  static const String _heightKey = 'terminal_height';

  @override
  Future<bool> loadVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_visibilityKey) ?? false; // Default to hidden
    } catch (e) {
      debugPrint('Error loading terminal visibility: $e');
      return false;
    }
  }

  @override
  Future<void> saveVisibility(bool isVisible) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_visibilityKey, isVisible);
    } catch (e) {
      debugPrint('Error saving terminal visibility: $e');
    }
  }

  @override
  Future<double> loadHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_heightKey) ?? TerminalConfig.defaultHeight;
    } catch (e) {
      debugPrint('Error loading terminal height: $e');
      return TerminalConfig.defaultHeight;
    }
  }

  @override
  Future<void> saveHeight(double height) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_heightKey, height);
    } catch (e) {
      debugPrint('Error saving terminal height: $e');
    }
  }
}
