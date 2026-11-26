import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/duonap_providers.dart';
import '../../core/duonap_result.dart';
import '../../domain/duonap_family.dart';
import '../common/duonap_error_text.dart';
import '../today/duonap_today_view_model.dart';
import 'duonap_family_state.dart';

/// Disposed when settings close, so the card reloads every time it opens.
final duoNapFamilyViewModelProvider =
    NotifierProvider.autoDispose<DuoNapFamilyViewModel, DuoNapFamilyState>(
  DuoNapFamilyViewModel.new,
);

/// Creates or joins the family, and shows the code for the other phone.
class DuoNapFamilyViewModel extends AutoDisposeNotifier<DuoNapFamilyState> {
  @override
  DuoNapFamilyState build() {
    final changes = ref.read(duoNapFamilyServiceProvider).remoteChanges.listen((_) => _load());
    ref.onDispose(changes.cancel);
    unawaited(Future<void>.microtask(_load));
    return const DuoNapFamilyState();
  }

  void setCode(String value) => state = state.withCode(value);

  Future<void> create() => _change(() => ref.read(duoNapFamilyServiceProvider).create());

  Future<void> join() {
    final code = state.code;
    return _change(() => ref.read(duoNapFamilyServiceProvider).join(code));
  }

  Future<void> renewCode() => _change(() => ref.read(duoNapFamilyServiceProvider).renewCode());

  /// Kept alive until done: settings may close while the network works.
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
    final result = await ref.read(duoNapFamilyServiceProvider).status();
    state = result.fold<DuoNapFamilyState>(
      (failure) => state.withError(duoNapErrorText(failure.code)),
      (DuoNapFamilyStatus status) => state.withStatus(status),
    );
  }
}
