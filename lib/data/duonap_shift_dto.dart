import '../core/duonap_base.dart';
import '../domain/duonap_anchors.dart';
import '../domain/duonap_shift.dart';

/// Storage shape of the path setup. Never leaves the data layer.
/// The start day is an ISO date ("2026-11-24"), read back as local midnight.
class DuoNapShiftDto implements DuoNapBaseDto<DuoNapShiftSetup> {
  const DuoNapShiftDto({
    required this.startDay,
    required this.startWakeMinutes,
    required this.startBedtimeMinutes,
    required this.targetBedtimeMinutes,
  });

  factory DuoNapShiftDto.fromDomain(DuoNapShiftSetup setup) {
    final day = setup.startDay;
    return DuoNapShiftDto(
      startDay: '${day.year}-${_two(day.month)}-${_two(day.day)}',
      startWakeMinutes: setup.start.wakeMinutes,
      startBedtimeMinutes: setup.start.bedtimeMinutes,
      targetBedtimeMinutes: setup.targetBedtimeMinutes,
    );
  }

  factory DuoNapShiftDto.fromJson(Map<String, dynamic> json) {
    return DuoNapShiftDto(
      startDay: json['startDay'] as String,
      startWakeMinutes: json['startWakeMinutes'] as int,
      startBedtimeMinutes: json['startBedtimeMinutes'] as int,
      targetBedtimeMinutes: json['targetBedtimeMinutes'] as int,
    );
  }

  final String startDay;
  final int startWakeMinutes;
  final int startBedtimeMinutes;
  final int targetBedtimeMinutes;

  @override
  DuoNapShiftSetup toDomain() {
    return DuoNapShiftSetup(
      startDay: DateTime.parse(startDay),
      start: DuoNapAnchors(
        wakeMinutes: startWakeMinutes,
        bedtimeMinutes: startBedtimeMinutes,
      ),
      targetBedtimeMinutes: targetBedtimeMinutes,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startDay': startDay,
      'startWakeMinutes': startWakeMinutes,
      'startBedtimeMinutes': startBedtimeMinutes,
      'targetBedtimeMinutes': targetBedtimeMinutes,
    };
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
