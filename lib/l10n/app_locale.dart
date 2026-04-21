import 'package:flutter/material.dart';

enum AppLocale {
  en(languageCode: 'en', intlTag: 'en_GB'),
  tr(languageCode: 'tr', intlTag: 'tr_TR');

  const AppLocale({required this.languageCode, required this.intlTag});

  final String languageCode;
  final String intlTag;

  Locale get locale => Locale(languageCode);

  static AppLocale fromLanguageCode(String? value) {
    return switch (value) {
      'tr' => AppLocale.tr,
      'en' => AppLocale.en,
      _ => AppLocale.en,
    };
  }
}
