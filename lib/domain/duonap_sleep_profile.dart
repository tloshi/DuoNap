import 'duonap_settings.dart';

/// The numbers the plan is built from. Starts from [starter] and is replaced
/// by learned values once enough days are logged.
class DuoNapSleepProfile {
  const DuoNapSleepProfile({
    required this.wakeWindows,
    required this.napLengths,
    required this.minLastWindow,
    required this.maxLastWindow,
    required this.maxDaySleep,
    required this.usualWakeMinutes,
    required this.plannedBedtimeMinutes,
  });

  /// Awake time before nap 1, nap 2, ... in order.
  final List<Duration> wakeWindows;

  /// Expected length of nap 1, nap 2, ... in order.
  final List<Duration> napLengths;

  /// Shortest awake time between the last nap and night sleep.
  final Duration minLastWindow;

  /// Longest awake time before night sleep. Past this, night moves earlier.
  final Duration maxLastWindow;

  /// Cap on total daytime sleep, so naps do not push the night later.
  final Duration maxDaySleep;

  /// Minutes after midnight. Used until the morning wake-up is logged.
  final int usualWakeMinutes;

  /// Minutes after midnight. The bedtime the plan aims for.
  final int plannedBedtimeMinutes;

  int get napCount => wakeWindows.length;

  /// Seeded from the family's own logs (late Oct to early Nov 2026).
  static const DuoNapSleepProfile starter = DuoNapSleepProfile(
    wakeWindows: [
      Duration(hours: 1, minutes: 45),
      Duration(hours: 2, minutes: 20),
      Duration(hours: 2, minutes: 15),
    ],
    napLengths: [
      Duration(hours: 1, minutes: 30),
      Duration(hours: 1, minutes: 30),
      Duration(minutes: 30),
    ],
    minLastWindow: Duration(hours: 2, minutes: 20),
    maxLastWindow: Duration(hours: 4),
    maxDaySleep: Duration(hours: 3, minutes: 30),
    usualWakeMinutes: DuoNapSettings.defaultWakeMinutes,
    plannedBedtimeMinutes: DuoNapSettings.defaultBedtimeMinutes,
  );

  /// The same numbers, with the wake time and bedtime the family set.
  DuoNapSleepProfile anchoredTo(DuoNapSettings settings) {
    return DuoNapSleepProfile(
      wakeWindows: wakeWindows,
      napLengths: napLengths,
      minLastWindow: minLastWindow,
      maxLastWindow: maxLastWindow,
      maxDaySleep: maxDaySleep,
      usualWakeMinutes: settings.usualWakeMinutes,
      plannedBedtimeMinutes: settings.plannedBedtimeMinutes,
    );
  }

  DuoNapSleepProfile copyWith({
    List<Duration>? wakeWindows,
    List<Duration>? napLengths,
  }) {
    return DuoNapSleepProfile(
      wakeWindows: wakeWindows ?? this.wakeWindows,
      napLengths: napLengths ?? this.napLengths,
      minLastWindow: minLastWindow,
      maxLastWindow: maxLastWindow,
      maxDaySleep: maxDaySleep,
      usualWakeMinutes: usualWakeMinutes,
      plannedBedtimeMinutes: plannedBedtimeMinutes,
    );
  }
}
