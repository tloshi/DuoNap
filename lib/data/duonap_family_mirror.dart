import 'dart:async';

import '../domain/duonap_settings.dart';
import '../domain/duonap_shift.dart';
import 'duonap_cloud.dart';
import 'duonap_family_dto.dart';
import 'duonap_settings_dto.dart';
import 'duonap_settings_repository.dart';
import 'duonap_shift_dto.dart';
import 'duonap_shift_repository.dart';

/// Keeps the names, the two times and the path on this phone in step with
/// the family document. The last change to arrive wins.
class DuoNapFamilyMirror {
  DuoNapFamilyMirror({
    required DuoNapCloudFamily cloud,
    required DuoNapHiveSettingsRepository settings,
    required DuoNapHiveShiftRepository shift,
  })  : _cloud = cloud,
        _settings = settings,
        _shift = shift;

  final DuoNapCloudFamily _cloud;
  final DuoNapHiveSettingsRepository _settings;
  final DuoNapHiveShiftRepository _shift;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  StreamSubscription<DuoNapFamilyDto>? _subscription;
  String? _familyId;

  /// The family document as last received. Null until it arrives.
  DuoNapFamilyDto? latest;

  Stream<void> get changes => _changes.stream;
  Stream<Object> get errors => _errors.stream;

  Future<void> start(String familyId) async {
    await stop();
    _familyId = familyId;
    _subscription = _cloud.watch(familyId).listen(_apply, onError: _errors.add);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _familyId = null;
  }

  void pushSettings(DuoNapSettings settings) {
    final familyId = _familyId;
    if (familyId == null) return;
    _send(_cloud.writeSettings(familyId, DuoNapSettingsDto.fromDomain(settings)));
  }

  /// A null [shift] means the path was stopped.
  void pushShift(DuoNapShiftSetup? shift) {
    final familyId = _familyId;
    if (familyId == null) return;
    final dto = shift == null ? null : DuoNapShiftDto.fromDomain(shift);
    _send(_cloud.writeShift(familyId, dto));
  }

  void _send(Future<void> write) {
    unawaited(write.catchError((Object error) => _errors.add(error)));
  }

  Future<void> _apply(DuoNapFamilyDto family) async {
    try {
      latest = family;
      await _settings.save(family.settings.toDomain());
      final shift = family.shift;
      await (shift == null ? _shift.clear() : _shift.save(shift.toDomain()));
      _changes.add(null);
    } on Object catch (error) {
      _errors.add(error);
    }
  }
}
