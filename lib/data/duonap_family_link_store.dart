import 'dart:convert';

import 'package:hive/hive.dart';

/// Which family this phone belongs to, kept on the phone only.
/// One JSON string under its own key in the settings box.
class DuoNapFamilyLinkStore {
  DuoNapFamilyLinkStore(this._box);

  static const String _key = 'family';

  final Box<String> _box;

  /// Null until this phone has created or joined a family. May throw on a
  /// broken record; the family repository catches it.
  String? get familyId {
    final raw = _box.get(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json['familyId'] as String?;
  }

  Future<void> save(String familyId) {
    return _box.put(_key, jsonEncode(<String, dynamic>{'familyId': familyId}));
  }
}
