import 'package:duonap/domain/duonap_plan_item.dart';
import 'package:duonap/service/duonap_twin_plan_merger.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime at(int hour, int minute) => DateTime(2026, 11, 23, hour, minute);

DuoNapPlanItem item(DuoNapPlanKind kind, DateTime start) {
  return DuoNapPlanItem(
    kind: kind,
    index: kind == DuoNapPlanKind.nap ? 3 : 0,
    start: start,
    expected: const Duration(minutes: 30),
    status: DuoNapPlanStatus.upcoming,
  );
}

void main() {
  const merger = DuoNapTwinPlanMerger();

  test('naps close together share the earlier time', () {
    final merged = merger.merge(
      [item(DuoNapPlanKind.nap, at(16, 50))],
      [item(DuoNapPlanKind.nap, at(16, 40))],
    );

    expect(merged.single.start, at(16, 40));
    expect(merged.single.secondStart, isNull);
  });

  test('night sleep close together shares the later time', () {
    final merged = merger.merge(
      [item(DuoNapPlanKind.night, at(21, 15))],
      [item(DuoNapPlanKind.night, at(21, 30))],
    );

    expect(merged.single.start, at(21, 30));
  });

  test('times far apart stay separate', () {
    final merged = merger.merge(
      [item(DuoNapPlanKind.nap, at(16, 40))],
      [item(DuoNapPlanKind.nap, at(17, 10))],
    );

    expect(merged.single.start, at(16, 40));
    expect(merged.single.secondStart, at(17, 10));
  });
}
