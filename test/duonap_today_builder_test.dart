import 'package:duonap/domain/duonap_anchors.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:duonap/domain/duonap_shift.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_today_builder.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int day, int hour, int minute) => DateTime(2026, 11, day, hour, minute);

DuoNapSleepSession night(DuoNapBabyId baby, DateTime start, [DateTime? end]) {
  return DuoNapSleepSession(
    id: '${baby.name}-${start.millisecondsSinceEpoch}',
    babyId: baby,
    kind: DuoNapSleepKind.night,
    start: start,
    end: end,
  );
}

DuoNapTodayInputs inputs(List<DuoNapSleepSession> sessions, [DuoNapShiftSetup? shift]) {
  return DuoNapTodayInputs(
    sessions: sessions,
    settings: DuoNapSettings.defaults,
    shift: shift,
  );
}

void main() {
  const builder = DuoNapTodayBuilder();

  test('it is night before dawn even with nothing logged', () {
    expect(builder.build(inputs(const []), at(24, 3, 0)).isNight, isTrue);
  });

  test('it is day in the afternoon until night sleep is logged', () {
    expect(builder.build(inputs(const []), at(24, 15, 0)).isNight, isFalse);
  });

  test('logging night sleep for both babies turns on the night view', () {
    final sessions = [
      night(DuoNapBabyId.first, at(24, 21, 0)),
      night(DuoNapBabyId.second, at(24, 21, 5)),
    ];

    expect(builder.build(inputs(sessions), at(24, 21, 30)).isNight, isTrue);
  });

  test('the next wake-up is this morning before it, tomorrow after it', () {
    expect(builder.build(inputs(const []), at(24, 3, 0)).nextWake, at(24, 8, 0));
    expect(builder.build(inputs(const []), at(24, 23, 0)).nextWake, at(25, 8, 0));
  });

  test('the plan and names follow the settings', () {
    final custom = DuoNapSettings.defaults
        .withName(DuoNapBabyId.first, 'Ana')
        .withBedtime(20 * 60 + 30)
        .withWake(7 * 60);
    final input = DuoNapTodayInputs(sessions: const [], settings: custom);

    final snapshot = builder.build(input, at(24, 6, 0));

    expect(snapshot.baby(DuoNapBabyId.first).name, 'Ana');
    expect(snapshot.plan.first.start, at(24, 7, 0));
    expect(snapshot.plan.last.start, at(24, 20, 30));
  });

  test('while the path runs, its times replace the settings', () {
    final shift = DuoNapShiftSetup(
      startDay: DateTime(2026, 11, 21),
      start: const DuoNapAnchors(wakeMinutes: 8 * 60 + 15, bedtimeMinutes: 21 * 60 + 45),
      targetBedtimeMinutes: 19 * 60 + 30,
    );

    final snapshot = builder.build(inputs(const [], shift), at(24, 6, 0));

    expect(snapshot.plan.first.start, at(24, 8, 0));
    expect(snapshot.plan.last.kind, DuoNapPlanKind.night);
    expect(snapshot.plan.last.start, at(24, 21, 30));
  });

  test('after a short night only that baby\'s night moves earlier', () {
    final sessions = [
      for (var e = 16; e <= 22; e++) ...[
        night(DuoNapBabyId.first, at(e, 21, 15), at(e + 1, 7, 45)),
        night(DuoNapBabyId.second, at(e, 21, 15), at(e + 1, 7, 45)),
      ],
      night(DuoNapBabyId.first, at(23, 21, 15), at(24, 6, 15)),
      night(DuoNapBabyId.second, at(23, 21, 15), at(24, 7, 45)),
    ];

    final snapshot = builder.build(inputs(sessions), at(24, 9, 0));

    expect(snapshot.babyPlans[DuoNapBabyId.first]?.last.start, at(24, 20, 30));
    expect(snapshot.babyPlans[DuoNapBabyId.second]?.last.start, at(24, 21, 15));
  });
}
