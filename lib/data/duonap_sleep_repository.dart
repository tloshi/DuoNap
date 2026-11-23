import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../domain/duonap_sleep_session.dart';
import 'duonap_sleep_session_dto.dart';

abstract interface class DuoNapSleepRepository
    implements DuoNapBaseRepository<DuoNapSleepSession> {}

/// On-device storage. One JSON string per session, keyed by session id.
class DuoNapHiveSleepRepository implements DuoNapSleepRepository {
  DuoNapHiveSleepRepository(this._box);

  static const String boxName = 'duonap_sleep_sessions';

  final Box<String> _box;

  @override
  Future<DuoNapResult<List<DuoNapSleepSession>>> loadSince(DateTime from) async {
    try {
      final sessions = _box.values
          .map(_decode)
          .where((session) => !session.start.isBefore(from))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      return DuoNapSuccess<List<DuoNapSleepSession>>(sessions);
    } on Object catch (error) {
      return DuoNapFailure<List<DuoNapSleepSession>>(
        'LOAD_FAILED',
        error.toString(),
      );
    }
  }

  @override
  Future<DuoNapResult<void>> save(DuoNapSleepSession item) async {
    try {
      final dto = DuoNapSleepSessionDto.fromDomain(item);
      await _box.put(item.id, jsonEncode(dto.toJson()));
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

  DuoNapSleepSession _decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DuoNapSleepSessionDto.fromJson(json).toDomain();
  }
}
