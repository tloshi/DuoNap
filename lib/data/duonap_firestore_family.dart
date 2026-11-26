import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'duonap_cloud.dart';
import 'duonap_family_dto.dart';
import 'duonap_settings_dto.dart';
import 'duonap_shift_dto.dart';

/// The family document and join codes in Firestore, with anonymous sign-in.
/// Creating and joining need the network; they give up after [_timeout].
class DuoNapFirestoreFamily implements DuoNapCloudFamily {
  DuoNapFirestoreFamily(this._db, this._auth);

  static const Duration _timeout = Duration(seconds: 15);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _families => _db.collection('families');
  CollectionReference<Map<String, dynamic>> get _codes => _db.collection('joinCodes');

  @override
  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth.signInAnonymously().timeout(_timeout);
    final user = credential.user;
    if (user == null) throw StateError('Anonymous sign-in returned no user.');
    return user.uid;
  }

  @override
  Future<String> create(DuoNapFamilyDto family) async {
    final doc = _families.doc();
    final batch = _db.batch()
      ..set(doc, family.toCloud())
      ..set(_codes.doc(family.joinCode), _codeData(doc.id, family.joinCodeExpiresAtMs));
    await batch.commit().timeout(_timeout);
    return doc.id;
  }

  @override
  Future<String?> familyIdForCode(String code) async {
    final snapshot = await _codes
        .doc(code)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final data = snapshot.data();
    if (data == null) return null;
    final expired = (data['expiresAtMs'] as int) <= _now();
    return expired ? null : data['familyId'] as String;
  }

  @override
  Future<void> join(String familyId, String uid, String code) {
    return _families.doc(familyId).update({
      'members': FieldValue.arrayUnion([uid]),
      'joinedWith': code,
    }).timeout(_timeout);
  }

  @override
  Future<void> renewCode(String familyId, String code, int expiresAtMs) {
    final batch = _db.batch()
      ..update(_families.doc(familyId), {
        'joinCode': code,
        'joinCodeExpiresAtMs': expiresAtMs,
        'updatedAtMs': _now(),
      })
      ..set(_codes.doc(code), _codeData(familyId, expiresAtMs));
    return batch.commit().timeout(_timeout);
  }

  /// Leaves out this phone's own writes that the server has not confirmed yet.
  @override
  Stream<DuoNapFamilyDto> watch(String familyId) {
    return _families
        .doc(familyId)
        .snapshots()
        .where((snapshot) => !snapshot.metadata.hasPendingWrites && snapshot.exists)
        .map((snapshot) => DuoNapFamilyDto.fromCloud(snapshot.data() ?? const {}));
  }

  @override
  Future<void> writeSettings(String familyId, DuoNapSettingsDto settings) {
    return _families.doc(familyId).update({
      ...DuoNapFamilyDto.settingsToCloud(settings),
      'updatedAtMs': _now(),
    });
  }

  @override
  Future<void> writeShift(String familyId, DuoNapShiftDto? shift) {
    return _families.doc(familyId).update({'shift': shift?.toJson(), 'updatedAtMs': _now()});
  }

  Map<String, dynamic> _codeData(String familyId, int expiresAtMs) {
    return <String, dynamic>{'familyId': familyId, 'expiresAtMs': expiresAtMs};
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;
}
