import '../domain/duonap_sleep_profile.dart';
import '../domain/duonap_sleep_session.dart';

/// One finished day for one baby: the morning wake-up and that day's naps in order.
class DuoNapDayRecord {
  const DuoNapDayRecord({required this.wake, required this.naps});

  final DateTime wake;
  final List<DuoNapSleepSession> naps;
}

/// Replaces the starter numbers with the baby's own medians, per nap position.
///
/// The median ignores a single odd day. A position keeps its starter value
/// until it has at least [_minSamples] logged days.
class DuoNapProfileLearner {
  const DuoNapProfileLearner();

  static const int _minSamples = 3;

  DuoNapSleepProfile learn(DuoNapSleepProfile base, List<DuoNapDayRecord> days) {
    final windows = <Duration>[];
    final lengths = <Duration>[];
    for (var i = 0; i < base.napCount; i++) {
      windows.add(_medianOr(base.wakeWindows[i], _windowSamples(days, i)));
      lengths.add(_medianOr(base.napLengths[i], _lengthSamples(days, i)));
    }
    return base.copyWith(wakeWindows: windows, napLengths: lengths);
  }

  List<Duration> _windowSamples(List<DuoNapDayRecord> days, int position) {
    final samples = <Duration>[];
    for (final day in days) {
      if (day.naps.length <= position) continue;
      final previousEnd = position == 0 ? day.wake : day.naps[position - 1].end;
      if (previousEnd == null) continue;
      samples.add(day.naps[position].start.difference(previousEnd));
    }
    return samples;
  }

  List<Duration> _lengthSamples(List<DuoNapDayRecord> days, int position) {
    final samples = <Duration>[];
    for (final day in days) {
      if (day.naps.length <= position) continue;
      final nap = day.naps[position];
      final end = nap.end;
      if (end == null) continue;
      samples.add(end.difference(nap.start));
    }
    return samples;
  }

  Duration _medianOr(Duration fallback, List<Duration> samples) {
    if (samples.length < _minSamples) return fallback;
    final sorted = [...samples]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    final sum = sorted[middle - 1].inMicroseconds + sorted[middle].inMicroseconds;
    return Duration(microseconds: sum ~/ 2);
  }
}
