import '../../domain/duonap_settings.dart';

/// The settings screen: the draft being edited, null until it has loaded.
class DuoNapSettingsState {
  const DuoNapSettingsState({this.draft, this.busy = false, this.error});

  final DuoNapSettings? draft;
  final bool busy;
  final String? error;

  DuoNapSettingsState withDraft(DuoNapSettings value) {
    return DuoNapSettingsState(draft: value);
  }

  DuoNapSettingsState withBusy() {
    return DuoNapSettingsState(draft: draft, busy: true);
  }

  DuoNapSettingsState withError(String message) {
    return DuoNapSettingsState(draft: draft, error: message);
  }
}
