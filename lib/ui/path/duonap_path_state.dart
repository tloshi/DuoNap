import '../../domain/duonap_anchors.dart';
import '../../domain/duonap_shift.dart';

/// The Rruga screen: where the path stands, or what it would start from.
class DuoNapPathState {
  const DuoNapPathState({
    this.loading = true,
    this.status,
    this.startFrom,
    this.busy = false,
    this.error,
  });

  final bool loading;

  /// Null when no path is running.
  final DuoNapShiftStatus? status;

  /// The times in settings, which a new path would start from.
  final DuoNapAnchors? startFrom;
  final bool busy;
  final String? error;

  DuoNapPathState withLoaded(DuoNapShiftStatus? value, DuoNapAnchors from) {
    return DuoNapPathState(loading: false, status: value, startFrom: from);
  }

  DuoNapPathState withBusy() {
    return DuoNapPathState(loading: false, status: status, startFrom: startFrom, busy: true);
  }

  DuoNapPathState withError(String message) {
    return DuoNapPathState(
      loading: false,
      status: status,
      startFrom: startFrom,
      error: message,
    );
  }
}
