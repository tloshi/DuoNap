import 'duonap_baby.dart';
import 'duonap_plan_item.dart';

class DuoNapBabyStatus {
  const DuoNapBabyStatus({required this.asleep, this.since});

  final bool asleep;

  /// When the current state began. Null when nothing has been logged yet.
  final DateTime? since;
}

/// Everything the Today screen shows, computed for one moment in time.
class DuoNapTodaySnapshot {
  const DuoNapTodaySnapshot({
    required this.now,
    required this.statuses,
    required this.plan,
    required this.babyPlans,
  });

  final DateTime now;
  final Map<DuoNapBabyId, DuoNapBabyStatus> statuses;

  /// The shared plan for both babies.
  final List<DuoNapPlanItem> plan;

  /// Each baby's own plan, used to draw the two rings.
  final Map<DuoNapBabyId, List<DuoNapPlanItem>> babyPlans;

  bool get bothAsleep => statuses.values.every((status) => status.asleep);
}
