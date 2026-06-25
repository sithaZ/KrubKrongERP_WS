import 'package:flutter/material.dart';

enum AppLocale {
  english(
    locale: Locale('en'),
    languageCode: 'en',
    englishLabel: 'English',
    nativeLabel: 'English',
  ),
  khmer(
    locale: Locale('km'),
    languageCode: 'km',
    englishLabel: 'Khmer',
    nativeLabel: 'ខ្មែរ',
  );

  const AppLocale({
    required this.locale,
    required this.languageCode,
    required this.englishLabel,
    required this.nativeLabel,
  });

  final Locale locale;
  final String languageCode;
  final String englishLabel;
  final String nativeLabel;

  static AppLocale fromLanguageCode(String code) {
    return AppLocale.values.firstWhere(
      (value) => value.languageCode == code,
      orElse: () => AppLocale.english,
    );
  }
}
