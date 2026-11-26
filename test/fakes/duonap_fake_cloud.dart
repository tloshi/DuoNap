import 'dart:async';

import 'package:duonap/data/duonap_cloud.dart';
import 'package:duonap/data/duonap_family_dto.dart';
import 'package:duonap/data/duonap_settings_dto.dart';
import 'package:duonap/data/duonap_shift_dto.dart';
import 'package:duonap/data/duonap_sleep_session_dto.dart';

/// The family's log "in the cloud", in memory. Tests push the other phone's
/// changes through [incoming].
class DuoNapFakeCloudSessions implements DuoNapCloudSessions {
  final StreamController<List<DuoNapRemoteSessionChange>> incoming =
      StreamController<List<DuoNapRemoteSessionChange>>.broadcast();
  final Map<String, DuoNapSleepSessionDto> stored = {};

  @override
  Stream<List<DuoNapRemoteSessionChange>> watch(String familyId) => incoming.stream;

  @override
  Future<void> put(String familyId, DuoNapSleepSessionDto dto) async {
    stored[dto.id] = dto;
  }

  @override
  Future<void> remove(String familyId, String id) async {
    stored.remove(id);
  }
}

/// Families and join codes in memory. [offline] makes every call time out.
class DuoNapFakeCloudFamily implements DuoNapCloudFamily {
  static const String familyId = 'family-1';

  final StreamController<DuoNapFamilyDto> incoming = StreamController<DuoNapFamilyDto>.broadcast();
  final Map<String, String> codes = {};
  final List<String> joins = [];
  String uid = 'uid-a';
  bool offline = false;
  DuoNapFamilyDto? created;
  DuoNapSettingsDto? writtenSettings;

  @override
  Future<String> signIn() async {
    if (offline) throw TimeoutException('offline');
    return uid;
  }

  @override
  Future<String> create(DuoNapFamilyDto family) async {
    created = family;
    codes[family.joinCode] = familyId;
    return familyId;
  }

  @override
  Future<String?> familyIdForCode(String code) async => codes[code];

  @override
  Future<void> join(String familyId, String uid, String code) async {
    joins.add('$familyId/$uid/$code');
  }

  @override
  Future<void> renewCode(String familyId, String code, int expiresAtMs) async {
    codes[code] = familyId;
  }

  @override
  Stream<DuoNapFamilyDto> watch(String familyId) => incoming.stream;

  @override
  Future<void> writeSettings(String familyId, DuoNapSettingsDto settings) async {
    writtenSettings = settings;
  }

  @override
  Future<void> writeShift(String familyId, DuoNapShiftDto? shift) async {}
}
