import '../../domain/duonap_settings.dart';

/// The settings screen: the draft being edited, null until it has loaded.
class DuoNapSettingsState {
  const DuoNapSettingsState({
    this.draft,
    this.pathRunning = false,
    this.busy = false,
    this.error,
  });

  final DuoNapSettings? draft;

  /// While the path toward 19:00 – 07:00 runs, it sets the two times.
  final bool pathRunning;
  final bool busy;
  final String? error;

  DuoNapSettingsState withDraft(DuoNapSettings value) {
    return DuoNapSettingsState(draft: value, pathRunning: pathRunning);
  }

  DuoNapSettingsState withPathRunning(bool value) {
    return DuoNapSettingsState(draft: draft, pathRunning: value);
  }

  DuoNapSettingsState withBusy() {
    return DuoNapSettingsState(draft: draft, pathRunning: pathRunning, busy: true);
  }

  DuoNapSettingsState withError(String message) {
    return DuoNapSettingsState(draft: draft, pathRunning: pathRunning, error: message);
  }
}
