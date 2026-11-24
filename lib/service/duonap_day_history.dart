import '../domain/duonap_plan_item.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_profile_learner.dart';

/// Reads one baby's logged sessions: who is asleep, when the day started,
/// which naps belong to a day. All lists passed in are for a single baby.
class DuoNapDayHistory {
  const DuoNapDayHistory();

  /// A morning wake-up happens from this hour on. Sleep starting earlier is night.
  static const int earliestWakeHour = 5;

  /// A morning wake-up happens before this hour. Night sleep starts after it.
  static const int latestWakeHour = 14;
  static const int _learningDays = 10;

  DuoNapSleepSession? ongoing(List<DuoNapSleepSession> sessions) {
    for (final session in sessions.reversed) {
      if (session.isOngoing) return session;
    }
    return null;
  }

  DuoNapBabyStatus statusOf(List<DuoNapSleepSession> sessions) {
    final current = ongoing(sessions);
    if (current != null) {
      return DuoNapBabyStatus(asleep: true, since: current.start);
    }
    DateTime? lastEnd;
    for (final session in sessions) {
      final end = session.end;
      if (end == null) continue;
      if (lastEnd == null || end.isAfter(lastEnd)) lastEnd = end;
    }
    return DuoNapBabyStatus(asleep: false, since: lastEnd);
  }

  /// The morning wake-up on [day]: the latest end of a night sleep, or of a
  /// wake-up logged by hand, that morning. Null while the baby is still in
  /// last night's sleep.
  DateTime? wakeOn(List<DuoNapSleepSession> sessions, DateTime day) {
    final latest = DateTime(day.year, day.month, day.day, latestWakeHour);
    DateTime? wake;
    for (final session in sessions) {
      if (session.kind == DuoNapSleepKind.nap) continue;
      final end = session.end;
      if (end == null && session.start.isBefore(latest)) return null;
      if (end == null || !_isMorningOf(end, day)) continue;
      if (wake == null || end.isAfter(wake)) wake = end;
    }
    return wake;
  }

  /// When night sleep began on the evening of [day]. A night that began after
  /// midnight, before 05:00, belongs to the evening before. Null until logged.
  DateTime? nightStartOn(List<DuoNapSleepSession> sessions, DateTime day) {
    DateTime? earliest;
    for (final session in sessions) {
      final tonight = isEveningOf(session.start, day);
      if (session.kind != DuoNapSleepKind.night || !tonight) continue;
      if (earliest == null || session.start.isBefore(earliest)) {
        earliest = session.start;
      }
    }
    return earliest;
  }

  /// [time] falls in the evening of [day]: from 14:00 that day until 05:00
  /// the next morning.
  bool isEveningOf(DateTime time, DateTime day) {
    if (_sameDay(time, day)) return time.hour >= latestWakeHour;
    final next = DateTime(day.year, day.month, day.day + 1);
    return _sameDay(time, next) && time.hour < earliestWakeHour;
  }

  /// The session behind one logged line of the plan, or null if nothing is
  /// logged for it. The line's own date picks the day.
  DuoNapSleepSession? loggedFor(
    List<DuoNapSleepSession> sessions,
    DuoNapPlanItem item,
  ) {
    final day = item.start;
    return switch (item.kind) {
      DuoNapPlanKind.wake => wakeSource(sessions, day),
      DuoNapPlanKind.night => _startingAt(sessions, nightStartOn(sessions, day)),
      DuoNapPlanKind.nap => _napAt(napsOn(sessions, day), item.index),
    };
  }

  /// The night sleep or hand wake-up whose end is the morning wake-up on [day].
  DuoNapSleepSession? wakeSource(List<DuoNapSleepSession> sessions, DateTime day) {
    return _endingAt(sessions, wakeOn(sessions, day));
  }

  List<DuoNapSleepSession> napsOn(List<DuoNapSleepSession> sessions, DateTime day) {
    return sessions
        .where((s) => s.kind == DuoNapSleepKind.nap && _sameDay(s.start, day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Finished days before today that have both a wake-up and at least one nap.
  List<DuoNapDayRecord> pastDays(List<DuoNapSleepSession> sessions, DateTime now) {
    final records = <DuoNapDayRecord>[];
    for (var back = 1; back <= _learningDays; back++) {
      final day = DateTime(now.year, now.month, now.day - back);
      final wake = wakeOn(sessions, day);
      final naps = napsOn(sessions, day).where((nap) => !nap.isOngoing).toList();
      if (wake == null || naps.isEmpty) continue;
      records.add(DuoNapDayRecord(wake: wake, naps: naps));
    }
    return records;
  }

  DuoNapSleepSession? _endingAt(List<DuoNapSleepSession> sessions, DateTime? at) {
    if (at == null) return null;
    final matches = sessions.where((s) => s.kind != DuoNapSleepKind.nap && s.end == at);
    return matches.isEmpty ? null : matches.last;
  }

  DuoNapSleepSession? _startingAt(List<DuoNapSleepSession> sessions, DateTime? at) {
    if (at == null) return null;
    final matches = sessions.where((s) => s.kind == DuoNapSleepKind.night && s.start == at);
    return matches.isEmpty ? null : matches.first;
  }

  /// Nap number [index] counts from 1.
  DuoNapSleepSession? _napAt(List<DuoNapSleepSession> naps, int index) {
    if (index < 1 || index > naps.length) return null;
    return naps[index - 1];
  }

  bool _isMorningOf(DateTime time, DateTime day) {
    final inWindow =
        time.hour >= earliestWakeHour && time.hour < latestWakeHour;
    return _sameDay(time, day) && inWindow;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
