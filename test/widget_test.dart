import 'package:duonap/ui/today/duonap_today_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

// Kept under this name so `flutter create .` does not add its own counter test.
void main() {
  test('durations read the way the screen shows them', () {
    expect(DuoNapFormat.duration(const Duration(minutes: 21)), '21 min');
    expect(DuoNapFormat.duration(const Duration(minutes: 120)), '2 h');
    expect(DuoNapFormat.duration(const Duration(minutes: 85)), '1 h 25 min');
  });

  test('clock times are zero padded', () {
    expect(DuoNapFormat.clock(DateTime(2026, 1, 1, 7, 5)), '07:05');
  });
}
