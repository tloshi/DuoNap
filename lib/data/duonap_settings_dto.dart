import '../core/duonap_base.dart';
import '../domain/duonap_settings.dart';

/// Storage shape of the family settings. Never leaves the data layer.
class DuoNapSettingsDto implements DuoNapBaseDto<DuoNapSettings> {
  const DuoNapSettingsDto({
    required this.firstName,
    required this.secondName,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
  });

  factory DuoNapSettingsDto.fromDomain(DuoNapSettings settings) {
    return DuoNapSettingsDto(
      firstName: settings.firstName,
      secondName: settings.secondName,
      bedtimeMinutes: settings.plannedBedtimeMinutes,
      wakeMinutes: settings.usualWakeMinutes,
    );
  }

  factory DuoNapSettingsDto.fromJson(Map<String, dynamic> json) {
    return DuoNapSettingsDto(
      firstName: json['firstName'] as String,
      secondName: json['secondName'] as String,
      bedtimeMinutes: json['bedtimeMinutes'] as int,
      wakeMinutes: json['wakeMinutes'] as int,
    );
  }

  final String firstName;
  final String secondName;
  final int bedtimeMinutes;
  final int wakeMinutes;

  @override
  DuoNapSettings toDomain() {
    return DuoNapSettings(
      firstName: firstName,
      secondName: secondName,
      plannedBedtimeMinutes: bedtimeMinutes,
      usualWakeMinutes: wakeMinutes,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'firstName': firstName,
      'secondName': secondName,
      'bedtimeMinutes': bedtimeMinutes,
      'wakeMinutes': wakeMinutes,
    };
  }
}
