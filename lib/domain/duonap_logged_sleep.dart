import 'duonap_baby.dart';
import 'duonap_plan_item.dart';
import 'duonap_sleep_session.dart';

/// New times for a logged sleep. A null [end] means the baby is still asleep.
class DuoNapSleepTimes {
  const DuoNapSleepTimes({required this.start, this.end});

  final DateTime start;
  final DateTime? end;
}

/// The sessions behind one line of the shared plan, at most one per baby.
class DuoNapLoggedSleep {
  const DuoNapLoggedSleep({required this.item, required this.sessions});

  final DuoNapPlanItem item;
  final Map<DuoNapBabyId, DuoNapSleepSession> sessions;

  bool get isEmpty => sessions.isEmpty;
}
