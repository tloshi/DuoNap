import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../data/duonap_sleep_repository.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_logged_sleep.dart';
import '../domain/duonap_plan_item.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_day_history.dart';
import 'duonap_sleep_edit_rules.dart';

/// Corrects the log after the fact: change or delete a logged sleep, and log a
/// morning wake-up by hand when the night before it was not logged.
class DuoNapSleepEditService {
  DuoNapSleepEditService({
    required DuoNapSleepRepository repository,
    DuoNapClock? clock,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now;

  /// A wake-up's night can start the evening before, so look back a day more.
  static const Duration _lookback = Duration(days: 1);

  static const DuoNapFailure<void> _nothingSelected =
      DuoNapFailure<void>('NOTHING_SELECTED', 'No sleep was chosen.');

  static const DuoNapFailure<void> _loadFailed =
      DuoNapFailure<void>('LOAD_FAILED', 'Could not read sleep log.');

  final DuoNapSleepRepository _repository;
  final DuoNapClock _clock;
  final DuoNapDayHistory _history = const DuoNapDayHistory();

  /// Each baby's session behind [item]. A baby with nothing logged is missing.
  Future<DuoNapResult<DuoNapLoggedSleep>> find(DuoNapPlanItem item) async {
    final loaded = await _loadAround(item.start);
    return loaded.fold<DuoNapResult<DuoNapLoggedSleep>>(
      (failure) => DuoNapFailure<DuoNapLoggedSleep>(failure.code, failure.message),
      (sessions) => DuoNapSuccess<DuoNapLoggedSleep>(
        DuoNapLoggedSleep(item: item, sessions: _byBaby(sessions, item)),
      ),
    );
  }

  /// Gives every session in [sessions] the same new times.
  Future<DuoNapResult<void>> retime(
    List<DuoNapSleepSession> sessions,
    DuoNapSleepTimes times,
  ) async {
    final rules = DuoNapSleepEditRules(_clock());
    final problem =
        rules.timesProblem(sessions, times) ?? await _placeProblem(rules, sessions, times);
    if (problem != null) return problem;
    return _saveAll([
      for (final session in sessions) session.retimed(times.start, times.end),
    ]);
  }

  Future<DuoNapResult<void>> delete(List<DuoNapSleepSession> sessions) async {
    if (sessions.isEmpty) return _nothingSelected;
    for (final session in sessions) {
      final result = await _repository.delete(session.id);
      if (result is DuoNapFailure<void>) return result;
    }
    return const DuoNapSuccess<void>(null);
  }

  /// Sets the morning wake-up for each baby in [babies] to [at]. Moves an
  /// existing wake-up, ends a night still running, or adds a hand wake-up.
  /// Nothing is saved unless every baby's update is valid.
  Future<DuoNapResult<void>> logWake(Set<DuoNapBabyId> babies, DateTime at) async {
    if (babies.isEmpty) return _nothingSelected;
    final problem = DuoNapSleepEditRules(_clock()).wakeProblem(at);
    if (problem != null) return problem;
    final loaded = await _loadAround(at);
    if (loaded is! DuoNapSuccess<List<DuoNapSleepSession>>) return _loadFailed;
    final updates = <DuoNapSleepSession>[];
    for (final baby in babies) {
      final own = loaded.data.where((s) => s.babyId == baby).toList();
      final update = _wakeUpdate(own, baby, at);
      if (update == null) {
        return const DuoNapFailure<void>('END_BEFORE_START', 'Wake-up is before the night began.');
      }
      updates.add(update);
    }
    return _saveAll(updates);
  }

  /// Each session must stay in its day and kind hours and not overlap
  /// another sleep of the same baby.
  Future<DuoNapFailure<void>?> _placeProblem(
    DuoNapSleepEditRules rules,
    List<DuoNapSleepSession> sessions,
    DuoNapSleepTimes times,
  ) async {
    final loaded = await _loadAround(times.start);
    if (loaded is! DuoNapSuccess<List<DuoNapSleepSession>>) return _loadFailed;
    for (final session in sessions) {
      final others = loaded.data
          .where((s) => s.babyId == session.babyId && s.id != session.id)
          .toList();
      final problem =
          rules.placeProblem(session, times) ?? rules.overlapProblem(times, others);
      if (problem != null) return problem;
    }
    return null;
  }

  /// The session to save for one baby, or null when [at] is before its night.
  DuoNapSleepSession? _wakeUpdate(
    List<DuoNapSleepSession> own,
    DuoNapBabyId baby,
    DateTime at,
  ) {
    final source = _history.wakeSource(own, at) ?? _runningNight(own);
    if (source == null) return _newWake(baby, at);
    if (source.kind == DuoNapSleepKind.wake) return source.retimed(at, at);
    if (!at.isAfter(source.start)) return null;
    return source.retimed(source.start, at);
  }

  DuoNapSleepSession? _runningNight(List<DuoNapSleepSession> own) {
    final current = _history.ongoing(own);
    return current?.kind == DuoNapSleepKind.night ? current : null;
  }

  DuoNapSleepSession _newWake(DuoNapBabyId baby, DateTime at) {
    return DuoNapSleepSession(
      id: '${baby.name}-${_clock().microsecondsSinceEpoch}',
      babyId: baby,
      kind: DuoNapSleepKind.wake,
      start: at,
      end: at,
    );
  }

  Map<DuoNapBabyId, DuoNapSleepSession> _byBaby(
    List<DuoNapSleepSession> sessions,
    DuoNapPlanItem item,
  ) {
    final found = <DuoNapBabyId, DuoNapSleepSession>{};
    for (final baby in DuoNapBabyId.values) {
      final own = sessions.where((s) => s.babyId == baby).toList();
      final session = _history.loggedFor(own, item);
      if (session != null) found[baby] = session;
    }
    return found;
  }

  Future<DuoNapResult<List<DuoNapSleepSession>>> _loadAround(DateTime time) {
    final day = DateTime(time.year, time.month, time.day);
    return _repository.loadSince(day.subtract(_lookback));
  }

  Future<DuoNapResult<void>> _saveAll(List<DuoNapSleepSession> sessions) async {
    for (final session in sessions) {
      final result = await _repository.save(session);
      if (result is DuoNapFailure<void>) return result;
    }
    return const DuoNapSuccess<void>(null);
  }
}
