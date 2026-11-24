import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_sleep_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/duonap_fake_repositories.dart';

DateTime at(int date, int hour, int minute) => DateTime(2026, 11, date, hour, minute);

DuoNapSleepSession night(DuoNapBabyId baby, DateTime start, DateTime end) {
  return DuoNapSleepSession(
    id: '${baby.name}-${start.millisecondsSinceEpoch}',
    babyId: baby,
    kind: DuoNapSleepKind.night,
    start: start,
    end: end,
  );
}

void main() {
  test('a baby after a short night goes to night sleep earlier', () async {
    final sessions = [
      for (var e = 16; e <= 22; e++) ...[
        night(DuoNapBabyId.first, at(e, 21, 15), at(e + 1, 7, 45)),
        night(DuoNapBabyId.second, at(e, 21, 15), at(e + 1, 7, 45)),
      ],
      night(DuoNapBabyId.first, at(23, 21, 15), at(24, 6, 15)),
      night(DuoNapBabyId.second, at(23, 21, 15), at(24, 7, 45)),
    ];
    final sleep = DuoNapFakeSleepRepository(sessions);
    final service = DuoNapSleepService(
      repository: sleep,
      settings: DuoNapFakeSettingsRepository(),
      shift: DuoNapFakeShiftRepository(),
      clock: () => at(24, 19, 45),
    );

    await service.toggle(DuoNapBabyId.first);
    await service.toggle(DuoNapBabyId.second);

    DuoNapSleepKind kindOf(DuoNapBabyId baby) {
      return sleep.sessions.values.firstWhere((s) => s.babyId == baby && s.isOngoing).kind;
    }

    // First baby: bedtime 21:15 moved to 20:30, night from 19:30 on.
    expect(kindOf(DuoNapBabyId.first), DuoNapSleepKind.night);
    // Second baby: bedtime 21:15, night only from 20:15 on.
    expect(kindOf(DuoNapBabyId.second), DuoNapSleepKind.nap);
  });
}
