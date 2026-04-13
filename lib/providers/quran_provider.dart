import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranProvider with ChangeNotifier {
  double _fontSize = 28.0;

  double get fontSize => _fontSize;

  QuranProvider() {
    _loadSettings();
  }

  void setFontSize(double size) {
    _fontSize = size;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble('quran_font_size') ?? 28.0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading quran settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('quran_font_size', _fontSize);
    } catch (e) {
      debugPrint("Error saving quran settings: $e");
    }
  }
}

