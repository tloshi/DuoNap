import '../domain/duonap_baby.dart';
import '../domain/duonap_plan_item.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_sleep_profile.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_day_history.dart';
import 'duonap_plan_engine.dart';
import 'duonap_profile_learner.dart';
import 'duonap_twin_plan_merger.dart';

/// Builds what the Today screen shows from the log, the settings and the time.
/// Pure: same input, same snapshot.
class DuoNapTodayBuilder {
  const DuoNapTodayBuilder();

  final DuoNapPlanEngine _engine = const DuoNapPlanEngine();
  final DuoNapTwinPlanMerger _merger = const DuoNapTwinPlanMerger();
  final DuoNapProfileLearner _learner = const DuoNapProfileLearner();
  final DuoNapDayHistory _history = const DuoNapDayHistory();

  DuoNapTodaySnapshot build(
    List<DuoNapSleepSession> sessions,
    DuoNapSettings settings,
    DateTime now,
  ) {
    final statuses = <DuoNapBabyId, DuoNapBabyStatus>{};
    final babyPlans = <DuoNapBabyId, List<DuoNapPlanItem>>{};
    for (final baby in DuoNapBabyId.values) {
      final own = sessions.where((s) => s.babyId == baby).toList();
      statuses[baby] = _history.statusOf(own);
      babyPlans[baby] = _planFor(own, settings, now);
    }
    final plan = _merger.merge(
      babyPlans[DuoNapBabyId.first] ?? const [],
      babyPlans[DuoNapBabyId.second] ?? const [],
    );
    return DuoNapTodaySnapshot(
      now: now,
      babies: settings.babies,
      statuses: statuses,
      plan: plan,
      babyPlans: babyPlans,
      isNight: _isNight(plan, now),
      nextWake: _nextWake(settings, now),
    );
  }

  List<DuoNapPlanItem> _planFor(
    List<DuoNapSleepSession> own,
    DuoNapSettings settings,
    DateTime now,
  ) {
    final base = DuoNapSleepProfile.starter.anchoredTo(settings);
    final profile = _learner.learn(base, _history.pastDays(own, now));
    final input = DuoNapPlanInput(
      now: now,
      profile: profile,
      naps: _history.napsOn(own, now),
      wakeTime: _history.wakeOn(own, now),
      nightStart: _history.nightStartOn(own, now),
    );
    return _engine.build(input);
  }

  /// Night once tonight's sleep is logged, and anyway until dawn.
  bool _isNight(List<DuoNapPlanItem> plan, DateTime now) {
    if (now.hour < DuoNapDayHistory.earliestWakeHour) return true;
    if (plan.isEmpty) return false;
    final last = plan.last;
    return last.kind == DuoNapPlanKind.night && last.status == DuoNapPlanStatus.done;
  }

  DateTime _nextWake(DuoNapSettings settings, DateTime now) {
    final minutes = settings.usualWakeMinutes;
    final today = DateTime(now.year, now.month, now.day, 0, minutes);
    if (now.isBefore(today)) return today;
    return DateTime(now.year, now.month, now.day + 1, 0, minutes);
  }
}
