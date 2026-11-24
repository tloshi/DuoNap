import '../domain/duonap_anchors.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_shift.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_day_history.dart';

/// The path toward 19:00 – 07:00, day by day. Pure: same setup and nights,
/// same answer. Rules in LOGIC.md, "Shift plan toward the target":
/// every 3 days both anchors move 15 minutes earlier, the wake-up stops at
/// 07:00, the bedtime at the target, and a step waits 2 days (and is checked
/// again) when the two nights before it both began more than 30 minutes late.
class DuoNapShiftPlan {
  const DuoNapShiftPlan(this.setup, this.nightStarts);

  /// [nightStarts] for each evening: the later of the twins' night starts.
  factory DuoNapShiftPlan.fromLog(
    DuoNapShiftSetup setup,
    List<DuoNapSleepSession> sessions,
  ) {
    final starts = <DateTime, DateTime>{};
    for (final baby in DuoNapBabyId.values) {
      final own = sessions.where((s) => s.babyId == baby).toList();
      _keepLater(starts, own);
    }
    return DuoNapShiftPlan(setup, starts);
  }

  static const int stepMinutes = 15;
  static const int _stepDays = 3;
  static const int _holdDays = 2;
  static const Duration _lateMargin = Duration(minutes: 30);
  static const DuoNapDayHistory _history = DuoNapDayHistory();

  final DuoNapShiftSetup setup;

  /// Keyed by the evening's date at local midnight.
  final Map<DateTime, DateTime> nightStarts;

  int get stepsTotal {
    final start = setup.start;
    final bedtime = _stepsBetween(start.bedtimeMinutes, setup.targetBedtimeMinutes);
    final wake = _stepsBetween(start.wakeMinutes, DuoNapShiftSetup.targetWakeMinutes);
    return bedtime > wake ? bedtime : wake;
  }

  DuoNapAnchors anchorsOn(DateTime day) => _anchorsAfter(_walk(day).steps);

  DuoNapShiftStatus statusOn(DateTime day) {
    final progress = _walk(day);
    return DuoNapShiftStatus(
      setup: setup,
      today: _anchorsAfter(progress.steps),
      stepsDone: progress.steps,
      stepsTotal: stepsTotal,
      held: progress.held,
      upcoming: _upcoming(progress),
    );
  }

  _Progress _walk(DateTime day) {
    final total = stepsTotal;
    var steps = 0;
    var held = false;
    var next = _plusDays(setup.startDay, _stepDays);
    for (var date = next; !date.isAfter(day) && steps < total; date = _plusDays(date, 1)) {
      if (!_sameDay(date, next)) continue;
      held = _lateTwice(date, steps);
      if (!held) steps++;
      next = _plusDays(date, held ? _holdDays : _stepDays);
    }
    return _Progress(steps, next, held);
  }

  bool _lateTwice(DateTime stepDay, int steps) {
    return _late(_plusDays(stepDay, -1), steps) && _late(_plusDays(stepDay, -2), steps);
  }

  bool _late(DateTime evening, int steps) {
    final start = nightStarts[evening];
    if (start == null) return false;
    final planned = evening.add(Duration(minutes: _anchorsAfter(steps).bedtimeMinutes));
    return start.isAfter(planned.add(_lateMargin));
  }

  List<DuoNapShiftStep> _upcoming(_Progress progress) {
    return [
      for (var step = progress.steps + 1; step <= stepsTotal; step++)
        DuoNapShiftStep(
          day: _plusDays(progress.next, (step - progress.steps - 1) * _stepDays),
          anchors: _anchorsAfter(step),
        ),
    ];
  }

  DuoNapAnchors _anchorsAfter(int steps) {
    final start = setup.start;
    return DuoNapAnchors(
      wakeMinutes: _stepped(start.wakeMinutes, DuoNapShiftSetup.targetWakeMinutes, steps),
      bedtimeMinutes: _stepped(start.bedtimeMinutes, setup.targetBedtimeMinutes, steps),
    );
  }

  /// [from] moved [steps] steps earlier, but never past [floor]. A start that
  /// is already at or before [floor] stays where it is.
  static int _stepped(int from, int floor, int steps) {
    if (from <= floor) return from;
    final moved = from - steps * stepMinutes;
    return moved > floor ? moved : floor;
  }

  static int _stepsBetween(int from, int floor) {
    if (from <= floor) return 0;
    return (from - floor + stepMinutes - 1) ~/ stepMinutes;
  }

  static void _keepLater(Map<DateTime, DateTime> starts, List<DuoNapSleepSession> own) {
    final evenings = own
        .where((s) => s.kind == DuoNapSleepKind.night)
        .map((s) => _eveningOf(s.start))
        .toSet();
    for (final evening in evenings) {
      final start = _history.nightStartOn(own, evening);
      final known = starts[evening];
      if (start != null && (known == null || start.isAfter(known))) starts[evening] = start;
    }
  }

  /// The evening a night start belongs to: the day before when it began
  /// after midnight, before 05:00.
  static DateTime _eveningOf(DateTime start) {
    final early = start.hour < DuoNapDayHistory.earliestWakeHour;
    return DateTime(start.year, start.month, start.day - (early ? 1 : 0));
  }

  static DateTime _plusDays(DateTime day, int days) {
    return DateTime(day.year, day.month, day.day + days);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Progress {
  const _Progress(this.steps, this.next, this.held);

  final int steps;

  /// The day the next step is due.
  final DateTime next;
  final bool held;
}
