import '../core/duonap_base.dart';
import '../domain/duonap_baby.dart';
import '../domain/duonap_sleep_session.dart';

/// Storage shape of a sleep session. Never leaves the data layer.
/// [updatedAtMs] decides which phone's copy wins; records saved before sync
/// existed have 0.
class DuoNapSleepSessionDto implements DuoNapBaseDto<DuoNapSleepSession> {
  const DuoNapSleepSessionDto({
    required this.id,
    required this.baby,
    required this.kind,
    required this.startMs,
    this.endMs,
    this.updatedAtMs = 0,
    this.updatedBy,
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
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  /// Firestore shape: the id is the document id and the baby is `babyId`.
  factory DuoNapSleepSessionDto.fromCloud(String id, Map<String, dynamic> data) {
    return DuoNapSleepSessionDto(
      id: id,
      baby: data['babyId'] as String,
      kind: data['kind'] as String,
      startMs: data['startMs'] as int,
      endMs: data['endMs'] as int?,
      updatedAtMs: data['updatedAtMs'] as int? ?? 0,
      updatedBy: data['updatedBy'] as String?,
    );
  }

  final String id;
  final String baby;
  final String kind;
  final int startMs;
  final int? endMs;
  final int updatedAtMs;
  final String? updatedBy;

  DuoNapSleepSessionDto stamped(int atMs, String? by) {
    return DuoNapSleepSessionDto(
      id: id,
      baby: baby,
      kind: kind,
      startMs: startMs,
      endMs: endMs,
      updatedAtMs: atMs,
      updatedBy: by,
    );
  }

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
      'updatedAtMs': updatedAtMs,
      'updatedBy': updatedBy,
    };
  }

  /// The session document under `families/{id}/sessions/{sessionId}`.
  Map<String, dynamic> toCloud() {
    return <String, dynamic>{
      'babyId': baby,
      'kind': kind,
      'startMs': startMs,
      'endMs': endMs,
      'updatedAtMs': updatedAtMs,
      'updatedBy': updatedBy,
    };
  }
}
