import '../domain/duonap_anchors.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_plan_item.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import '../domain/duonap_sleep_profile.dart';
import '../domain/duonap_sleep_session.dart';
import '../domain/duonap_today_snapshot.dart';
import 'duonap_day_history.dart';
import 'duonap_plan_engine.dart';
import 'duonap_profile_learner.dart';
import 'duonap_shift_plan.dart';
import 'duonap_short_night.dart';
import 'duonap_twin_plan_merger.dart';

/// Everything the plan is built from, loaded together for one moment.
class DuoNapTodayInputs {
  const DuoNapTodayInputs({
    required this.sessions,
    required this.settings,
    this.shift,
  });

  final List<DuoNapSleepSession> sessions;
  final DuoNapSettings settings;

  /// The path toward 19:00 – 07:00, or null when none is running.
  final DuoNapShiftSetup? shift;
}

/// Builds what the Today screen shows from the log, the settings, the path
/// and the time. Pure: same input, same snapshot.
class DuoNapTodayBuilder {
  const DuoNapTodayBuilder();

  final DuoNapPlanEngine _engine = const DuoNapPlanEngine();
  final DuoNapTwinPlanMerger _merger = const DuoNapTwinPlanMerger();
  final DuoNapProfileLearner _learner = const DuoNapProfileLearner();
  final DuoNapDayHistory _history = const DuoNapDayHistory();
  final DuoNapShortNight _shortNight = const DuoNapShortNight();

  DuoNapTodaySnapshot build(DuoNapTodayInputs inputs, DateTime now) {
    final anchors = anchorsOn(inputs, now);
    final statuses = <DuoNapBabyId, DuoNapBabyStatus>{};
    final babyPlans = <DuoNapBabyId, List<DuoNapPlanItem>>{};
    for (final baby in DuoNapBabyId.values) {
      final own = inputs.sessions.where((s) => s.babyId == baby).toList();
      statuses[baby] = _history.statusOf(own);
      babyPlans[baby] = _planFor(own, _adjusted(own, anchors, now), now);
    }
    final plan = _merger.merge(
      babyPlans[DuoNapBabyId.first] ?? const [],
      babyPlans[DuoNapBabyId.second] ?? const [],
    );
    return DuoNapTodaySnapshot(
      now: now,
      babies: inputs.settings.babies,
      statuses: statuses,
      plan: plan,
      babyPlans: babyPlans,
      isNight: _isNight(plan, now),
      nextWake: _nextWake(inputs, now),
    );
  }

  /// The shared wake-up and bedtime for [day]: from the path while it runs,
  /// otherwise from settings.
  DuoNapAnchors anchorsOn(DuoNapTodayInputs inputs, DateTime day) {
    final shift = inputs.shift;
    if (shift == null || day.isBefore(shift.startDay)) return inputs.settings.anchors;
    return DuoNapShiftPlan.fromLog(shift, inputs.sessions).anchorsOn(day);
  }

  /// One baby's anchors for [day]: the shared ones, with tonight's bedtime
  /// moved earlier after that baby's short night. [own] is that baby's log.
  DuoNapAnchors babyAnchorsOn(
    DuoNapTodayInputs inputs,
    List<DuoNapSleepSession> own,
    DateTime day,
  ) {
    return _adjusted(own, anchorsOn(inputs, day), day);
  }

  DuoNapAnchors _adjusted(
    List<DuoNapSleepSession> own,
    DuoNapAnchors shared,
    DateTime now,
  ) {
    final earlier = _shortNight.earlierBy(own, now).inMinutes;
    return shared.withBedtime(shared.bedtimeMinutes - earlier);
  }

  List<DuoNapPlanItem> _planFor(
    List<DuoNapSleepSession> own,
    DuoNapAnchors anchors,
    DateTime now,
  ) {
    final base = DuoNapSleepProfile.starter.anchoredTo(anchors);
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

  DateTime _nextWake(DuoNapTodayInputs inputs, DateTime now) {
    final todayWake = anchorsOn(inputs, now).wakeMinutes;
    final today = DateTime(now.year, now.month, now.day, 0, todayWake);
    if (now.isBefore(today)) return today;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.add(Duration(minutes: anchorsOn(inputs, tomorrow).wakeMinutes));
  }
}
