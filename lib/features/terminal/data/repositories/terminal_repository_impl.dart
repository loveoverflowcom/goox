import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of TerminalRepository using SharedPreferences
class TerminalRepositoryImpl implements TerminalRepository {
  /// Storage key for terminal visibility
  static const String _visibilityKey = 'terminal_visible';
  static const String _heightKey = 'terminal_height';
  static const String _countKey = 'terminal_count';
  static const String _workingDirsKey = 'terminal_working_dirs';

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

  @override
  Future<double> loadHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_heightKey) ?? 300.0;
    } on Exception catch (e) {
      debugPrint('Error loading terminal height: $e');
      return 300.0;
    }
  }

  @override
  Future<void> saveHeight({required double height}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_heightKey, height);
    } on Exception catch (e) {
      debugPrint('Error saving terminal height: $e');
    }
  }

  @override
  Future<int> loadTerminalCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_countKey) ?? 1;
    } on Exception catch (e) {
      debugPrint('Error loading terminal count: $e');
      return 1;
    }
  }

  @override
  Future<void> saveTerminalCount({required int count}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_countKey, count);
    } on Exception catch (e) {
      debugPrint('Error saving terminal count: $e');
    }
  }

  @override
  Future<List<String>> loadWorkingDirectories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_workingDirsKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List;
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } on Exception catch (e) {
      debugPrint('Error loading working directories: $e');
      return [];
    }
  }

  @override
  Future<void> saveWorkingDirectories({required List<String> paths}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(paths);
      await prefs.setString(_workingDirsKey, jsonString);
    } on Exception catch (e) {
      debugPrint('Error saving working directories: $e');
    }
  }
}
