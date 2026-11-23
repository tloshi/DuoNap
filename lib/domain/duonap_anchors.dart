/// A day's two anchor times, in minutes after midnight: the usual morning
/// wake-up and the planned bedtime.
class DuoNapAnchors {
  const DuoNapAnchors({required this.wakeMinutes, required this.bedtimeMinutes});

  final int wakeMinutes;
  final int bedtimeMinutes;

  DuoNapAnchors withBedtime(int minutes) {
    return DuoNapAnchors(wakeMinutes: wakeMinutes, bedtimeMinutes: minutes);
  }
}
