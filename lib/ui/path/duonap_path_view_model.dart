import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_settings.dart';
import '../../domain/duonap_shift.dart';
import '../common/duonap_error_text.dart';
import '../today/duonap_today_view_model.dart';
import 'duonap_path_state.dart';

/// Disposed when the screen closes, so it reloads every time it opens.
final duoNapPathViewModelProvider =
    NotifierProvider.autoDispose<DuoNapPathViewModel, DuoNapPathState>(
  DuoNapPathViewModel.new,
);

/// Holds the Rruga screen and turns its taps into shift service calls.
class DuoNapPathViewModel extends AutoDisposeNotifier<DuoNapPathState> {
  @override
  DuoNapPathState build() {
    unawaited(Future<void>.microtask(_load));
    return const DuoNapPathState();
  }

  Future<void> start() => _change(() => ref.read(duoNapShiftServiceProvider).start());

  Future<void> stop() => _change(() => ref.read(duoNapShiftServiceProvider).stop());

  Future<void> setTarget(int minutes) {
    return _change(() => ref.read(duoNapShiftServiceProvider).setTarget(minutes));
  }

  /// Kept alive until done: the screen may close while the action runs.
  Future<void> _change(Future<DuoNapResult<void>> Function() action) async {
    final link = ref.keepAlive();
    try {
      state = state.withBusy();
      final result = await action();
      if (result is DuoNapFailure<void>) {
        state = state.withError(duoNapErrorText(result.code));
        return;
      }
      await _load();
      await ref.read(duoNapTodayViewModelProvider.notifier).refresh();
    } finally {
      link.close();
    }
  }

  Future<void> _load() async {
    final link = ref.keepAlive();
    try {
      final settings = await ref.read(duoNapSettingsServiceProvider).load();
      final status = await ref.read(duoNapShiftServiceProvider).status();
      state = _loaded(settings, status);
    } finally {
      link.close();
    }
  }

  DuoNapPathState _loaded(
    DuoNapResult<DuoNapSettings> settings,
    DuoNapResult<DuoNapShiftStatus?> status,
  ) {
    if (settings is! DuoNapSuccess<DuoNapSettings>) {
      return state.withError(duoNapErrorText('LOAD_FAILED'));
    }
    return status.fold<DuoNapPathState>(
      (failure) => state.withError(duoNapErrorText(failure.code)),
      (DuoNapShiftStatus? value) => state.withLoaded(value, settings.data.anchors),
    );
  }
}
