import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranProvider with ChangeNotifier {
  double _fontSize = 28.0;
  double _latinFontSize = 13.0;
  double _translationFontSize = 14.0;

  double get fontSize => _fontSize;
  double get latinFontSize => _latinFontSize;
  double get translationFontSize => _translationFontSize;

  QuranProvider() {
    _loadSettings();
  }

  void setFontSize(double size) {
    _fontSize = size;
    _saveSettings();
    notifyListeners();
  }

  void setLatinFontSize(double size) {
    _latinFontSize = size;
    _saveSettings();
    notifyListeners();
  }

  void setTranslationFontSize(double size) {
    _translationFontSize = size;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble('quran_font_size') ?? 28.0;
      _latinFontSize = prefs.getDouble('quran_latin_font_size') ?? 13.0;
      _translationFontSize = prefs.getDouble('quran_translation_font_size') ?? 14.0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading quran settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('quran_font_size', _fontSize);
      await prefs.setDouble('quran_latin_font_size', _latinFontSize);
      await prefs.setDouble('quran_translation_font_size', _translationFontSize);
    } catch (e) {
      debugPrint("Error saving quran settings: $e");
    }
  }
}
