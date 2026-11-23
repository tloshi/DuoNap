import '../../domain/duonap_today_snapshot.dart';

class DuoNapTodayState {
  const DuoNapTodayState({this.loading = true, this.snapshot, this.error});

  final bool loading;
  final DuoNapTodaySnapshot? snapshot;
  final String? error;

  DuoNapTodayState withError(String message) {
    return DuoNapTodayState(loading: false, snapshot: snapshot, error: message);
  }

  DuoNapTodayState withSnapshot(DuoNapTodaySnapshot value) {
    return DuoNapTodayState(loading: false, snapshot: value);
  }
}
