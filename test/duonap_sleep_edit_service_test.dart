import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_logged_sleep.dart';
import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_sleep_edit_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/duonap_fake_repositories.dart';

DateTime at(int hour, int minute) => DateTime(2026, 11, 24, hour, minute);
DateTime lastNight(int hour, int minute) => DateTime(2026, 11, 23, hour, minute);

DuoNapSleepSession sleep(String id, DuoNapSleepKind kind, DateTime start, [DateTime? end]) {
  final baby = id.startsWith('first') ? DuoNapBabyId.first : DuoNapBabyId.second;
  return DuoNapSleepSession(id: id, babyId: baby, kind: kind, start: start, end: end);
}

String? codeOf(DuoNapResult<void> result) {
  return result is DuoNapFailure<void> ? result.code : null;
}

void main() {
  final now = at(15, 0);
  late DuoNapFakeSleepRepository repository;
  late DuoNapSleepEditService service;

  void seed(List<DuoNapSleepSession> sessions) {
    repository = DuoNapFakeSleepRepository(sessions);
    service = DuoNapSleepEditService(repository: repository, clock: () => now);
  }

  setUp(() => seed(const []));

  group('retime', () {
    test('moves the start and end of a finished nap', () async {
      final nap = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
      seed([nap]);

      final times = DuoNapSleepTimes(start: at(9, 5), end: at(10, 20));
      final result = await service.retime([nap], times);

      expect(codeOf(result), isNull);
      expect(repository.sessions['first-1']?.start, at(9, 5));
      expect(repository.sessions['first-1']?.end, at(10, 20));
    });

    test('applies the same times to both babies', () async {
      final a = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
      final b = sleep('second-1', DuoNapSleepKind.nap, at(9, 10), at(10, 5));
      seed([a, b]);

      final times = DuoNapSleepTimes(start: at(9, 2), end: at(10, 2));
      await service.retime([a, b], times);

      expect(repository.sessions['first-1']?.start, at(9, 2));
      expect(repository.sessions['second-1']?.start, at(9, 2));
    });

    test('keeps a running nap running', () async {
      final nap = sleep('first-1', DuoNapSleepKind.nap, at(14, 30));
      seed([nap]);

      await service.retime([nap], DuoNapSleepTimes(start: at(14, 20)));

      expect(repository.sessions['first-1']?.start, at(14, 20));
      expect(repository.sessions['first-1']?.isOngoing, isTrue);
    });

    test('rejects an end before the start', () async {
      final nap = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
      seed([nap]);

      final times = DuoNapSleepTimes(start: at(10, 0), end: at(9, 59));

      expect(codeOf(await service.retime([nap], times)), 'END_BEFORE_START');
      expect(repository.sessions['first-1']?.start, at(9, 0));
    });

    test('rejects a time in the future', () async {
      final nap = sleep('first-1', DuoNapSleepKind.nap, at(14, 0), at(14, 50));
      seed([nap]);

      final times = DuoNapSleepTimes(start: at(14, 0), end: at(15, 1));

      expect(codeOf(await service.retime([nap], times)), 'IN_FUTURE');
    });

    test('rejects moving a nap over the next one', () async {
      final a = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
      final b = sleep('first-2', DuoNapSleepKind.nap, at(12, 0), at(13, 0));
      seed([a, b]);

      final times = DuoNapSleepTimes(start: at(9, 0), end: at(12, 10));

      expect(codeOf(await service.retime([a], times)), 'OVERLAP');
    });

    test('rejects taking the end away from a finished sleep', () async {
      final nap = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
      seed([nap]);

      final result = await service.retime([nap], DuoNapSleepTimes(start: at(9, 0)));

      expect(codeOf(result), 'END_MISSING');
    });
  });

  test('delete removes every chosen session', () async {
    final a = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
    final b = sleep('second-1', DuoNapSleepKind.nap, at(9, 10), at(10, 5));
    seed([a, b]);

    await service.delete([a, b]);

    expect(repository.sessions, isEmpty);
  });

  group('logWake', () {
    const both = {DuoNapBabyId.first, DuoNapBabyId.second};

    test('adds a hand wake-up for each baby when nothing is logged', () async {
      final result = await service.logWake(both, at(7, 30));

      expect(codeOf(result), isNull);
      final marks = repository.sessions.values.toList();
      expect(marks, hasLength(2));
      expect(marks.every((s) => s.kind == DuoNapSleepKind.wake), isTrue);
      expect(marks.every((s) => s.start == at(7, 30) && s.end == at(7, 30)), isTrue);
    });

    test('ends a night that is still running', () async {
      final night = sleep('first-n', DuoNapSleepKind.night, lastNight(21, 0));
      seed([night]);

      await service.logWake({DuoNapBabyId.first}, at(7, 10));

      expect(repository.sessions['first-n']?.end, at(7, 10));
      expect(repository.sessions, hasLength(1));
    });

    test('moves the end of the night that ended this morning', () async {
      final night =
          sleep('first-n', DuoNapSleepKind.night, lastNight(21, 0), at(6, 50));
      seed([night]);

      await service.logWake({DuoNapBabyId.first}, at(7, 5));

      expect(repository.sessions['first-n']?.end, at(7, 5));
    });

    test('moves an earlier hand wake-up', () async {
      final mark = sleep('first-w', DuoNapSleepKind.wake, at(7, 0), at(7, 0));
      seed([mark]);

      await service.logWake({DuoNapBabyId.first}, at(7, 20));

      expect(repository.sessions['first-w']?.start, at(7, 20));
      expect(repository.sessions['first-w']?.end, at(7, 20));
    });

    test('rejects a wake-up before the running night began', () async {
      final night = sleep('first-n', DuoNapSleepKind.night, at(6, 0));
      seed([night]);

      final result = await service.logWake({DuoNapBabyId.first}, at(5, 30));

      expect(codeOf(result), 'END_BEFORE_START');
      expect(repository.sessions['first-n']?.isOngoing, isTrue);
    });

    test('rejects a time outside the morning window', () async {
      expect(codeOf(await service.logWake(both, at(4, 50))), 'WAKE_OUT_OF_RANGE');
      expect(codeOf(await service.logWake(both, at(14, 0))), 'WAKE_OUT_OF_RANGE');
      expect(repository.sessions, isEmpty);
    });
  });

  test('find returns each baby\'s session behind a plan line', () async {
    final a = sleep('first-1', DuoNapSleepKind.nap, at(9, 0), at(10, 0));
    final b = sleep('second-1', DuoNapSleepKind.nap, at(9, 10), at(10, 5));
    seed([a, b]);
    final row = DuoNapPlanItem(
      kind: DuoNapPlanKind.nap,
      index: 1,
      start: at(9, 0),
      expected: const Duration(hours: 1),
      status: DuoNapPlanStatus.done,
    );

    final result = await service.find(row);

    final logged = (result as DuoNapSuccess<DuoNapLoggedSleep>).data;
    expect(logged.sessions[DuoNapBabyId.first]?.id, 'first-1');
    expect(logged.sessions[DuoNapBabyId.second]?.id, 'second-1');
  });
}
