import '../core/duonap_result.dart';
import '../data/duonap_sleep_repository.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_plan_item.dart';
import '../domain/duonap_sleep_profile.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_day_history.dart';
import 'duonap_plan_engine.dart';
import 'duonap_profile_learner.dart';
import 'duonap_twin_plan_merger.dart';

typedef DuoNapClock = DateTime Function();

/// Business logic for logging sleep and building today's plan.
class DuoNapSleepService {
  DuoNapSleepService({
    required DuoNapSleepRepository repository,
    DuoNapClock? clock,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now;

  static const Duration _lookback = Duration(days: 14);
  static const Duration _nightLead = Duration(minutes: 60);
  static const int _nightEndsHour = 5;

  final DuoNapSleepRepository _repository;
  final DuoNapClock _clock;
  final DuoNapPlanEngine _engine = const DuoNapPlanEngine();
  final DuoNapTwinPlanMerger _merger = const DuoNapTwinPlanMerger();
  final DuoNapProfileLearner _learner = const DuoNapProfileLearner();
  final DuoNapDayHistory _history = const DuoNapDayHistory();

  Future<DuoNapResult<DuoNapTodaySnapshot>> loadToday() async {
    final now = _clock();
    final loaded = await _repository.loadSince(now.subtract(_lookback));
    return loaded.fold<DuoNapResult<DuoNapTodaySnapshot>>(
      (failure) => DuoNapFailure<DuoNapTodaySnapshot>(
        failure.code,
        failure.message,
      ),
      (sessions) => DuoNapSuccess<DuoNapTodaySnapshot>(_snapshot(sessions, now)),
    );
  }

  /// Asleep becomes awake, awake becomes asleep.
  Future<DuoNapResult<void>> toggle(DuoNapBabyId babyId) async {
    final now = _clock();
    final loaded = await _repository.loadSince(now.subtract(_lookback));
    if (loaded is! DuoNapSuccess<List<DuoNapSleepSession>>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');
    }
    final own = loaded.data.where((s) => s.babyId == babyId).toList();
    final current = _history.ongoing(own);
    if (current != null) return _repository.save(current.ended(now));
    return _repository.save(_newSession(babyId, now));
  }

  /// Puts both babies in the same state. A baby already in it is left alone.
  Future<DuoNapResult<void>> setBoth({required bool asleep}) async {
    final today = await loadToday();
    if (today is! DuoNapSuccess<DuoNapTodaySnapshot>) {
      return const DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');
    }
    for (final baby in DuoNapFamily.babies) {
      if (today.data.statuses[baby.id]?.asleep == asleep) continue;
      final result = await toggle(baby.id);
      if (result is DuoNapFailure<void>) return result;
    }
    return const DuoNapSuccess<void>(null);
  }

  DuoNapTodaySnapshot _snapshot(List<DuoNapSleepSession> sessions, DateTime now) {
    final statuses = <DuoNapBabyId, DuoNapBabyStatus>{};
    final babyPlans = <DuoNapBabyId, List<DuoNapPlanItem>>{};
    for (final baby in DuoNapFamily.babies) {
      final own = sessions.where((s) => s.babyId == baby.id).toList();
      statuses[baby.id] = _history.statusOf(own);
      babyPlans[baby.id] = _planFor(own, now);
    }
    final plan = _merger.merge(
      babyPlans[DuoNapBabyId.first] ?? const [],
      babyPlans[DuoNapBabyId.second] ?? const [],
    );
    return DuoNapTodaySnapshot(
      now: now,
      statuses: statuses,
      plan: plan,
      babyPlans: babyPlans,
    );
  }

  List<DuoNapPlanItem> _planFor(List<DuoNapSleepSession> own, DateTime now) {
    final profile = _learner.learn(
      DuoNapSleepProfile.starter,
      _history.pastDays(own, now),
    );
    final input = DuoNapPlanInput(
      now: now,
      profile: profile,
      naps: _history.napsOn(own, now),
      wakeTime: _history.wakeOn(own, now),
      nightStart: _history.nightStartOn(own, now),
    );
    return _engine.build(input);
  }

  /// Sleep that starts close to bedtime, or before dawn, counts as night sleep.
  DuoNapSleepSession _newSession(DuoNapBabyId babyId, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    final bedtime = day.add(
      Duration(minutes: DuoNapSleepProfile.starter.plannedBedtimeMinutes),
    );
    final nearBedtime = !now.isBefore(bedtime.subtract(_nightLead));
    final isNight = nearBedtime || now.hour < _nightEndsHour;
    return DuoNapSleepSession(
      id: '${babyId.name}-${now.microsecondsSinceEpoch}',
      babyId: babyId,
      kind: isNight ? DuoNapSleepKind.night : DuoNapSleepKind.nap,
      start: now,
    );
  }
}
