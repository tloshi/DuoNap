import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/duonap_result.dart';
import '../domain/duonap_shift.dart';
import 'duonap_shift_dto.dart';

abstract interface class DuoNapShiftRepository {
  /// The running path, or null when none has been started.
  Future<DuoNapResult<DuoNapShiftSetup?>> load();

  Future<DuoNapResult<void>> save(DuoNapShiftSetup setup);

  /// Stops the path. The plan goes back to the times in settings.
  Future<DuoNapResult<void>> clear();
}

/// On-device storage, one JSON string under its own key in the settings box.
class DuoNapHiveShiftRepository implements DuoNapShiftRepository {
  DuoNapHiveShiftRepository(this._box);

  static const String _key = 'shift';

  final Box<String> _box;

  @override
  Future<DuoNapResult<DuoNapShiftSetup?>> load() async {
    try {
      final raw = _box.get(_key);
      if (raw == null) return const DuoNapSuccess<DuoNapShiftSetup?>(null);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DuoNapSuccess<DuoNapShiftSetup?>(DuoNapShiftDto.fromJson(json).toDomain());
    } on Object catch (error) {
      return DuoNapFailure<DuoNapShiftSetup?>('LOAD_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapShiftSetup setup) async {
    try {
      final dto = DuoNapShiftDto.fromDomain(setup);
      await _box.put(_key, jsonEncode(dto.toJson()));
      return const DuoNapSuccess<void>(null);
    } on Object catch (error) {
      return DuoNapFailure<void>('SAVE_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> clear() async {
    try {
      await _box.delete(_key);
      return const DuoNapSuccess<void>(null);
    } on Object catch (error) {
      return DuoNapFailure<void>('DELETE_FAILED', error.toString());
    }
  }
}
