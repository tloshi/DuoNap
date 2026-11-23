import '../../domain/duonap_baby.dart';
import '../../domain/duonap_logged_sleep.dart';
import '../../domain/duonap_plan_item.dart';
import '../../domain/duonap_sleep_session.dart';

/// Who an edit applies to: one baby, or both at once.
enum DuoNapEditTarget { first, second, both }

/// The edit sheet: which logged sleep is open, for whom, and the times shown.
/// For a wake-up, [start] is the wake time and [end] is unused.
class DuoNapSleepEditState {
  const DuoNapSleepEditState({
    this.logged,
    this.target = DuoNapEditTarget.first,
    this.start,
    this.end,
    this.busy = false,
    this.error,
  });

  final DuoNapLoggedSleep? logged;
  final DuoNapEditTarget target;
  final DateTime? start;
  final DateTime? end;
  final bool busy;
  final String? error;

  bool get isWake => logged?.item.kind == DuoNapPlanKind.wake;

  /// The logged sessions the chosen target covers.
  List<DuoNapSleepSession> get selectedSessions {
    final sessions = logged?.sessions ?? const {};
    final baby = babyOf(target);
    if (baby == null) return sessions.values.toList();
    final session = sessions[baby];
    return session == null ? const [] : [session];
  }

  /// A hand wake-up can be deleted. A wake-up that is the end of a logged
  /// night cannot: deleting it would delete the whole night.
  bool get canDelete {
    final selected = selectedSessions;
    if (selected.isEmpty) return false;
    return !isWake || selected.every((s) => s.kind == DuoNapSleepKind.wake);
  }

  /// Targets that can be chosen. Any baby can get a wake-up. For a nap or a
  /// night, only babies with a logged session, and both only when both are
  /// either still asleep or both finished.
  List<DuoNapEditTarget> get targets {
    if (isWake) return DuoNapEditTarget.values;
    final sessions = logged?.sessions ?? const {};
    final first = sessions[DuoNapBabyId.first];
    final second = sessions[DuoNapBabyId.second];
    final bothMatch = first != null && second != null && first.isOngoing == second.isOngoing;
    return [
      if (first != null) DuoNapEditTarget.first,
      if (second != null) DuoNapEditTarget.second,
      if (bothMatch) DuoNapEditTarget.both,
    ];
  }

  static DuoNapBabyId? babyOf(DuoNapEditTarget target) {
    return switch (target) {
      DuoNapEditTarget.first => DuoNapBabyId.first,
      DuoNapEditTarget.second => DuoNapBabyId.second,
      DuoNapEditTarget.both => null,
    };
  }

  DuoNapSleepEditState withTarget(
    DuoNapEditTarget value,
    DateTime? newStart,
    DateTime? newEnd,
  ) {
    return DuoNapSleepEditState(
      logged: logged,
      target: value,
      start: newStart,
      end: newEnd,
    );
  }

  DuoNapSleepEditState withTimes(DateTime? newStart, DateTime? newEnd) {
    return DuoNapSleepEditState(
      logged: logged,
      target: target,
      start: newStart,
      end: newEnd,
    );
  }

  DuoNapSleepEditState withBusy() {
    return DuoNapSleepEditState(
      logged: logged,
      target: target,
      start: start,
      end: end,
      busy: true,
    );
  }

  DuoNapSleepEditState withError(String message) {
    return DuoNapSleepEditState(
      logged: logged,
      target: target,
      start: start,
      end: end,
      error: message,
    );
  }
}
