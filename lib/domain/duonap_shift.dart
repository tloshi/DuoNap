import 'duonap_anchors.dart';

/// The path toward 19:00 – 07:00, as started on the Rruga screen.
class DuoNapShiftSetup {
  const DuoNapShiftSetup({
    required this.startDay,
    required this.start,
    required this.targetBedtimeMinutes,
  });

  /// The wake-up stops moving here.
  static const int targetWakeMinutes = 7 * 60;

  /// Three naps a day: 19:30. Two naps: 19:00, chosen by hand for now.
  static const int defaultTargetBedtimeMinutes = 19 * 60 + 30;
  static const List<int> targetChoices = [19 * 60, 19 * 60 + 30, 20 * 60];

  /// Local midnight of the day the path started.
  final DateTime startDay;

  /// The wake-up and bedtime on the start day, taken from settings.
  final DuoNapAnchors start;
  final int targetBedtimeMinutes;

  DuoNapShiftSetup withTarget(int minutes) {
    return DuoNapShiftSetup(
      startDay: startDay,
      start: start,
      targetBedtimeMinutes: minutes,
    );
  }
}

/// One step on the path: from [day] on, the anchors are [anchors].
class DuoNapShiftStep {
  const DuoNapShiftStep({required this.day, required this.anchors});

  final DateTime day;
  final DuoNapAnchors anchors;
}

/// Where the path stands on one day.
class DuoNapShiftStatus {
  const DuoNapShiftStatus({
    required this.setup,
    required this.today,
    required this.stepsDone,
    required this.stepsTotal,
    required this.held,
    required this.upcoming,
  });

  final DuoNapShiftSetup setup;
  final DuoNapAnchors today;
  final int stepsDone;
  final int stepsTotal;

  /// True while the next step waits because two nights in a row began late.
  final bool held;

  /// The steps still to come, if no further step is held.
  final List<DuoNapShiftStep> upcoming;

  bool get finished => stepsDone >= stepsTotal;

  /// When the last step is expected, or null once the target is reached.
  DateTime? get arrival => upcoming.isEmpty ? null : upcoming.last.day;
}
