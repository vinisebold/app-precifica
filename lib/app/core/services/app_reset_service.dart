import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precifica/data/services/preferences_service.dart';
import 'package:precifica/domain/repositories/i_gestao_repository.dart';
import 'package:precifica/domain/repositories/i_settings_repository.dart';
import 'package:precifica/presentation/configuracoes/settings_controller.dart';
import 'package:precifica/presentation/gestao_produtos/gestao_controller.dart';

class AppResetService {
  AppResetService({
    required IGestaoRepository gestaoRepository,
    required ISettingsRepository settingsRepository,
    PreferencesService? preferencesService,
  })  : _gestaoRepository = gestaoRepository,
        _settingsRepository = settingsRepository,
        _preferencesService = preferencesService ?? PreferencesService();

  final IGestaoRepository _gestaoRepository;
  final ISettingsRepository _settingsRepository;
  final PreferencesService _preferencesService;

  Future<void> reset() async {
    await _gestaoRepository.resetStorage();
    await _settingsRepository.resetStorage();
    await _preferencesService.clearAll();
  }
}

final appResetServiceProvider = Provider<AppResetService>((ref) {
  final gestaoRepository = ref.read(gestaoRepositoryProvider);
  final settingsRepository = ref.read(settingsRepositoryProvider);

  return AppResetService(
    gestaoRepository: gestaoRepository,
    settingsRepository: settingsRepository,
  );
});
