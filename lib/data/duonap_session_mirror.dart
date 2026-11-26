import 'dart:async';

import 'duonap_cloud.dart';
import 'duonap_sleep_repository.dart';
import 'duonap_sleep_session_dto.dart';

/// Keeps the sleep log on this phone and the family's log in the cloud in
/// step. Local reads never wait for the network: changes from the other
/// phone are written into the local log as they arrive.
///
/// Conflicts: last write wins per session, by `updatedAtMs`.
class DuoNapSessionMirror {
  DuoNapSessionMirror({
    required DuoNapHiveSleepRepository local,
    required DuoNapCloudSessions cloud,
  })  : _local = local,
        _cloud = cloud;

  final DuoNapHiveSleepRepository _local;
  final DuoNapCloudSessions _cloud;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  StreamSubscription<List<DuoNapRemoteSessionChange>>? _subscription;
  String? _familyId;
  String? _uid;

  /// Fires after the other phone's changes were written here.
  Stream<void> get changes => _changes.stream;
  Stream<Object> get errors => _errors.stream;

  /// A remote session replaces the local one only when it is newer.
  static bool isNewer(DuoNapSleepSessionDto remote, DuoNapSleepSessionDto? local) {
    return local == null || remote.updatedAtMs > local.updatedAtMs;
  }

  Future<void> start(String familyId, String uid) async {
    await stop();
    _familyId = familyId;
    _uid = uid;
    _subscription = _cloud.watch(familyId).listen(_apply, onError: _errors.add);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _familyId = null;
  }

  /// Sends one local session. A tap never waits for this: offline, the
  /// cloud keeps the write and sends it later.
  void push(String id) {
    final familyId = _familyId;
    final dto = _local.dtoOf(id);
    if (familyId == null || dto == null) return;
    _send(_cloud.put(familyId, dto.stamped(dto.updatedAtMs, _uid)));
  }

  void pushDelete(String id) {
    final familyId = _familyId;
    if (familyId == null) return;
    _send(_cloud.remove(familyId, id));
  }

  /// Sends the whole local log, when this phone creates the family.
  void pushAll() {
    for (final dto in _local.allDtos()) {
      push(dto.id);
    }
  }

  void _send(Future<void> write) {
    unawaited(write.catchError((Object error) => _errors.add(error)));
  }

  Future<void> _apply(List<DuoNapRemoteSessionChange> changes) async {
    try {
      var changed = false;
      for (final change in changes) {
        changed = await _applyOne(change) || changed;
      }
      if (changed) _changes.add(null);
    } on Object catch (error) {
      _errors.add(error);
    }
  }

  Future<bool> _applyOne(DuoNapRemoteSessionChange change) async {
    final remote = change.dto;
    if (remote == null) return _local.removeDto(change.id);
    if (!isNewer(remote, _local.dtoOf(change.id))) return false;
    await _local.putDto(remote);
    return true;
  }
}
