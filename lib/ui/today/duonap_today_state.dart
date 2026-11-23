import '../../domain/duonap_today_snapshot.dart';

class DuoNapTodayState {
  const DuoNapTodayState({
    this.loading = true,
    this.snapshot,
    this.error,
    this.dayAtNight = false,
  });

  final bool loading;
  final DuoNapTodaySnapshot? snapshot;
  final String? error;

  /// The parent chose the day view although it is night. Reset at dawn.
  final bool dayAtNight;

  bool get showNightView => (snapshot?.isNight ?? false) && !dayAtNight;

  DuoNapTodayState withError(String message) {
    return DuoNapTodayState(
      loading: false,
      snapshot: snapshot,
      error: message,
      dayAtNight: dayAtNight,
    );
  }

  DuoNapTodayState withSnapshot(DuoNapTodaySnapshot value) {
    return DuoNapTodayState(
      loading: false,
      snapshot: value,
      dayAtNight: value.isNight && dayAtNight,
    );
  }

  DuoNapTodayState withDayAtNight(bool value) {
    return DuoNapTodayState(
      loading: loading,
      snapshot: snapshot,
      error: error,
      dayAtNight: value,
    );
  }
}
