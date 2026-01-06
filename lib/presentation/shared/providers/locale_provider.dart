import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../configuracoes/settings_controller.dart';
import '../../../app/core/l10n/app_localizations.dart';

export '../../../app/core/l10n/app_localizations.dart' show AppLanguage;

/// Notifier for managing app locale
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final languageCode = settingsController.getLanguage();
    final language = AppLanguage.fromLanguageCode(languageCode);
    return language.locale;
  }

  Future<void> setLocale(AppLanguage language) async {
    state = language.locale;
    final settingsController = ref.read(settingsControllerProvider.notifier);
    await settingsController.setLanguage(language.languageCode);
  }

  AppLanguage get currentLanguage => AppLanguage.fromLocale(state);
}

/// Provider for the current locale
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
