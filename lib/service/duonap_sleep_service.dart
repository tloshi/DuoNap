import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../data/duonap_settings_repository.dart';
import '../data/duonap_shift_repository.dart';
import '../data/duonap_sleep_repository.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_day_history.dart';
import 'duonap_today_builder.dart';

/// Business logic for logging sleep with one tap and building today's plan.
class DuoNapSleepService {
  DuoNapSleepService({
    required DuoNapSleepRepository repository,
    required DuoNapSettingsRepository settings,
    required DuoNapShiftRepository shift,
    DuoNapClock? clock,
  })  : _repository = repository,
        _settings = settings,
        _shift = shift,
        _clock = clock ?? DateTime.now;

  static const Duration _lookback = Duration(days: 14);
  static const Duration _nightLead = Duration(minutes: 60);
  static const DuoNapFailure<DuoNapTodayInputs> _loadFailed =
      DuoNapFailure<DuoNapTodayInputs>('LOAD_FAILED', 'Could not read settings.');

  final DuoNapSleepRepository _repository;
  final DuoNapSettingsRepository _settings;
  final DuoNapShiftRepository _shift;
  final DuoNapClock _clock;
  final DuoNapTodayBuilder _builder = const DuoNapTodayBuilder();
  final DuoNapDayHistory _history = const DuoNapDayHistory();

  Future<DuoNapResult<DuoNapTodaySnapshot>> loadToday() async {
    final now = _clock();
    final inputs = await _loadInputs(now);
    return inputs.fold<DuoNapResult<DuoNapTodaySnapshot>>(
      (failure) => DuoNapFailure<DuoNapTodaySnapshot>(failure.code, failure.message),
      (data) => DuoNapSuccess<DuoNapTodaySnapshot>(_builder.build(data, now)),
    );
  }

  /// Asleep becomes awake, awake becomes asleep.
  Future<DuoNapResult<void>> toggle(DuoNapBabyId babyId) async {
    final now = _clock();
    final inputs = await _loadInputs(now);
    if (inputs is! DuoNapSuccess<DuoNapTodayInputs>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');
    }
    final own = inputs.data.sessions.where((s) => s.babyId == babyId).toList();
    final current = _history.ongoing(own);
    if (current != null) return _repository.save(current.ended(now));
    return _repository.save(_newSession(babyId, now, inputs.data));
  }

  /// Puts both babies in the same state. A baby already in it is left alone.
  Future<DuoNapResult<void>> setBoth({required bool asleep}) async {
    final today = await loadToday();
    if (today is! DuoNapSuccess<DuoNapTodaySnapshot>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');
    }
    for (final baby in DuoNapBabyId.values) {
      if (today.data.statuses[baby]?.asleep == asleep) continue;
      final result = await toggle(baby);
      if (result is DuoNapFailure<void>) return result;
    }
    return const DuoNapSuccess<void>(null);
  }

  /// Settings, the path and the log. While a path runs the log is read from
  /// the day before it started, so every night since then counts for holds.
  Future<DuoNapResult<DuoNapTodayInputs>> _loadInputs(DateTime now) async {
    final settings = await _settings.load();
    final shift = await _shift.load();
    if (settings is! DuoNapSuccess<DuoNapSettings>) return _loadFailed;
    if (shift is! DuoNapSuccess<DuoNapShiftSetup?>) return _loadFailed;
    final loaded = await _repository.loadSince(_from(now, shift.data));
    return loaded.fold<DuoNapResult<DuoNapTodayInputs>>(
      (failure) => DuoNapFailure<DuoNapTodayInputs>(failure.code, failure.message),
      (sessions) => DuoNapSuccess<DuoNapTodayInputs>(
        DuoNapTodayInputs(sessions: sessions, settings: settings.data, shift: shift.data),
      ),
    );
  }

  DateTime _from(DateTime now, DuoNapShiftSetup? shift) {
    final recent = now.subtract(_lookback);
    if (shift == null) return recent;
    final dayBefore = shift.startDay.subtract(const Duration(days: 1));
    return dayBefore.isBefore(recent) ? dayBefore : recent;
  }

  /// Sleep that starts close to the day's bedtime, or before dawn, is night.
  DuoNapSleepSession _newSession(
    DuoNapBabyId babyId,
    DateTime now,
    DuoNapTodayInputs inputs,
  ) {
    final day = DateTime(now.year, now.month, now.day);
    final bedtimeMinutes = _builder.anchorsOn(inputs, now).bedtimeMinutes;
    final bedtime = day.add(Duration(minutes: bedtimeMinutes));
    final nearBedtime = !now.isBefore(bedtime.subtract(_nightLead));
    final isNight = nearBedtime || now.hour < DuoNapDayHistory.earliestWakeHour;
    return DuoNapSleepSession(
      id: '${babyId.name}-${now.microsecondsSinceEpoch}',
      babyId: babyId,
      kind: isNight ? DuoNapSleepKind.night : DuoNapSleepKind.nap,
      start: now,
    );
  }
}
