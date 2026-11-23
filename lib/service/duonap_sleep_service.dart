import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../data/duonap_settings_repository.dart';
import '../data/duonap_sleep_repository.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_day_history.dart';
import 'duonap_today_builder.dart';

/// Business logic for logging sleep with one tap and building today's plan.
class DuoNapSleepService {
  DuoNapSleepService({
    required DuoNapSleepRepository repository,
    required DuoNapSettingsRepository settings,
    DuoNapClock? clock,
  })  : _repository = repository,
        _settings = settings,
        _clock = clock ?? DateTime.now;

  static const Duration _lookback = Duration(days: 14);
  static const Duration _nightLead = Duration(minutes: 60);

  final DuoNapSleepRepository _repository;
  final DuoNapSettingsRepository _settings;
  final DuoNapClock _clock;
  final DuoNapTodayBuilder _builder = const DuoNapTodayBuilder();
  final DuoNapDayHistory _history = const DuoNapDayHistory();

  Future<DuoNapResult<DuoNapTodaySnapshot>> loadToday() async {
    final now = _clock();
    final inputs = await _loadInputs(now);
    return inputs.fold<DuoNapResult<DuoNapTodaySnapshot>>(
      (failure) => DuoNapFailure<DuoNapTodaySnapshot>(failure.code, failure.message),
      (data) => DuoNapSuccess<DuoNapTodaySnapshot>(
        _builder.build(data.sessions, data.settings, now),
      ),
    );
  }

  /// Asleep becomes awake, awake becomes asleep.
  Future<DuoNapResult<void>> toggle(DuoNapBabyId babyId) async {
    final now = _clock();
    final inputs = await _loadInputs(now);
    if (inputs is! DuoNapSuccess<DuoNapLogInputs>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');
    }
    final own = inputs.data.sessions.where((s) => s.babyId == babyId).toList();
    final current = _history.ongoing(own);
    if (current != null) return _repository.save(current.ended(now));
    final session = _newSession(babyId, now, inputs.data.settings);
    return _repository.save(session);
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

  Future<DuoNapResult<DuoNapLogInputs>> _loadInputs(DateTime now) async {
    final settings = await _settings.load();
    if (settings is! DuoNapSuccess<DuoNapSettings>) {
      return const DuoNapFailure<DuoNapLogInputs>('LOAD_FAILED', 'Could not read settings.');
    }
    final loaded = await _repository.loadSince(now.subtract(_lookback));
    return loaded.fold<DuoNapResult<DuoNapLogInputs>>(
      (failure) => DuoNapFailure<DuoNapLogInputs>(failure.code, failure.message),
      (sessions) => DuoNapSuccess<DuoNapLogInputs>(
        DuoNapLogInputs(sessions: sessions, settings: settings.data),
      ),
    );
  }

  /// Sleep that starts close to bedtime, or before dawn, counts as night sleep.
  DuoNapSleepSession _newSession(
    DuoNapBabyId babyId,
    DateTime now,
    DuoNapSettings settings,
  ) {
    final day = DateTime(now.year, now.month, now.day);
    final bedtime = day.add(Duration(minutes: settings.plannedBedtimeMinutes));
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

/// The log and the settings, loaded together for one moment.
class DuoNapLogInputs {
  const DuoNapLogInputs({required this.sessions, required this.settings});

  final List<DuoNapSleepSession> sessions;
  final DuoNapSettings settings;
}
