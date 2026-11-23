import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:duonap/service/duonap_short_night.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int date, int hour, int minute) => DateTime(2026, 11, date, hour, minute);

/// A night that starts at 21:30 on [evening] and ends next morning at [wake].
DuoNapSleepSession night(int evening, int wakeHour, int wakeMinute) {
  final start = at(evening, 21, 30);
  return DuoNapSleepSession(
    id: 'first-$evening',
    babyId: DuoNapBabyId.first,
    kind: DuoNapSleepKind.night,
    start: start,
    end: at(evening + 1, wakeHour, wakeMinute),
  );
}

/// Seven typical nights of 10 h 30 (21:30 to 08:00), evenings 14 to 20.
List<DuoNapSleepSession> typicalWeek() => [for (var e = 14; e <= 20; e++) night(e, 8, 0)];

void main() {
  const shortNight = DuoNapShortNight();
  final today = at(22, 12, 0);

  test('a night 90 minutes short moves tonight 45 minutes earlier', () {
    final sessions = [...typicalWeek(), night(21, 6, 30)];

    expect(shortNight.earlierBy(sessions, today), const Duration(minutes: 45));
  });

  test('a night 60 minutes short moves tonight by half of it', () {
    final sessions = [...typicalWeek(), night(21, 7, 0)];

    expect(shortNight.earlierBy(sessions, today), const Duration(minutes: 30));
  });

  test('the move is capped at 45 minutes', () {
    final sessions = [...typicalWeek(), night(21, 5, 30)];

    expect(shortNight.earlierBy(sessions, today), const Duration(minutes: 45));
  });

  test('45 minutes short or less changes nothing', () {
    final sessions = [...typicalWeek(), night(21, 7, 15)];

    expect(shortNight.earlierBy(sessions, today), Duration.zero);
  });

  test('without this morning\'s wake-up nothing changes', () {
    final running = DuoNapSleepSession(
      id: 'first-21',
      babyId: DuoNapBabyId.first,
      kind: DuoNapSleepKind.night,
      start: at(21, 21, 30),
    );

    expect(shortNight.earlierBy([...typicalWeek(), running], today), Duration.zero);
  });

  test('fewer than three earlier nights give no typical length', () {
    final sessions = [night(19, 8, 0), night(20, 8, 0), night(21, 6, 0)];

    expect(shortNight.earlierBy(sessions, today), Duration.zero);
  });
}
