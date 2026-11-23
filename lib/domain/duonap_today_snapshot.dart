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
    required this.babies,
    required this.statuses,
    required this.plan,
    required this.babyPlans,
    required this.isNight,
    required this.nextWake,
  });

  final DateTime now;

  /// Both babies with the names from settings, first baby first.
  final List<DuoNapBaby> babies;

  /// True between logged night sleep and 05:00. The night view is shown then.
  final bool isNight;

  /// The next usual morning wake-up from settings, for the night view.
  final DateTime nextWake;
  final Map<DuoNapBabyId, DuoNapBabyStatus> statuses;

  /// The shared plan for both babies.
  final List<DuoNapPlanItem> plan;

  /// Each baby's own plan, used to draw the two rings.
  final Map<DuoNapBabyId, List<DuoNapPlanItem>> babyPlans;

  bool get bothAsleep => statuses.values.every((status) => status.asleep);

  DuoNapBaby baby(DuoNapBabyId id) => babies.firstWhere((b) => b.id == id);
}
