import '../domain/duonap_plan_item.dart';
import '../domain/duonap_sleep_profile.dart';
import '../domain/duonap_sleep_session.dart';

class DuoNapPlanInput {
  const DuoNapPlanInput({
    required this.now,
    required this.profile,
    required this.naps,
    this.wakeTime,
    this.nightStart,
  });

  final DateTime now;
  final DuoNapSleepProfile profile;

  /// Today's naps for one baby, finished or still running.
  final List<DuoNapSleepSession> naps;

  /// Today's morning wake-up. Null until it is logged.
  final DateTime? wakeTime;

  /// When tonight's sleep began. Null until it is logged.
  final DateTime? nightStart;
}

/// Builds one baby's plan for today. Pure: same input, same plan.
///
/// Rules:
/// 1. The morning wake-up starts the day.
/// 2. Next nap = end of the previous sleep + the wake window for that position.
/// 3. Daytime sleep is capped, and no nap starts too close to night sleep.
/// 4. Night = the planned bedtime, but never sooner than (last nap end + min last
///    window) and never later than (last nap end + max last window).
class DuoNapPlanEngine {
  const DuoNapPlanEngine();

  static const Duration _minNap = Duration(minutes: 15);
  static const Duration _lateNapMargin = Duration(minutes: 30);

  List<DuoNapPlanItem> build(DuoNapPlanInput input) {
    final profile = input.profile;
    final day = DateTime(input.now.year, input.now.month, input.now.day);
    final wake = input.wakeTime ??
        day.add(Duration(minutes: profile.usualWakeMinutes));
    final state = _DayState(wake);

    final items = <DuoNapPlanItem>[_wakeItem(wake, input.wakeTime != null)];
    items.addAll(_loggedNaps(input, state));

    final nightStart = input.nightStart;
    if (nightStart != null) {
      items.add(_nightItem(nightStart, DuoNapPlanStatus.done));
      return items;
    }

    final bedtime = day.add(Duration(minutes: profile.plannedBedtimeMinutes));
    items.addAll(_plannedNaps(input, state, bedtime));
    final night = _nightStart(input, state.cursor, bedtime);
    items.add(_nightItem(night, DuoNapPlanStatus.upcoming));
    return _markNext(items, input.now);
  }

  /// The planned bedtime, kept between the shortest and longest last wake window.
  /// The pull-earlier limit is ignored once that moment has already passed.
  DateTime _nightStart(
    DuoNapPlanInput input,
    DateTime lastWake,
    DateTime bedtime,
  ) {
    final earliest = lastWake.add(input.profile.minLastWindow);
    final latest = lastWake.add(input.profile.maxLastWindow);
    if (bedtime.isBefore(earliest)) return earliest;
    if (bedtime.isAfter(latest) && latest.isAfter(input.now)) return latest;
    return bedtime;
  }

  List<DuoNapPlanItem> _loggedNaps(DuoNapPlanInput input, _DayState state) {
    final naps = [...input.naps]..sort((a, b) => a.start.compareTo(b.start));
    final items = <DuoNapPlanItem>[];
    for (var i = 0; i < naps.length; i++) {
      final expected = _expectedLength(input.profile, i);
      final end = _endOf(naps[i], expected, input.now);
      final length = end.difference(naps[i].start);
      items.add(_loggedNap(naps[i], i + 1, length));
      state.cursor = end;
      state.daySleep += length;
    }
    return items;
  }

  List<DuoNapPlanItem> _plannedNaps(
    DuoNapPlanInput input,
    _DayState state,
    DateTime bedtime,
  ) {
    final profile = input.profile;
    final cutoff = bedtime.subtract(profile.minLastWindow + _lateNapMargin);
    final items = <DuoNapPlanItem>[];
    for (var i = input.naps.length; i < profile.napCount; i++) {
      final planned = state.cursor.add(profile.wakeWindows[i]);
      final budget = profile.maxDaySleep - state.daySleep;
      final length = _shorter(profile.napLengths[i], budget);
      final effective = planned.isBefore(input.now) ? input.now : planned;
      if (length < _minNap || effective.isAfter(cutoff)) break;
      items.add(_plannedNap(planned, i + 1, length));
      state.cursor = effective.add(length);
      state.daySleep += length;
    }
    return items;
  }

  DuoNapPlanItem _wakeItem(DateTime wake, bool logged) {
    return DuoNapPlanItem(
      kind: DuoNapPlanKind.wake,
      index: 0,
      start: wake,
      expected: Duration.zero,
      status: logged ? DuoNapPlanStatus.done : DuoNapPlanStatus.upcoming,
    );
  }

  DuoNapPlanItem _loggedNap(DuoNapSleepSession nap, int number, Duration length) {
    return DuoNapPlanItem(
      kind: DuoNapPlanKind.nap,
      index: number,
      start: nap.start,
      expected: length,
      status: nap.isOngoing ? DuoNapPlanStatus.ongoing : DuoNapPlanStatus.done,
    );
  }

  DuoNapPlanItem _plannedNap(DateTime start, int number, Duration length) {
    return DuoNapPlanItem(
      kind: DuoNapPlanKind.nap,
      index: number,
      start: start,
      expected: length,
      status: DuoNapPlanStatus.upcoming,
    );
  }

  DuoNapPlanItem _nightItem(DateTime start, DuoNapPlanStatus status) {
    return DuoNapPlanItem(
      kind: DuoNapPlanKind.night,
      index: 0,
      start: start,
      expected: Duration.zero,
      status: status,
    );
  }

  Duration _expectedLength(DuoNapSleepProfile profile, int position) {
    final lengths = profile.napLengths;
    return position < lengths.length ? lengths[position] : lengths.last;
  }

  /// A running nap is expected to end at its usual length, or now if it ran over.
  DateTime _endOf(DuoNapSleepSession nap, Duration expected, DateTime now) {
    final end = nap.end;
    if (end != null) return end;
    final usualEnd = nap.start.add(expected);
    return usualEnd.isAfter(now) ? usualEnd : now;
  }

  Duration _shorter(Duration a, Duration b) => a < b ? a : b;

  /// The first item that has not happened yet becomes `next`, or `overdue` if late.
  List<DuoNapPlanItem> _markNext(List<DuoNapPlanItem> items, DateTime now) {
    final index = items.indexWhere(
      (item) => item.status == DuoNapPlanStatus.upcoming,
    );
    if (index < 0) return items;
    final item = items[index];
    final status = item.start.isBefore(now)
        ? DuoNapPlanStatus.overdue
        : DuoNapPlanStatus.next;
    return [...items]..[index] = item.copyWith(status: status);
  }
}

/// Running position while a day is being laid out.
class _DayState {
  _DayState(this.cursor);

  /// When the baby last woke up, or is expected to.
  DateTime cursor;

  Duration daySleep = Duration.zero;
}
