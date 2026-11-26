import 'duonap_settings_dto.dart';
import 'duonap_shift_dto.dart';

/// The family document in Firestore, as in PLAN.md's data model:
/// members, join code, babies, settings and the running path.
class DuoNapFamilyDto {
  const DuoNapFamilyDto({
    required this.members,
    required this.joinCode,
    required this.joinCodeExpiresAtMs,
    required this.settings,
    this.shift,
    this.updatedAtMs = 0,
  });

  factory DuoNapFamilyDto.fromCloud(Map<String, dynamic> data) {
    final babies = (data['babies'] as List<dynamic>)
        .map((baby) => baby as Map<String, dynamic>)
        .toList();
    final shift = data['shift'] as Map<String, dynamic>?;
    return DuoNapFamilyDto(
      members: (data['members'] as List<dynamic>).map((m) => m as String).toList(),
      joinCode: data['joinCode'] as String,
      joinCodeExpiresAtMs: data['joinCodeExpiresAtMs'] as int,
      settings: _settingsOf(babies, data['settings'] as Map<String, dynamic>),
      shift: shift == null ? null : DuoNapShiftDto.fromJson(shift),
      updatedAtMs: data['updatedAtMs'] as int? ?? 0,
    );
  }

  final List<String> members;
  final String joinCode;
  final int joinCodeExpiresAtMs;
  final DuoNapSettingsDto settings;
  final DuoNapShiftDto? shift;
  final int updatedAtMs;

  Map<String, dynamic> toCloud() {
    return <String, dynamic>{
      'members': members,
      'joinCode': joinCode,
      'joinCodeExpiresAtMs': joinCodeExpiresAtMs,
      ...settingsToCloud(settings),
      'shift': shift?.toJson(),
      'updatedAtMs': updatedAtMs,
    };
  }

  /// The `babies` and `settings` fields of the family document.
  static Map<String, dynamic> settingsToCloud(DuoNapSettingsDto settings) {
    return <String, dynamic>{
      'babies': [
        {'id': 'first', 'name': settings.firstName},
        {'id': 'second', 'name': settings.secondName},
      ],
      'settings': {
        'plannedBedtimeMinutes': settings.bedtimeMinutes,
        'usualWakeMinutes': settings.wakeMinutes,
      },
    };
  }

  static DuoNapSettingsDto _settingsOf(
    List<Map<String, dynamic>> babies,
    Map<String, dynamic> settings,
  ) {
    String nameOf(String id) => babies.firstWhere((baby) => baby['id'] == id)['name'] as String;
    return DuoNapSettingsDto(
      firstName: nameOf('first'),
      secondName: nameOf('second'),
      bedtimeMinutes: settings['plannedBedtimeMinutes'] as int,
      wakeMinutes: settings['usualWakeMinutes'] as int,
    );
  }
}
