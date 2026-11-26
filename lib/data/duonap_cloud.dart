import 'duonap_family_dto.dart';
import 'duonap_settings_dto.dart';
import 'duonap_shift_dto.dart';
import 'duonap_sleep_session_dto.dart';

/// One change in the family's log in the cloud. A null [dto] means deleted.
class DuoNapRemoteSessionChange {
  const DuoNapRemoteSessionChange({required this.id, this.dto});

  final String id;
  final DuoNapSleepSessionDto? dto;
}

/// The family's sleep log in the cloud. Implementations may throw; the
/// mirrors and the family repository turn failures into results.
abstract interface class DuoNapCloudSessions {
  /// Changes made by other phones, starting with every existing session.
  Stream<List<DuoNapRemoteSessionChange>> watch(String familyId);

  /// Completes when the cloud has the write. Offline it waits; callers on a
  /// tap must not await it.
  Future<void> put(String familyId, DuoNapSleepSessionDto dto);

  Future<void> remove(String familyId, String id);
}

/// The family document, membership and join codes in the cloud.
abstract interface class DuoNapCloudFamily {
  /// Signs in anonymously when needed and returns this phone's user id.
  Future<String> signIn();

  /// Creates the family and its join code; returns the new family id.
  Future<String> create(DuoNapFamilyDto family);

  /// The family a code belongs to, or null when unknown or expired.
  Future<String?> familyIdForCode(String code);

  Future<void> join(String familyId, String uid, String code);

  Future<void> renewCode(String familyId, String code, int expiresAtMs);

  /// The family document whenever another phone changes it.
  Stream<DuoNapFamilyDto> watch(String familyId);

  Future<void> writeSettings(String familyId, DuoNapSettingsDto settings);

  Future<void> writeShift(String familyId, DuoNapShiftDto? shift);
}
