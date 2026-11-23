/// The median of [samples], or null when there are fewer than [minSamples].
/// The median ignores a single odd day, which is why the plan uses it.
Duration? duoNapMedian(List<Duration> samples, int minSamples) {
  if (samples.isEmpty || samples.length < minSamples) return null;
  final sorted = [...samples]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  final sum = sorted[middle - 1].inMicroseconds + sorted[middle].inMicroseconds;
  return Duration(microseconds: sum ~/ 2);
}
