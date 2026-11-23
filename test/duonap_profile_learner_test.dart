import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_sleep_profile.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_profile_learner.dart';
import 'package:flutter_test/flutter_test.dart';

DuoNapSleepSession nap(DateTime start, int minutes) {
  return DuoNapSleepSession(
    id: 'nap-${start.millisecondsSinceEpoch}',
    babyId: DuoNapBabyId.first,
    kind: DuoNapSleepKind.nap,
    start: start,
    end: start.add(Duration(minutes: minutes)),
  );
}

/// A day that woke at 08:00, with nap 1 after [window] minutes lasting [length].
DuoNapDayRecord day(int dayOfMonth, int window, int length) {
  final wake = DateTime(2026, 11, dayOfMonth, 8);
  return DuoNapDayRecord(
    wake: wake,
    naps: [nap(wake.add(Duration(minutes: window)), length)],
  );
}

void main() {
  const learner = DuoNapProfileLearner();
  const base = DuoNapSleepProfile.starter;

  test('uses the median of logged days for a nap position', () {
    final learned = learner.learn(base, [
      day(20, 100, 60),
      day(21, 120, 80),
      day(22, 110, 70),
    ]);

    expect(learned.wakeWindows[0], const Duration(minutes: 110));
    expect(learned.napLengths[0], const Duration(minutes: 70));
  });

  test('keeps the starter value until a position has three samples', () {
    final learned = learner.learn(base, [day(20, 100, 60), day(21, 120, 80)]);

    expect(learned.wakeWindows[0], base.wakeWindows[0]);
    expect(learned.napLengths[0], base.napLengths[0]);
  });

  test('positions with no data keep their starter values', () {
    final learned = learner.learn(base, [
      day(20, 100, 60),
      day(21, 120, 80),
      day(22, 110, 70),
    ]);

    expect(learned.wakeWindows[1], base.wakeWindows[1]);
    expect(learned.napLengths[2], base.napLengths[2]);
  });

  test('one odd day does not move the median', () {
    final learned = learner.learn(base, [
      day(19, 100, 60),
      day(20, 105, 65),
      day(21, 110, 70),
      day(22, 300, 10),
    ]);

    expect(learned.wakeWindows[0], const Duration(minutes: 107, seconds: 30));
  });
}
