import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:duonap/domain/duonap_shift.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_shift_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/duonap_fake_repositories.dart';

DateTime at(int date, int hour, int minute) => DateTime(2026, 11, date, hour, minute);

String? codeOf(DuoNapResult<void> result) {
  return result is DuoNapFailure<void> ? result.code : null;
}

void main() {
  late DuoNapFakeShiftRepository shift;
  late DuoNapFakeSleepRepository sleep;
  late DateTime now;
  late DuoNapShiftService service;

  setUp(() {
    shift = DuoNapFakeShiftRepository();
    sleep = DuoNapFakeSleepRepository();
    now = at(24, 10, 0);
    final settings = DuoNapFakeSettingsRepository(
      DuoNapSettings.defaults.withWake(8 * 60 + 15).withBedtime(21 * 60 + 45),
    );
    service = DuoNapShiftService(
      shift: shift,
      settings: settings,
      sleep: sleep,
      clock: () => now,
    );
  });

  Future<DuoNapShiftStatus?> status() async {
    final result = await service.status();
    return (result as DuoNapSuccess<DuoNapShiftStatus?>).data;
  }

  test('no status until the path is started', () async {
    expect(await status(), isNull);
  });

  test('starting takes today and the times in settings', () async {
    expect(codeOf(await service.start()), isNull);

    expect(shift.stored?.startDay, DateTime(2026, 11, 24));
    expect(shift.stored?.start.wakeMinutes, 8 * 60 + 15);
    expect(shift.stored?.start.bedtimeMinutes, 21 * 60 + 45);
    expect(shift.stored?.targetBedtimeMinutes, 19 * 60 + 30);
    expect((await status())?.stepsDone, 0);
  });

  test('a running path cannot be started again', () async {
    await service.start();

    expect(codeOf(await service.start()), 'ALREADY_RUNNING');
  });

  test('three days later the first step is done', () async {
    await service.start();
    now = at(27, 9, 0);

    final today = (await status())?.today;

    expect(today?.wakeMinutes, 8 * 60);
    expect(today?.bedtimeMinutes, 21 * 60 + 30);
  });

  test('two late nights in the log hold the step', () async {
    await service.start();
    for (final evening in [25, 26]) {
      await sleep.save(
        DuoNapSleepSession(
          id: 'first-$evening',
          babyId: DuoNapBabyId.first,
          kind: DuoNapSleepKind.night,
          start: at(evening, 22, 30),
          end: at(evening + 1, 7, 30),
        ),
      );
    }
    now = at(27, 9, 0);

    final current = await status();

    expect(current?.held, isTrue);
    expect(current?.stepsDone, 0);
  });

  test('the target can be one of the choices only', () async {
    await service.start();

    expect(codeOf(await service.setTarget(18 * 60)), 'TARGET_INVALID');
    expect(codeOf(await service.setTarget(19 * 60)), isNull);
    expect((await status())?.stepsTotal, 11);
  });

  test('setting a target needs a running path', () async {
    expect(codeOf(await service.setTarget(19 * 60)), 'NOT_RUNNING');
  });

  test('stopping removes the path', () async {
    await service.start();

    await service.stop();

    expect(await status(), isNull);
  });
}
