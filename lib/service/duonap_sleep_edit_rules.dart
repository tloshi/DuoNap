import '../core/duonap_result.dart';
import '../domain/duonap_logged_sleep.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_day_history.dart';

/// What a correction to the log must respect. Pure: the time comes in as [now].
class DuoNapSleepEditRules {
  const DuoNapSleepEditRules(this.now);

  final DateTime now;

  /// Something is chosen, nothing is in the future, and the end follows the start.
  DuoNapFailure<void>? timesProblem(
    List<DuoNapSleepSession> sessions,
    DuoNapSleepTimes times,
  ) {
    if (sessions.isEmpty) return _fail('NOTHING_SELECTED', 'No sleep was chosen.');
    final end = times.end;
    if (times.start.isAfter(now) || (end?.isAfter(now) ?? false)) {
      return _fail('IN_FUTURE', 'A time is in the future.');
    }
    if (end == null && sessions.any((s) => !s.isOngoing)) {
      return _fail('END_MISSING', 'A finished sleep needs an end.');
    }
    if (end != null && !end.isAfter(times.start)) {
      return _fail('END_BEFORE_START', 'End is not after start.');
    }
    return null;
  }

  /// A sleep keeps its date, and its start stays in the hours of its kind:
  /// a nap from 05:00 on, night sleep from 14:00 on or before 05:00. Otherwise
  /// the day rules in LOGIC.md would no longer find it where it was.
  DuoNapFailure<void>? placeProblem(
    DuoNapSleepSession session,
    DuoNapSleepTimes times,
  ) {
    final start = times.start;
    final sameDay = start.year == session.start.year &&
        start.month == session.start.month &&
        start.day == session.start.day;
    final fits = switch (session.kind) {
      DuoNapSleepKind.nap => start.hour >= DuoNapDayHistory.earliestWakeHour,
      DuoNapSleepKind.night => start.hour >= DuoNapDayHistory.latestWakeHour ||
          start.hour < DuoNapDayHistory.earliestWakeHour,
      DuoNapSleepKind.wake => false,
    };
    if (sameDay && fits) return null;
    return _fail('OUT_OF_PLACE', 'The new start does not fit this sleep.');
  }

  /// The new times must not overlap another sleep of the same baby.
  /// Hand wake-ups are moments, not sleep, so they never overlap.
  DuoNapFailure<void>? overlapProblem(
    DuoNapSleepTimes times,
    List<DuoNapSleepSession> others,
  ) {
    final end = times.end ?? now;
    for (final other in others) {
      if (other.kind == DuoNapSleepKind.wake) continue;
      final otherEnd = other.end ?? now;
      if (other.start.isBefore(end) && times.start.isBefore(otherEnd)) {
        return _fail('OVERLAP', 'The sleep overlaps another sleep.');
      }
    }
    return null;
  }

  /// A hand wake-up is in the past and inside the morning window.
  DuoNapFailure<void>? wakeProblem(DateTime at) {
    if (at.isAfter(now)) return _fail('IN_FUTURE', 'A time is in the future.');
    final inWindow = at.hour >= DuoNapDayHistory.earliestWakeHour &&
        at.hour < DuoNapDayHistory.latestWakeHour;
    if (inWindow) return null;
    return _fail('WAKE_OUT_OF_RANGE', 'Wake-up is not in the morning.');
  }

  DuoNapFailure<void> _fail(String code, String message) {
    return DuoNapFailure<void>(code, message);
  }
}
