import 'package:duonap/domain/duonap_anchors.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_shift.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_shift_plan.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime day(int month, int date) => DateTime(2026, month, date);
DateTime at(int month, int date, int hour, int minute) =>
    DateTime(2026, month, date, hour, minute);

/// LOGIC.md section 6: start from 08:15 and 21:45, target 19:30.
final setup = DuoNapShiftSetup(
  startDay: day(11, 24),
  start: const DuoNapAnchors(wakeMinutes: 8 * 60 + 15, bedtimeMinutes: 21 * 60 + 45),
  targetBedtimeMinutes: 19 * 60 + 30,
);

String clock(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String anchorsOn(DuoNapShiftPlan plan, DateTime date) {
  final anchors = plan.anchorsOn(date);
  return '${clock(anchors.wakeMinutes)} ${clock(anchors.bedtimeMinutes)}';
}

void main() {
  final calm = DuoNapShiftPlan(setup, const {});

  test('the first three days keep the starting times', () {
    expect(anchorsOn(calm, day(11, 24)), '08:15 21:45');
    expect(anchorsOn(calm, day(11, 26)), '08:15 21:45');
  });

  test('every three days both move 15 minutes earlier', () {
    expect(anchorsOn(calm, day(11, 27)), '08:00 21:30');
    expect(anchorsOn(calm, day(11, 30)), '07:45 21:15');
  });

  test('the wake-up stops at 07:00 while the night goes on', () {
    expect(anchorsOn(calm, day(12, 9)), '07:00 20:30');
    expect(anchorsOn(calm, day(12, 12)), '07:00 20:15');
  });

  test('the night stops at the target', () {
    expect(anchorsOn(calm, day(12, 21)), '07:00 19:30');
    expect(anchorsOn(calm, day(12, 31)), '07:00 19:30');
    expect(calm.statusOn(day(12, 21)).finished, isTrue);
  });

  test('two late nights in a row hold the step for two days', () {
    final plan = DuoNapShiftPlan(setup, {
      day(11, 25): at(11, 25, 22, 20),
      day(11, 26): at(11, 26, 22, 16),
    });

    expect(anchorsOn(plan, day(11, 27)), '08:15 21:45');
    expect(plan.statusOn(day(11, 28)).held, isTrue);
    expect(anchorsOn(plan, day(11, 29)), '08:00 21:30');
    expect(plan.statusOn(day(11, 29)).held, isFalse);
  });

  test('the hold repeats while the nights stay late', () {
    final plan = DuoNapShiftPlan(setup, {
      for (var date = 25; date <= 28; date++) day(11, date): at(11, date, 22, 30),
    });

    expect(anchorsOn(plan, day(11, 29)), '08:15 21:45');
    expect(anchorsOn(plan, day(12, 1)), '08:00 21:30');
  });

  test('one late night alone does not hold the step', () {
    final plan = DuoNapShiftPlan(setup, {day(11, 26): at(11, 26, 23, 0)});

    expect(anchorsOn(plan, day(11, 27)), '08:00 21:30');
  });

  test('exactly 30 minutes late is not late', () {
    final plan = DuoNapShiftPlan(setup, {
      day(11, 25): at(11, 25, 22, 15),
      day(11, 26): at(11, 26, 22, 15),
    });

    expect(anchorsOn(plan, day(11, 27)), '08:00 21:30');
  });

  test('the status counts the steps and lists the ones to come', () {
    final status = calm.statusOn(day(11, 28));

    expect(status.stepsDone, 1);
    expect(status.stepsTotal, 9);
    expect(status.upcoming.first.day, day(11, 30));
    expect(status.arrival, day(12, 21));
  });

  test('a start already at the target has no steps', () {
    final done = DuoNapShiftSetup(
      startDay: day(11, 24),
      start: const DuoNapAnchors(wakeMinutes: 7 * 60, bedtimeMinutes: 19 * 60),
      targetBedtimeMinutes: 19 * 60 + 30,
    );
    final status = DuoNapShiftPlan(done, const {}).statusOn(day(12, 1));

    expect(status.stepsTotal, 0);
    expect(status.finished, isTrue);
    expect(status.today.bedtimeMinutes, 19 * 60);
  });

  group('from the log', () {
    DuoNapSleepSession night(DuoNapBabyId baby, DateTime start) {
      return DuoNapSleepSession(
        id: '${baby.name}-${start.millisecondsSinceEpoch}',
        babyId: baby,
        kind: DuoNapSleepKind.night,
        start: start,
        end: start.add(const Duration(hours: 8)),
      );
    }

    test('a night that began after midnight counts as a late evening', () {
      final plan = DuoNapShiftPlan.fromLog(setup, [
        night(DuoNapBabyId.first, at(11, 26, 0, 30)),
        night(DuoNapBabyId.first, at(11, 27, 0, 10)),
      ]);

      expect(anchorsOn(plan, day(11, 27)), '08:15 21:45');
    });

    test('a twin with no night logged leaves the other twin to decide', () {
      final plan = DuoNapShiftPlan.fromLog(setup, [
        night(DuoNapBabyId.second, at(11, 25, 22, 40)),
        night(DuoNapBabyId.second, at(11, 26, 22, 35)),
      ]);

      expect(plan.statusOn(day(11, 27)).held, isTrue);
    });
  });

  test('the later twin decides when the night began', () {
    DuoNapSleepSession night(DuoNapBabyId baby, DateTime start) {
      return DuoNapSleepSession(
        id: '${baby.name}-${start.millisecondsSinceEpoch}',
        babyId: baby,
        kind: DuoNapSleepKind.night,
        start: start,
        end: start.add(const Duration(hours: 9)),
      );
    }

    final plan = DuoNapShiftPlan.fromLog(setup, [
      night(DuoNapBabyId.first, at(11, 25, 21, 40)),
      night(DuoNapBabyId.second, at(11, 25, 22, 20)),
      night(DuoNapBabyId.first, at(11, 26, 22, 25)),
      night(DuoNapBabyId.second, at(11, 26, 21, 50)),
    ]);

    expect(anchorsOn(plan, day(11, 27)), '08:15 21:45');
  });
}
