import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_today_builder.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int day, int hour, int minute) => DateTime(2026, 11, day, hour, minute);

DuoNapSleepSession night(DuoNapBabyId baby, DateTime start) {
  return DuoNapSleepSession(
    id: '${baby.name}-${start.millisecondsSinceEpoch}',
    babyId: baby,
    kind: DuoNapSleepKind.night,
    start: start,
  );
}

void main() {
  const builder = DuoNapTodayBuilder();
  const settings = DuoNapSettings.defaults;

  test('it is night before dawn even with nothing logged', () {
    final snapshot = builder.build(const [], settings, at(24, 3, 0));

    expect(snapshot.isNight, isTrue);
  });

  test('it is day in the afternoon until night sleep is logged', () {
    final snapshot = builder.build(const [], settings, at(24, 15, 0));

    expect(snapshot.isNight, isFalse);
  });

  test('logging night sleep for both babies turns on the night view', () {
    final sessions = [
      night(DuoNapBabyId.first, at(24, 21, 0)),
      night(DuoNapBabyId.second, at(24, 21, 5)),
    ];

    final snapshot = builder.build(sessions, settings, at(24, 21, 30));

    expect(snapshot.isNight, isTrue);
  });

  test('the next wake-up is this morning before it, tomorrow after it', () {
    expect(builder.build(const [], settings, at(24, 3, 0)).nextWake, at(24, 8, 0));
    expect(builder.build(const [], settings, at(24, 23, 0)).nextWake, at(25, 8, 0));
  });

  test('the plan and names follow the settings', () {
    final custom = settings
        .withName(DuoNapBabyId.first, 'Ana')
        .withBedtime(20 * 60 + 30)
        .withWake(7 * 60);

    final snapshot = builder.build(const [], custom, at(24, 6, 0));

    expect(snapshot.baby(DuoNapBabyId.first).name, 'Ana');
    expect(snapshot.plan.first.kind, DuoNapPlanKind.wake);
    expect(snapshot.plan.first.start, at(24, 7, 0));
    expect(snapshot.plan.last.kind, DuoNapPlanKind.night);
    expect(snapshot.plan.last.start, at(24, 20, 30));
  });
}
