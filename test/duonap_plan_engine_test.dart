import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/domain/duonap_sleep_profile.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_plan_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int hour, int minute) => DateTime(2026, 11, 23, hour, minute);

DuoNapSleepSession nap(DateTime start, [DateTime? end]) {
  return DuoNapSleepSession(
    id: 'nap-${start.millisecondsSinceEpoch}',
    babyId: DuoNapBabyId.first,
    kind: DuoNapSleepKind.nap,
    start: start,
    end: end,
  );
}

void main() {
  const engine = DuoNapPlanEngine();
  const profile = DuoNapSleepProfile.starter;

  test('fresh day: three naps from the wake-up, night at the planned bedtime', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(8, 30),
        profile: profile,
        naps: const [],
        wakeTime: at(8, 0),
      ),
    );

    expect(plan.map((item) => item.start).toList(), [
      at(8, 0),
      at(9, 45),
      at(13, 35),
      at(17, 20),
      at(21, 15),
    ]);
    expect(plan[0].status, DuoNapPlanStatus.done);
    expect(plan[1].status, DuoNapPlanStatus.next);
    expect(plan[2].status, DuoNapPlanStatus.upcoming);
    expect(plan[3].expected, const Duration(minutes: 30));
  });

  test('a late last nap pushes night to nap end + min last window', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(19, 2),
        profile: profile,
        naps: [
          nap(at(9, 55), at(11, 20)),
          nap(at(13, 0), at(14, 27)),
          nap(at(19, 1)),
        ],
        wakeTime: at(8, 13),
      ),
    );

    expect(plan[3].status, DuoNapPlanStatus.ongoing);
    expect(plan[3].end, at(19, 31));
    expect(plan.last.kind, DuoNapPlanKind.night);
    expect(plan.last.start, at(21, 51));
    expect(plan.last.status, DuoNapPlanStatus.next);
  });

  test('an overdue nap is flagged and the rest of the day moves with it', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(10, 30),
        profile: profile,
        naps: const [],
        wakeTime: at(8, 0),
      ),
    );

    expect(plan[1].start, at(9, 45));
    expect(plan[1].status, DuoNapPlanStatus.overdue);
    expect(plan[2].start, at(14, 20));
    expect(plan.last.start, at(21, 15));
  });

  test('no nap is planned close to night sleep', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(18, 5),
        profile: profile,
        naps: [
          nap(at(9, 45), at(11, 15)),
          nap(at(16, 30), at(18, 0)),
        ],
        wakeTime: at(8, 0),
      ),
    );

    expect(plan.length, 4);
    expect(plan.last.start, at(21, 15));
  });

  test('when the nap budget is used up, night moves earlier instead', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(15, 10),
        profile: profile,
        naps: [
          nap(at(9, 45), at(11, 45)),
          nap(at(13, 35), at(15, 5)),
        ],
        wakeTime: at(8, 0),
      ),
    );

    expect(plan.length, 4);
    expect(plan.last.start, at(19, 5));
  });

  test('a logged night closes the day', () {
    final plan = engine.build(
      DuoNapPlanInput(
        now: at(21, 40),
        profile: profile,
        naps: [nap(at(9, 45), at(11, 15))],
        wakeTime: at(8, 0),
        nightStart: at(21, 20),
      ),
    );

    expect(plan.last.kind, DuoNapPlanKind.night);
    expect(plan.last.start, at(21, 20));
    expect(plan.last.status, DuoNapPlanStatus.done);
    expect(plan.length, 3);
  });

  test('without a logged wake-up the usual wake time anchors the plan', () {
    final plan = engine.build(
      DuoNapPlanInput(now: at(6, 30), profile: profile, naps: const []),
    );

    expect(plan.first.start, at(8, 0));
    expect(plan.first.status, DuoNapPlanStatus.next);
    expect(plan[1].start, at(9, 45));
  });
}
