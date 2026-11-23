import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_settings.dart';
import '../../domain/duonap_shift.dart';
import '../common/duonap_error_text.dart';
import '../today/duonap_today_view_model.dart';
import 'duonap_settings_state.dart';

/// Disposed when the screen closes, so it reloads every time it opens.
final duoNapSettingsViewModelProvider =
    NotifierProvider.autoDispose<DuoNapSettingsViewModel, DuoNapSettingsState>(
  DuoNapSettingsViewModel.new,
);

/// Holds the settings draft and saves it through the settings service.
class DuoNapSettingsViewModel extends AutoDisposeNotifier<DuoNapSettingsState> {
  /// One tap on a time stepper moves the time by this many minutes.
  static const int stepMinutes = 15;
  static const int _lastMinuteOfDay = 24 * 60 - 1;

  @override
  DuoNapSettingsState build() {
    unawaited(Future<void>.microtask(_load));
    return const DuoNapSettingsState();
  }

  void setName(DuoNapBabyId id, String name) {
    _update((draft) => draft.withName(id, name));
  }

  void nudgeBedtime(int steps) {
    _update((draft) => draft.withBedtime(_moved(draft.plannedBedtimeMinutes, steps)));
  }

  void nudgeWake(int steps) {
    _update((draft) => draft.withWake(_moved(draft.usualWakeMinutes, steps)));
  }

  /// True when saved; the screen then closes.
  Future<bool> save() async {
    final draft = state.draft;
    if (draft == null) return false;
    state = state.withBusy();
    final result = await ref.read(duoNapSettingsServiceProvider).save(draft);
    if (result is DuoNapFailure<void>) {
      state = state.withError(duoNapErrorText(result.code));
      return false;
    }
    await ref.read(duoNapTodayViewModelProvider.notifier).refresh();
    return true;
  }

  Future<void> _load() async {
    final shift = await ref.read(duoNapShiftServiceProvider).status();
    final running = shift is DuoNapSuccess<DuoNapShiftStatus?> && shift.data != null;
    final result = await ref.read(duoNapSettingsServiceProvider).load();
    state = result.fold<DuoNapSettingsState>(
      (failure) => state.withError(duoNapErrorText(failure.code)),
      (DuoNapSettings settings) => state.withPathRunning(running).withDraft(settings),
    );
  }

  void _update(DuoNapSettings Function(DuoNapSettings draft) change) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.withDraft(change(draft));
  }

  int _moved(int minutes, int steps) {
    final moved = minutes + steps * stepMinutes;
    return moved.clamp(0, _lastMinuteOfDay);
  }
}
