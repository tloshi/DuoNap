import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_logged_sleep.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_sleep_edit_rules.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int day, int hour, int minute) => DateTime(2026, 11, day, hour, minute);

DuoNapSleepSession sleep(DuoNapSleepKind kind, DateTime start, [DateTime? end]) {
  return DuoNapSleepSession(
    id: '${kind.name}-${start.millisecondsSinceEpoch}',
    babyId: DuoNapBabyId.first,
    kind: kind,
    start: start,
    end: end,
  );
}

String? codeOf(DuoNapFailure<void>? failure) => failure?.code;

void main() {
  final rules = DuoNapSleepEditRules(at(24, 23, 0));

  test('rejects a correction with nothing chosen', () {
    final times = DuoNapSleepTimes(start: at(24, 9, 0), end: at(24, 10, 0));

    expect(codeOf(rules.timesProblem(const [], times)), 'NOTHING_SELECTED');
  });

  group('placeProblem', () {
    final nap = sleep(DuoNapSleepKind.nap, at(24, 9, 0), at(24, 10, 0));
    final night = sleep(DuoNapSleepKind.night, at(24, 21, 0));

    test('lets a nap move within its day', () {
      final times = DuoNapSleepTimes(start: at(24, 8, 40), end: at(24, 10, 0));

      expect(rules.placeProblem(nap, times), isNull);
    });

    test('keeps a nap on its own day', () {
      final times = DuoNapSleepTimes(start: at(23, 9, 0), end: at(23, 10, 0));

      expect(codeOf(rules.placeProblem(nap, times)), 'OUT_OF_PLACE');
    });

    test('keeps a nap out of the early morning', () {
      final times = DuoNapSleepTimes(start: at(24, 4, 50), end: at(24, 10, 0));

      expect(codeOf(rules.placeProblem(nap, times)), 'OUT_OF_PLACE');
    });

    test('keeps the start of night sleep in the evening', () {
      final times = DuoNapSleepTimes(start: at(24, 13, 50));

      expect(codeOf(rules.placeProblem(night, times)), 'OUT_OF_PLACE');
    });

    test('lets a night wake-up segment start before dawn', () {
      final segment = sleep(DuoNapSleepKind.night, at(24, 3, 0), at(24, 6, 0));
      final times = DuoNapSleepTimes(start: at(24, 2, 45), end: at(24, 6, 0));

      expect(rules.placeProblem(segment, times), isNull);
    });
  });

  group('overlapProblem', () {
    final other = sleep(DuoNapSleepKind.nap, at(24, 13, 0), at(24, 14, 0));

    test('rejects times that overlap another sleep', () {
      final times = DuoNapSleepTimes(start: at(24, 12, 0), end: at(24, 13, 10));

      expect(codeOf(rules.overlapProblem(times, [other])), 'OVERLAP');
    });

    test('allows times that only touch another sleep', () {
      final times = DuoNapSleepTimes(start: at(24, 12, 0), end: at(24, 13, 0));

      expect(rules.overlapProblem(times, [other]), isNull);
    });

    test('a running sleep overlaps until now', () {
      final running = sleep(DuoNapSleepKind.night, at(24, 21, 0));
      final times = DuoNapSleepTimes(start: at(24, 22, 0), end: at(24, 22, 30));

      expect(codeOf(rules.overlapProblem(times, [running])), 'OVERLAP');
    });

    test('a hand wake-up never counts as overlap', () {
      final mark = sleep(DuoNapSleepKind.wake, at(24, 7, 30), at(24, 7, 30));
      final times = DuoNapSleepTimes(start: at(24, 7, 0), end: at(24, 8, 0));

      expect(rules.overlapProblem(times, [mark]), isNull);
    });
  });

  test('a hand wake-up cannot be in the future', () {
    final early = DuoNapSleepEditRules(at(24, 6, 0));

    expect(codeOf(early.wakeProblem(at(24, 6, 30))), 'IN_FUTURE');
  });
}
