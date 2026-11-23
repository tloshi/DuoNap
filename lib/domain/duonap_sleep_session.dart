import 'duonap_baby.dart';

/// `wake` is a morning wake-up logged by hand when the night before it was not
/// logged. Its start and end are the same moment.
enum DuoNapSleepKind { nap, night, wake }

/// One stretch of sleep for one baby. `end` is null while the baby is still asleep.
class DuoNapSleepSession {
  const DuoNapSleepSession({
    required this.id,
    required this.babyId,
    required this.kind,
    required this.start,
    this.end,
  });

  final String id;
  final DuoNapBabyId babyId;
  final DuoNapSleepKind kind;
  final DateTime start;
  final DateTime? end;

  bool get isOngoing => end == null;

  Duration durationAt(DateTime now) => (end ?? now).difference(start);

  DuoNapSleepSession ended(DateTime at) => retimed(start, at);

  /// Same session, new times. A null [newEnd] means the baby is still asleep.
  DuoNapSleepSession retimed(DateTime newStart, DateTime? newEnd) {
    return DuoNapSleepSession(
      id: id,
      babyId: babyId,
      kind: kind,
      start: newStart,
      end: newEnd,
    );
  }
}
