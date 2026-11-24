import 'dart:convert';

import 'package:duonap/data/duonap_shift_dto.dart';
import 'package:duonap/domain/duonap_anchors.dart';
import 'package:duonap/domain/duonap_shift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final setup = DuoNapShiftSetup(
    startDay: DateTime(2026, 11, 24),
    start: const DuoNapAnchors(wakeMinutes: 495, bedtimeMinutes: 1305),
    targetBedtimeMinutes: 1170,
  );

  test('the start day is stored as an ISO date', () {
    final json = DuoNapShiftDto.fromDomain(setup).toJson();

    expect(json['startDay'], '2026-11-24');
    expect(json['startWakeMinutes'], 495);
    expect(json['startBedtimeMinutes'], 1305);
    expect(json['targetBedtimeMinutes'], 1170);
  });

  test('a stored setup reads back the same', () {
    final raw = jsonEncode(DuoNapShiftDto.fromDomain(setup).toJson());
    final back = DuoNapShiftDto.fromJson(jsonDecode(raw) as Map<String, dynamic>).toDomain();

    expect(back.startDay, DateTime(2026, 11, 24));
    expect(back.start.wakeMinutes, 495);
    expect(back.start.bedtimeMinutes, 1305);
    expect(back.targetBedtimeMinutes, 1170);
  });
}
