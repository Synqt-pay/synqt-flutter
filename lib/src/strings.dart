import 'dart:ui' show PlatformDispatcher;

import 'l10n/form_strings_en.dart';
import 'l10n/sheet_strings_en.dart';

/// Payer-facing text by language. To add one, copy both English files to `<language>` versions, translate them and
/// list them here, such as `'af': {...formStringsAf, ...sheetStringsAf}`. Keys are the Android SDK's string resource
/// names, so one translation serves every platform.
const _translations = <String, Map<String, String>>{
  'en': {...formStringsEn, ...sheetStringsEn},
};

/// Payer-facing text in the phone's language, falling back to English, then to the key itself. `%1$s` and `%1$d`
/// placeholders take [args] in order.
String text(String key, [List<Object> args = const []]) {
  final language = PlatformDispatcher.instance.locale.languageCode;
  final template = _translations[language]?[key] ?? _translations['en']![key] ?? key;
  return template.replaceAllMapped(RegExp(r'%(\d+)\$[sd]'), (match) => '${args[int.parse(match[1]!) - 1]}');
}

/// Whether [key] has English text, so tests can catch a typo before a payer sees a raw key.
bool hasText(String key) => _translations['en']!.containsKey(key);
