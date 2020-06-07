import 'package:flutter/material.dart';

class I18n {
  I18n(this.locale);

  final Locale locale;

  static I18n of(BuildContext context) {
    return Localizations.of<I18n>(context, I18n);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Exchange Shops in Philippines',
      'license': 'License',
    },
    'ja': {
      'title': 'フィリピンの両替所',
      'license': 'ライセンス情報',
    },
  };

  String get title {
    return _localizedValues[locale.languageCode]['title'];
  }

  String get license {
    return _localizedValues[locale.languageCode]['license'];
  }
}
