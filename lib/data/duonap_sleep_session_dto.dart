import '../core/duonap_base.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_sleep_session.dart';

/// Storage shape of a sleep session. Never leaves the data layer.
class DuoNapSleepSessionDto implements DuoNapBaseDto<DuoNapSleepSession> {
  const DuoNapSleepSessionDto({
    required this.id,
    required this.baby,
    required this.kind,
    required this.startMs,
    this.endMs,
  });

  factory DuoNapSleepSessionDto.fromDomain(DuoNapSleepSession session) {
    return DuoNapSleepSessionDto(
      id: session.id,
      baby: session.babyId.name,
      kind: session.kind.name,
      startMs: session.start.millisecondsSinceEpoch,
      endMs: session.end?.millisecondsSinceEpoch,
    );
  }

  factory DuoNapSleepSessionDto.fromJson(Map<String, dynamic> json) {
    return DuoNapSleepSessionDto(
      id: json['id'] as String,
      baby: json['baby'] as String,
      kind: json['kind'] as String,
      startMs: json['startMs'] as int,
      endMs: json['endMs'] as int?,
    );
  }

  final String id;
  final String baby;
  final String kind;
  final int startMs;
  final int? endMs;

  @override
  DuoNapSleepSession toDomain() {
    final end = endMs;
    return DuoNapSleepSession(
      id: id,
      babyId: DuoNapBabyId.values.byName(baby),
      kind: DuoNapSleepKind.values.byName(kind),
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: end == null ? null : DateTime.fromMillisecondsSinceEpoch(end),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'baby': baby,
      'kind': kind,
      'startMs': startMs,
      'endMs': endMs,
    };
  }
}
