import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_profile_learner.dart';

/// Reads one baby's logged sessions: who is asleep, when the day started,
/// which naps belong to a day. All lists passed in are for a single baby.
class DuoNapDayHistory {
  const DuoNapDayHistory();

  static const int _earliestWakeHour = 5;
  static const int _latestWakeHour = 14;
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

  /// The morning wake-up on [day]: the end of the last night sleep that ended
  /// that morning. Null while the baby is still in last night's sleep.
  DateTime? wakeOn(List<DuoNapSleepSession> sessions, DateTime day) {
    final latest = DateTime(day.year, day.month, day.day, _latestWakeHour);
    DateTime? wake;
    for (final session in sessions) {
      if (session.kind != DuoNapSleepKind.night) continue;
      final end = session.end;
      if (end == null && session.start.isBefore(latest)) return null;
      if (end == null || !_isMorningOf(end, day)) continue;
      if (wake == null || end.isAfter(wake)) wake = end;
    }
    return wake;
  }

  /// When night sleep began on the evening of [day]. Null until it is logged.
  DateTime? nightStartOn(List<DuoNapSleepSession> sessions, DateTime day) {
    DateTime? earliest;
    for (final session in sessions) {
      final evening = session.start.hour >= _latestWakeHour;
      final tonight = _sameDay(session.start, day) && evening;
      if (session.kind != DuoNapSleepKind.night || !tonight) continue;
      if (earliest == null || session.start.isBefore(earliest)) {
        earliest = session.start;
      }
    }
    return earliest;
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

  bool _isMorningOf(DateTime time, DateTime day) {
    final inWindow =
        time.hour >= _earliestWakeHour && time.hour < _latestWakeHour;
    return _sameDay(time, day) && inWindow;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
