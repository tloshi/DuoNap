import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_logged_sleep.dart';
import '../../domain/duonap_plan_item.dart';
import '../../domain/duonap_sleep_session.dart';
import '../common/duonap_error_text.dart';
import '../today/duonap_today_view_model.dart';
import 'duonap_sleep_edit_state.dart';

final duoNapSleepEditViewModelProvider =
    NotifierProvider<DuoNapSleepEditViewModel, DuoNapSleepEditState>(
  DuoNapSleepEditViewModel.new,
);

/// Holds the edit sheet and turns its taps into service calls.
class DuoNapSleepEditViewModel extends Notifier<DuoNapSleepEditState> {
  @override
  DuoNapSleepEditState build() => const DuoNapSleepEditState();

  /// Loads what is logged behind [item]. False when there is nothing to open:
  /// a nap or night with no logged sleep, or the log could not be read.
  Future<bool> open(DuoNapPlanItem item) async {
    final result = await ref.read(duoNapSleepEditServiceProvider).find(item);
    if (result is! DuoNapSuccess<DuoNapLoggedSleep>) return false;
    final logged = result.data;
    final isWake = item.kind == DuoNapPlanKind.wake;
    if (logged.isEmpty && !isWake) return false;
    state = DuoNapSleepEditState(logged: logged, start: _suggestedWake(item));
    final firstWakeOfDay = isWake && logged.isEmpty;
    select(firstWakeOfDay ? DuoNapEditTarget.both : state.targets.first);
    return true;
  }

  void select(DuoNapEditTarget target) {
    final session = _sessionFor(target);
    if (state.isWake) {
      state = state.withTarget(target, session?.end ?? state.start, null);
      return;
    }
    if (session == null) return;
    state = state.withTarget(target, session.start, session.end);
  }

  void nudgeStart(int minutes) {
    final start = state.start;
    if (start == null) return;
    state = state.withTimes(start.add(Duration(minutes: minutes)), state.end);
  }

  void nudgeEnd(int minutes) {
    final end = state.end;
    if (end == null) return;
    state = state.withTimes(state.start, end.add(Duration(minutes: minutes)));
  }

  /// True when saved; the sheet then closes.
  Future<bool> save() async {
    final start = state.start;
    if (start == null) return false;
    final service = ref.read(duoNapSleepEditServiceProvider);
    state = state.withBusy();
    final result = state.isWake
        ? await service.logWake(_babiesOf(state.target), start)
        : await service.retime(
            state.selectedSessions,
            DuoNapSleepTimes(start: start, end: state.end),
          );
    return _finish(result);
  }

  /// True when deleted; the sheet then closes.
  Future<bool> delete() async {
    final service = ref.read(duoNapSleepEditServiceProvider);
    state = state.withBusy();
    return _finish(await service.delete(state.selectedSessions));
  }

  Future<bool> _finish(DuoNapResult<void> result) async {
    if (result is DuoNapFailure<void>) {
      state = state.withError(duoNapErrorText(result.code));
      return false;
    }
    await ref.read(duoNapTodayViewModelProvider.notifier).refresh();
    return true;
  }

  /// The session whose times the sheet shows. For both babies, the first's.
  DuoNapSleepSession? _sessionFor(DuoNapEditTarget target) {
    final baby = DuoNapSleepEditState.babyOf(target) ?? DuoNapBabyId.first;
    return state.logged?.sessions[baby];
  }

  Set<DuoNapBabyId> _babiesOf(DuoNapEditTarget target) {
    final baby = DuoNapSleepEditState.babyOf(target);
    return baby == null ? DuoNapBabyId.values.toSet() : {baby};
  }

  /// The planned wake time, or now if that is still ahead, to the minute.
  DateTime _suggestedWake(DuoNapPlanItem item) {
    final now = DateTime.now();
    final pick = item.start.isAfter(now) ? now : item.start;
    return DateTime(pick.year, pick.month, pick.day, pick.hour, pick.minute);
  }
}
