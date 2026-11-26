import '../core/duonap_result.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_family_mirror.dart';
import 'duonap_session_mirror.dart';
import 'duonap_settings_repository.dart';
import 'duonap_shift_repository.dart';
import 'duonap_sleep_repository.dart';

// The repositories the services use once sync exists. Each one reads and
// writes the phone first, then hands the change to its mirror. Without a
// family the mirrors do nothing, so the app works as before.

class DuoNapSyncedSleepRepository implements DuoNapSleepRepository {
  DuoNapSyncedSleepRepository(this._local, this._mirror);

  final DuoNapHiveSleepRepository _local;
  final DuoNapSessionMirror _mirror;

  @override
  Future<DuoNapResult<List<DuoNapSleepSession>>> loadSince(DateTime from) {
    return _local.loadSince(from);
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSleepSession item) async {
    final result = await _local.save(item);
    if (result is DuoNapSuccess<void>) _mirror.push(item.id);
    return result;
  }

  @override
  Future<DuoNapResult<void>> delete(String id) async {
    final result = await _local.delete(id);
    if (result is DuoNapSuccess<void>) _mirror.pushDelete(id);
    return result;
  }
}

class DuoNapSyncedSettingsRepository implements DuoNapSettingsRepository {
  DuoNapSyncedSettingsRepository(this._local, this._mirror);

  final DuoNapHiveSettingsRepository _local;
  final DuoNapFamilyMirror _mirror;

  @override
  Future<DuoNapResult<DuoNapSettings>> load() => _local.load();

  @override
  Future<DuoNapResult<void>> save(DuoNapSettings settings) async {
    final result = await _local.save(settings);
    if (result is DuoNapSuccess<void>) _mirror.pushSettings(settings);
    return result;
  }
}

class DuoNapSyncedShiftRepository implements DuoNapShiftRepository {
  DuoNapSyncedShiftRepository(this._local, this._mirror);

  final DuoNapHiveShiftRepository _local;
  final DuoNapFamilyMirror _mirror;

  @override
  Future<DuoNapResult<DuoNapShiftSetup?>> load() => _local.load();

  @override
  Future<DuoNapResult<void>> save(DuoNapShiftSetup setup) async {
    final result = await _local.save(setup);
    if (result is DuoNapSuccess<void>) _mirror.pushShift(setup);
    return result;
  }

  @override
  Future<DuoNapResult<void>> clear() async {
    final result = await _local.clear();
    if (result is DuoNapSuccess<void>) _mirror.pushShift(null);
    return result;
  }
}
