import '../domain/duonap_sleep_session.dart';
import 'duonap_day_history.dart';
import 'duonap_median.dart';

/// Earlier night after a short night, for one baby. Rules in LOGIC.md:
/// the typical night is the median of the 7 nights before last night; if last
/// night was more than 45 minutes shorter, tonight's bedtime moves earlier by
/// half the shortfall, at most 45 minutes. Naps are never lengthened.
class DuoNapShortNight {
  const DuoNapShortNight();

  static const int _typicalNights = 7;
  static const int _minNights = 3;
  static const Duration _threshold = Duration(minutes: 45);
  static const Duration _maxEarlier = Duration(minutes: 45);

  final DuoNapDayHistory _history = const DuoNapDayHistory();

  /// How much earlier tonight's bedtime is. Zero when nothing applies.
  Duration earlierBy(List<DuoNapSleepSession> own, DateTime today) {
    final last = nightLength(own, today);
    if (last == null) return Duration.zero;
    final typical = duoNapMedian(_previousNights(own, today), _minNights);
    if (typical == null) return Duration.zero;
    final shortfall = typical - last;
    if (shortfall <= _threshold) return Duration.zero;
    final half = Duration(minutes: shortfall.inMinutes ~/ 2);
    return half < _maxEarlier ? half : _maxEarlier;
  }

  /// From the night start the evening before [morning] to the wake-up on
  /// [morning]. Night wake-ups in between are not subtracted.
  Duration? nightLength(List<DuoNapSleepSession> own, DateTime morning) {
    final evening = DateTime(morning.year, morning.month, morning.day - 1);
    final start = _history.nightStartOn(own, evening);
    final wake = _history.wakeOn(own, morning);
    if (start == null || wake == null || !wake.isAfter(start)) return null;
    return wake.difference(start);
  }

  List<Duration> _previousNights(List<DuoNapSleepSession> own, DateTime today) {
    final lengths = <Duration>[];
    for (var back = 1; back <= _typicalNights; back++) {
      final morning = DateTime(today.year, today.month, today.day - back);
      final length = nightLength(own, morning);
      if (length != null) lengths.add(length);
    }
    return lengths;
  }
}
