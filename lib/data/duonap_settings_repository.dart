import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/duonap_result.dart';
import '../domain/duonap_settings.dart';
import 'duonap_settings_dto.dart';

abstract interface class DuoNapSettingsRepository {
  /// The saved settings, or [DuoNapSettings.defaults] when nothing is saved yet.
  Future<DuoNapResult<DuoNapSettings>> load();

  Future<DuoNapResult<void>> save(DuoNapSettings settings);
}

/// On-device storage. One JSON string under a single key.
class DuoNapHiveSettingsRepository implements DuoNapSettingsRepository {
  DuoNapHiveSettingsRepository(this._box);

  static const String boxName = 'duonap_settings';
  static const String _key = 'settings';

  final Box<String> _box;

  @override
  Future<DuoNapResult<DuoNapSettings>> load() async {
    try {
      final raw = _box.get(_key);
      if (raw == null) {
        return const DuoNapSuccess<DuoNapSettings>(DuoNapSettings.defaults);
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final settings = DuoNapSettingsDto.fromJson(json).toDomain();
      return DuoNapSuccess<DuoNapSettings>(settings);
    } on Object catch (error) {
      return DuoNapFailure<DuoNapSettings>('LOAD_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSettings settings) async {
    try {
      final dto = DuoNapSettingsDto.fromDomain(settings);
      await _box.put(_key, jsonEncode(dto.toJson()));
      return const DuoNapSuccess<void>(null);
    } on Object catch (error) {
      return DuoNapFailure<void>('SAVE_FAILED', error.toString());
    }
  }
}
