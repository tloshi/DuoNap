import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/data/duonap_settings_repository.dart';
import 'package:duonap/data/duonap_shift_repository.dart';
import 'package:duonap/data/duonap_sleep_repository.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:duonap/domain/duonap_shift.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';

/// In-memory sleep log, keyed by session id like the Hive box.
class DuoNapFakeSleepRepository implements DuoNapSleepRepository {
  DuoNapFakeSleepRepository([List<DuoNapSleepSession> seed = const []]) {
    for (final session in seed) {
      sessions[session.id] = session;
    }
  }

  final Map<String, DuoNapSleepSession> sessions = {};

  @override
  Future<DuoNapResult<List<DuoNapSleepSession>>> loadSince(DateTime from) async {
    final list = sessions.values.where((s) => !s.start.isBefore(from)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return DuoNapSuccess<List<DuoNapSleepSession>>(list);
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSleepSession item) async {
    sessions[item.id] = item;
    return const DuoNapSuccess<void>(null);
  }

  @override
  Future<DuoNapResult<void>> delete(String id) async {
    sessions.remove(id);
    return const DuoNapSuccess<void>(null);
  }
}

class DuoNapFakeShiftRepository implements DuoNapShiftRepository {
  DuoNapFakeShiftRepository([this.stored]);

  DuoNapShiftSetup? stored;

  @override
  Future<DuoNapResult<DuoNapShiftSetup?>> load() async {
    return DuoNapSuccess<DuoNapShiftSetup?>(stored);
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapShiftSetup setup) async {
    stored = setup;
    return const DuoNapSuccess<void>(null);
  }

  @override
  Future<DuoNapResult<void>> clear() async {
    stored = null;
    return const DuoNapSuccess<void>(null);
  }
}

class DuoNapFakeSettingsRepository implements DuoNapSettingsRepository {
  DuoNapFakeSettingsRepository([this.stored]);

  DuoNapSettings? stored;

  @override
  Future<DuoNapResult<DuoNapSettings>> load() async {
    return DuoNapSuccess<DuoNapSettings>(stored ?? DuoNapSettings.defaults);
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSettings settings) async {
    stored = settings;
    return const DuoNapSuccess<void>(null);
  }
}
