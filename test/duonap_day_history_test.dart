import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_day_history.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int day, int hour, int minute) => DateTime(2026, 11, day, hour, minute);

DuoNapSleepSession session(
  DuoNapSleepKind kind,
  DateTime start, [
  DateTime? end,
]) {
  return DuoNapSleepSession(
    id: '${kind.name}-${start.millisecondsSinceEpoch}',
    babyId: DuoNapBabyId.first,
    kind: kind,
    start: start,
    end: end,
  );
}

DuoNapPlanItem planItem(DuoNapPlanKind kind, DateTime start, [int index = 0]) {
  return DuoNapPlanItem(
    kind: kind,
    index: index,
    start: start,
    expected: Duration.zero,
    status: DuoNapPlanStatus.done,
  );
}

void main() {
  const history = DuoNapDayHistory();

  test('a wake-up logged by hand counts as the morning wake-up', () {
    final wake = session(DuoNapSleepKind.wake, at(24, 7, 40), at(24, 7, 40));

    expect(history.wakeOn([wake], at(24, 0, 0)), at(24, 7, 40));
  });

  test('the later of a logged night and a hand wake-up wins', () {
    final sessions = [
      session(DuoNapSleepKind.night, at(23, 21, 0), at(24, 6, 10)),
      session(DuoNapSleepKind.wake, at(24, 7, 0), at(24, 7, 0)),
    ];

    expect(history.wakeOn(sessions, at(24, 0, 0)), at(24, 7, 0));
  });

  test('a hand wake-up is not a nap and not night sleep', () {
    final wake = session(DuoNapSleepKind.wake, at(24, 7, 40), at(24, 7, 40));

    expect(history.napsOn([wake], at(24, 0, 0)), isEmpty);
    expect(history.nightStartOn([wake], at(24, 0, 0)), isNull);
    expect(history.ongoing([wake]), isNull);
  });

  test('a night that began after midnight belongs to the evening before', () {
    final late = session(DuoNapSleepKind.night, at(25, 0, 30), at(25, 7, 0));

    expect(history.nightStartOn([late], at(24, 0, 0)), at(25, 0, 30));
    expect(history.nightStartOn([late], at(25, 0, 0)), isNull);
  });

  test('a night wake-up after midnight does not replace the evening start', () {
    final sessions = [
      session(DuoNapSleepKind.night, at(24, 21, 0), at(25, 1, 0)),
      session(DuoNapSleepKind.night, at(25, 1, 30), at(25, 7, 0)),
    ];

    expect(history.nightStartOn(sessions, at(24, 0, 0)), at(24, 21, 0));
  });

  test('finds the session behind each logged line of the plan', () {
    final night = session(DuoNapSleepKind.night, at(23, 21, 0), at(24, 7, 5));
    final nap1 = session(DuoNapSleepKind.nap, at(24, 9, 0), at(24, 10, 20));
    final nap2 = session(DuoNapSleepKind.nap, at(24, 13, 0), at(24, 14, 0));
    final tonight = session(DuoNapSleepKind.night, at(24, 21, 10));
    final sessions = [night, nap1, nap2, tonight];

    final wakeRow = planItem(DuoNapPlanKind.wake, at(24, 7, 5));
    final napRow = planItem(DuoNapPlanKind.nap, at(24, 13, 0), 2);
    final nightRow = planItem(DuoNapPlanKind.night, at(24, 21, 10));

    expect(history.loggedFor(sessions, wakeRow)?.id, night.id);
    expect(history.loggedFor(sessions, napRow)?.id, nap2.id);
    expect(history.loggedFor(sessions, nightRow)?.id, tonight.id);
  });

  test('a plan line with nothing logged behind it finds nothing', () {
    final napRow = planItem(DuoNapPlanKind.nap, at(24, 13, 0), 2);

    expect(history.loggedFor(const [], napRow), isNull);
  });
}
