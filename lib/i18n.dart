import 'package:flutter/material.dart';

class I18n {
  I18n(this.locale);

  final Locale locale;

  static I18n of(BuildContext context) {
    return Localizations.of<I18n>(context, I18n);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Exchange Shop in Cebu',
    },
    'ja': {
      'title': 'セブの両替所',
    },
  };

  String get title {
    return _localizedValues[locale.languageCode]['title'];
  }
}
