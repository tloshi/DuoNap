import '../../domain/duonap_family.dart';

/// The family card in settings: link status, the typed code, and progress.
class DuoNapFamilyState {
  const DuoNapFamilyState({
    this.status,
    this.code = '',
    this.busy = false,
    this.error,
  });

  /// Null while loading.
  final DuoNapFamilyStatus? status;

  /// What the parent typed into the code field.
  final String code;
  final bool busy;
  final String? error;

  DuoNapFamilyState withStatus(DuoNapFamilyStatus value) {
    return DuoNapFamilyState(status: value, code: code);
  }

  DuoNapFamilyState withCode(String value) {
    return DuoNapFamilyState(status: status, code: value);
  }

  DuoNapFamilyState withBusy() {
    return DuoNapFamilyState(status: status, code: code, busy: true);
  }

  DuoNapFamilyState withError(String message) {
    return DuoNapFamilyState(status: status, code: code, error: message);
  }
}
