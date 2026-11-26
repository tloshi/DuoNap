import 'package:cloud_firestore/cloud_firestore.dart';

import 'duonap_cloud.dart';
import 'duonap_sleep_session_dto.dart';

/// The family's sleep log in Firestore: `families/{familyId}/sessions`.
class DuoNapFirestoreSessions implements DuoNapCloudSessions {
  DuoNapFirestoreSessions(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _sessions(String familyId) {
    return _db.collection('families').doc(familyId).collection('sessions');
  }

  /// Leaves out this phone's own writes that the server has not confirmed yet.
  @override
  Stream<List<DuoNapRemoteSessionChange>> watch(String familyId) {
    return _sessions(familyId).snapshots().map(
          (snapshot) => [
            for (final change in snapshot.docChanges)
              if (!change.doc.metadata.hasPendingWrites) _changeOf(change),
          ],
        );
  }

  @override
  Future<void> put(String familyId, DuoNapSleepSessionDto dto) {
    return _sessions(familyId).doc(dto.id).set(dto.toCloud());
  }

  @override
  Future<void> remove(String familyId, String id) {
    return _sessions(familyId).doc(id).delete();
  }

  DuoNapRemoteSessionChange _changeOf(DocumentChange<Map<String, dynamic>> change) {
    final data = change.doc.data();
    final id = change.doc.id;
    if (change.type == DocumentChangeType.removed || data == null) {
      return DuoNapRemoteSessionChange(id: id);
    }
    return DuoNapRemoteSessionChange(id: id, dto: DuoNapSleepSessionDto.fromCloud(id, data));
  }
}
