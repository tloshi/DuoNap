import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_baby.dart';
import '../../domain/duonap_today_snapshot.dart';
import 'duonap_today_state.dart';

final duoNapTodayViewModelProvider =
    NotifierProvider<DuoNapTodayViewModel, DuoNapTodayState>(
  DuoNapTodayViewModel.new,
);

/// Holds the Today screen state and turns taps into service calls.
class DuoNapTodayViewModel extends Notifier<DuoNapTodayState> {
  static const Duration _refreshEvery = Duration(seconds: 30);

  @override
  DuoNapTodayState build() {
    final timer = Timer.periodic(_refreshEvery, (_) => refresh());
    ref.onDispose(timer.cancel);
    Future<void>.microtask(refresh);
    return const DuoNapTodayState();
  }

  /// The plan depends on the clock, so it is rebuilt on a timer and after each tap.
  Future<void> refresh() async {
    final result = await ref.read(duoNapSleepServiceProvider).loadToday();
    state = result.fold<DuoNapTodayState>(
      (failure) => state.withError(failure.message),
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

  Future<void> _run(Future<DuoNapResult<void>> Function() action) async {
    final result = await action();
    if (result is DuoNapFailure<void>) {
      state = state.withError(result.message);
      return;
    }
    await refresh();
  }
}
