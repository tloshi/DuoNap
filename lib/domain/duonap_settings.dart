import 'duonap_baby.dart';

/// What the family sets by hand: the babies' names and the two anchor times.
class DuoNapSettings {
  const DuoNapSettings({
    required this.firstName,
    required this.secondName,
    required this.plannedBedtimeMinutes,
    required this.usualWakeMinutes,
  });

  static const int maxNameLength = 24;
  static const int defaultBedtimeMinutes = 21 * 60 + 15;
  static const int defaultWakeMinutes = 8 * 60;

  /// Used until the family saves their own settings.
  static const DuoNapSettings defaults = DuoNapSettings(
    firstName: 'Elena',
    secondName: 'Diana',
    plannedBedtimeMinutes: defaultBedtimeMinutes,
    usualWakeMinutes: defaultWakeMinutes,
  );

  final String firstName;
  final String secondName;

  /// Minutes after midnight. The bedtime the plan aims for.
  final int plannedBedtimeMinutes;

  /// Minutes after midnight. Anchors the day until the wake-up is logged.
  final int usualWakeMinutes;

  List<DuoNapBaby> get babies => [baby(DuoNapBabyId.first), baby(DuoNapBabyId.second)];

  DuoNapBaby baby(DuoNapBabyId id) {
    final name = id == DuoNapBabyId.first ? firstName : secondName;
    return DuoNapBaby(id: id, name: name);
  }

  DuoNapSettings withName(DuoNapBabyId id, String name) {
    return DuoNapSettings(
      firstName: id == DuoNapBabyId.first ? name : firstName,
      secondName: id == DuoNapBabyId.second ? name : secondName,
      plannedBedtimeMinutes: plannedBedtimeMinutes,
      usualWakeMinutes: usualWakeMinutes,
    );
  }

  DuoNapSettings withBedtime(int minutes) {
    return DuoNapSettings(
      firstName: firstName,
      secondName: secondName,
      plannedBedtimeMinutes: minutes,
      usualWakeMinutes: usualWakeMinutes,
    );
  }

  DuoNapSettings withWake(int minutes) {
    return DuoNapSettings(
      firstName: firstName,
      secondName: secondName,
      plannedBedtimeMinutes: plannedBedtimeMinutes,
      usualWakeMinutes: minutes,
    );
  }
}
