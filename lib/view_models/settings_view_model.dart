import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _appLocale = const Locale('kk');

  ThemeMode get themeMode => _themeMode;
  Locale get appLocale => _appLocale;
  
  SettingsViewModel() {
    _loadSettings();
  }

  // Загружаем сохраненные настройки
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем язык
    final languageCode = prefs.getString('languageCode') ?? 'kk'; // по умолчанию 'kk'
    _appLocale = Locale(languageCode);

    // Загружаем тему
    // Сохраняем как число (0=system, 1=light, 2=dark)
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index); // Сохраняем индекс темы
    _themeMode = themeMode;
    notifyListeners();
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode); // Сохраняем код языка
    _appLocale = locale;
    notifyListeners();
  }
}