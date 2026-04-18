import 'package:flutter/material.dart';
import 'package:gabeseye/l10n/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  static const List<String> langNames = ['Français', 'العربية', 'English'];

  static const Map<String, String> _nameToCode = {
    'Français': 'fr',
    'العربية': 'ar',
    'English': 'en',
  };

  String get currentName => _nameToCode.entries
      .firstWhere(
        (e) => e.value == _locale.languageCode,
        orElse: () => const MapEntry('Français', 'fr'),
      )
      .key;

  void setByName(String name) {
    final code = _nameToCode[name] ?? 'fr';
    if (_locale.languageCode != code) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  String t(String key) => AppStrings.t(_locale.languageCode, key);
}
