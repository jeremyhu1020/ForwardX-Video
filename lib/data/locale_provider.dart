import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh'); // 默认中文

  Locale get locale => _locale;

  bool get isZh => _locale.languageCode == 'zh';

  void toggle() {
    _locale = isZh ? const Locale('en') : const Locale('zh');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
