import 'dart:async';

import '../core/duonap_result.dart';
import '../domain/duonap_family.dart';
import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import 'duonap_cloud.dart';
import 'duonap_family_dto.dart';
import 'duonap_family_link_store.dart';
import 'duonap_family_mirror.dart';
import 'duonap_session_mirror.dart';
import 'duonap_settings_dto.dart';
import 'duonap_settings_repository.dart';
import 'duonap_shift_dto.dart';
import 'duonap_shift_repository.dart';
import 'duonap_sleep_repository.dart';

abstract interface class DuoNapFamilyRepository {
  /// Fires when the other phone changed something on this phone.
  Stream<void> get remoteChanges;

  /// Fires when sending or receiving a change failed.
  Stream<Object> get syncErrors;

  Future<DuoNapResult<DuoNapFamilyStatus>> status();

  /// Reconnects a linked phone when the app starts. Does nothing otherwise.
  Future<DuoNapResult<void>> resume();

  Future<DuoNapResult<void>> create(DuoNapJoinCode code);

  /// Joins with [code]. This phone's own log is replaced by the family's.
  Future<DuoNapResult<void>> join(String code);

  Future<DuoNapResult<void>> renewCode(DuoNapJoinCode code);
}

/// The local stores that creating and joining read and replace.
class DuoNapLocalStores {
  const DuoNapLocalStores({required this.sleep, required this.settings, required this.shift});

  final DuoNapHiveSleepRepository sleep;
  final DuoNapHiveSettingsRepository settings;
  final DuoNapHiveShiftRepository shift;
}

class DuoNapCloudFamilyRepository implements DuoNapFamilyRepository {
  DuoNapCloudFamilyRepository({
    required DuoNapCloudFamily cloud,
    required DuoNapFamilyLinkStore link,
    required DuoNapSessionMirror sessions,
    required DuoNapFamilyMirror family,
    required DuoNapLocalStores local,
  })  : _cloud = cloud,
        _link = link,
        _sessions = sessions,
        _family = family,
        _local = local {
    _sessions.changes.listen(_changes.add);
    _family.changes.listen(_changes.add);
    _sessions.errors.listen(_errors.add);
    _family.errors.listen(_errors.add);
  }

  final DuoNapCloudFamily _cloud;
  final DuoNapFamilyLinkStore _link;
  final DuoNapSessionMirror _sessions;
  final DuoNapFamilyMirror _family;
  final DuoNapLocalStores _local;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  /// The code made on this phone, shown until the family document arrives.
  DuoNapJoinCode? _ownCode;

  @override
  Stream<void> get remoteChanges => _changes.stream;

  @override
  Stream<Object> get syncErrors => _errors.stream;

  @override
  Future<DuoNapResult<DuoNapFamilyStatus>> status() async {
    try {
      if (_link.familyId == null) {
        return const DuoNapSuccess<DuoNapFamilyStatus>(DuoNapFamilyStatus.unlinked);
      }
      return DuoNapSuccess<DuoNapFamilyStatus>(_linkedStatus());
    } on Object catch (error) {
      return DuoNapFailure<DuoNapFamilyStatus>('LOAD_FAILED', error.toString());
    }
  }

  @override
  Future<DuoNapResult<void>> resume() => _guard(() async {
        final familyId = _link.familyId;
        if (familyId == null) return const DuoNapSuccess<void>(null);
        await _start(familyId, await _cloud.signIn());
        return const DuoNapSuccess<void>(null);
      });

  @override
  Future<DuoNapResult<void>> create(DuoNapJoinCode code) => _guard(() async {
        if (_link.familyId != null) return _alreadyLinked;
        final uid = await _cloud.signIn();
        final familyId = await _cloud.create(await _newFamily(uid, code));
        await _link.save(familyId);
        _ownCode = code;
        await _start(familyId, uid);
        _sessions.pushAll();
        return const DuoNapSuccess<void>(null);
      });

  @override
  Future<DuoNapResult<void>> join(String code) => _guard(() async {
        if (_link.familyId != null) return _alreadyLinked;
        final uid = await _cloud.signIn();
        final familyId = await _cloud.familyIdForCode(code);
        if (familyId == null) {
          return const DuoNapFailure<void>('CODE_UNKNOWN', 'No family has this code.');
        }
        await _cloud.join(familyId, uid, code);
        await _local.sleep.clearAll();
        await _link.save(familyId);
        await _start(familyId, uid);
        return const DuoNapSuccess<void>(null);
      });

  @override
  Future<DuoNapResult<void>> renewCode(DuoNapJoinCode code) => _guard(() async {
        final familyId = _link.familyId;
        if (familyId == null) {
          return const DuoNapFailure<void>('NOT_LINKED', 'This phone has no family.');
        }
        await _cloud.renewCode(familyId, code.code, code.expires.millisecondsSinceEpoch);
        _ownCode = code;
        return const DuoNapSuccess<void>(null);
      });

  static const DuoNapFailure<void> _alreadyLinked =
      DuoNapFailure<void>('ALREADY_LINKED', 'This phone already has a family.');

  DuoNapFamilyStatus _linkedStatus() {
    final latest = _family.latest;
    final ownCode = _ownCode;
    if (latest == null) {
      return DuoNapFamilyStatus(linked: true, joinCode: ownCode?.code, joinCodeExpires: ownCode?.expires);
    }
    return DuoNapFamilyStatus(
      linked: true,
      joinCode: latest.joinCode,
      joinCodeExpires: DateTime.fromMillisecondsSinceEpoch(latest.joinCodeExpiresAtMs),
      members: latest.members.length,
    );
  }

  Future<DuoNapFamilyDto> _newFamily(String uid, DuoNapJoinCode code) async {
    final settings = await _local.settings.load();
    final shift = await _local.shift.load();
    final setup = shift is DuoNapSuccess<DuoNapShiftSetup?> ? shift.data : null;
    return DuoNapFamilyDto(
      members: [uid],
      joinCode: code.code,
      joinCodeExpiresAtMs: code.expires.millisecondsSinceEpoch,
      settings: DuoNapSettingsDto.fromDomain(
        settings is DuoNapSuccess<DuoNapSettings> ? settings.data : DuoNapSettings.defaults,
      ),
      shift: setup == null ? null : DuoNapShiftDto.fromDomain(setup),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _start(String familyId, String uid) async {
    await _sessions.start(familyId, uid);
    await _family.start(familyId);
  }

  /// No network or a refused write become failures, never exceptions.
  Future<DuoNapResult<void>> _guard(Future<DuoNapResult<void>> Function() body) async {
    try {
      return await body();
    } on TimeoutException {
      return const DuoNapFailure<void>('OFFLINE', 'No connection.');
    } on Object catch (error) {
      return DuoNapFailure<void>('SYNC_FAILED', error.toString());
    }
  }
}
