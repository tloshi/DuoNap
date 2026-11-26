import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_today_snapshot.dart';
import '../common/duonap_error_text.dart';
import 'duonap_today_state.dart';

final duoNapTodayViewModelProvider =
    NotifierProvider<DuoNapTodayViewModel, DuoNapTodayState>(
  DuoNapTodayViewModel.new,
);

/// Holds the Today screen state and turns taps into service calls.
class DuoNapTodayViewModel extends Notifier<DuoNapTodayState> {
  static const Duration _refreshEvery = Duration(seconds: 30);

  /// Counts refreshes so a slow, older one cannot overwrite a newer result.
  int _generation = 0;

  @override
  DuoNapTodayState build() {
    final timer = Timer.periodic(_refreshEvery, (_) => refresh());
    ref.onDispose(timer.cancel);
    _followFamily();
    unawaited(Future<void>.microtask(refresh));
    return const DuoNapTodayState();
  }

  /// Reconnects to the family at start, refreshes when the other phone
  /// changed something, and says so when a change could not be synced.
  void _followFamily() {
    final family = ref.read(duoNapFamilyServiceProvider);
    final changes = family.remoteChanges.listen((_) => refresh());
    final errors = family.syncErrors.listen((_) => _showError('SYNC_FAILED'));
    ref.onDispose(changes.cancel);
    ref.onDispose(errors.cancel);
    unawaited(_resume());
  }

  Future<void> _resume() async {
    final result = await ref.read(duoNapFamilyServiceProvider).resume();
    if (result is DuoNapFailure<void>) _showError(result.code);
  }

  void _showError(String code) => state = state.withError(duoNapErrorText(code));

  /// The plan depends on the clock, so it is rebuilt on a timer and after each tap.
  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await ref.read(duoNapSleepServiceProvider).loadToday();
    if (generation != _generation) return;
    state = result.fold<DuoNapTodayState>(
      (failure) => state.withError(duoNapErrorText(failure.code)),
      (DuoNapTodaySnapshot snapshot) => state.withSnapshot(snapshot),
    );
  }

  Future<void> onBabyTapped(DuoNapBabyId babyId) {
    return _run(() => ref.read(duoNapSleepServiceProvider).toggle(babyId));
  }

  Future<void> onBothTapped({required bool asleep}) {
    return _run(
      () => ref.read(duoNapSleepServiceProvider).setBoth(asleep: asleep),
    );
  }

  void showDay() => state = state.withDayAtNight(true);

  void showNight() => state = state.withDayAtNight(false);

  Future<void> _run(Future<DuoNapResult<void>> Function() action) async {
    final result = await action();
    if (result is DuoNapFailure<void>) {
      state = state.withError(duoNapErrorText(result.code));
      return;
    }
    await refresh();
  }
}
