import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_sleep_session_dto.dart';

abstract interface class DuoNapSleepRepository
    implements DuoNapBaseRepository<DuoNapSleepSession> {}

/// On-device storage. One JSON string per session, keyed by session id.
/// Every save is stamped with the time, so sync can tell which copy is newer.
class DuoNapHiveSleepRepository implements DuoNapSleepRepository {
  DuoNapHiveSleepRepository(this._box, {DuoNapClock? clock})
      : _clock = clock ?? DateTime.now;

  static const String boxName = 'duonap_sleep_sessions';

  final Box<String> _box;
  final DuoNapClock _clock;

  @override
  Future<DuoNapResult<List<DuoNapSleepSession>>> loadSince(DateTime from) async {
    try {
      final sessions = allDtos()
          .map((dto) => dto.toDomain())
          .where((session) => !session.start.isBefore(from))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      return DuoNapSuccess<List<DuoNapSleepSession>>(sessions);
    } on Object catch (error) {
      return DuoNapFailure<List<DuoNapSleepSession>>('LOAD_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSleepSession item) async {
    try {
      final stamp = _clock().millisecondsSinceEpoch;
      await putDto(DuoNapSleepSessionDto.fromDomain(item).stamped(stamp, null));
      return const DuoNapSuccess<void>(null);
    } on Object catch (error) {
      return DuoNapFailure<void>('SAVE_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> delete(String id) async {
    try {
      await _box.delete(id);
      return const DuoNapSuccess<void>(null);
    } on Object catch (error) {
      return DuoNapFailure<void>('DELETE_FAILED', error.toString());
    }
  }

  // The methods below are for sync inside the data layer. They may throw;
  // the session mirror catches and reports.

  DuoNapSleepSessionDto? dtoOf(String id) {
    final raw = _box.get(id);
    return raw == null ? null : _decode(raw);
  }

  List<DuoNapSleepSessionDto> allDtos() => _box.values.map(_decode).toList();

  /// Stores [dto] as it is, keeping its stamp.
  Future<void> putDto(DuoNapSleepSessionDto dto) {
    return _box.put(dto.id, jsonEncode(dto.toJson()));
  }

  /// True when a session was there to remove.
  Future<bool> removeDto(String id) async {
    final existed = _box.containsKey(id);
    await _box.delete(id);
    return existed;
  }

  /// Empties the log, when this phone joins a family and takes its log.
  Future<void> clearAll() => _box.clear();

  DuoNapSleepSessionDto _decode(String raw) {
    return DuoNapSleepSessionDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
