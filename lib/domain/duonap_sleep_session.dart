import 'duonap_baby.dart';

enum DuoNapSleepKind { nap, night }

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

  DuoNapSleepSession ended(DateTime at) {
    return DuoNapSleepSession(
      id: id,
      babyId: babyId,
      kind: kind,
      start: start,
      end: at,
    );
  }
}
