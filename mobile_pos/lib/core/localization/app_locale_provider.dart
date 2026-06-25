import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/core_providers.dart';
import 'app_locale.dart';

const _localePreferenceKey = 'app_locale';

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, AppLocale>((ref) {
      final prefs = ref.watch(sharedPreferencesInstanceProvider);
      final savedCode = prefs.getString(_localePreferenceKey);
      final initialLocale = AppLocale.fromLanguageCode(savedCode ?? '');
      return AppLocaleNotifier(prefs, initialLocale);
    });

class AppLocaleNotifier extends StateNotifier<AppLocale> {
  AppLocaleNotifier(this._prefs, AppLocale initialLocale) : super(initialLocale);

  final SharedPreferences _prefs;

  Locale get flutterLocale => state.locale;

  Future<void> setLocale(AppLocale locale) async {
    if (state == locale) {
      return;
    }

    state = locale;
    await _prefs.setString(_localePreferenceKey, locale.languageCode);
  }
}
