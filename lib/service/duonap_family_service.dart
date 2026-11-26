import 'dart:math';

import '../core/duonap_base.dart';
import '../core/duonap_result.dart';
import '../data/duonap_family_repository.dart';
import '../domain/duonap_family.dart';

/// Links two phones into one family and keeps them in step.
/// Join codes: 6 characters without look-alikes (no 0/O, 1/I), valid 24 h.
class DuoNapFamilyService {
  DuoNapFamilyService({
    required DuoNapFamilyRepository repository,
    DuoNapClock? clock,
    Random? random,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure();

  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int codeLength = 6;
  static const Duration codeLife = Duration(hours: 24);

  final DuoNapFamilyRepository _repository;
  final DuoNapClock _clock;
  final Random _random;

  Stream<void> get remoteChanges => _repository.remoteChanges;

  Stream<Object> get syncErrors => _repository.syncErrors;

  Future<DuoNapResult<DuoNapFamilyStatus>> status() => _repository.status();

  Future<DuoNapResult<void>> resume() => _repository.resume();

  Future<DuoNapResult<void>> create() => _repository.create(newCode());

  Future<DuoNapResult<void>> renewCode() => _repository.renewCode(newCode());

  /// Accepts the code with spaces, dashes or small letters.
  Future<DuoNapResult<void>> join(String input) async {
    final code = normalize(input);
    if (!isValid(code)) {
      return const DuoNapFailure<void>('CODE_INVALID', 'A code has 6 letters or digits.');
    }
    return _repository.join(code);
  }

  DuoNapJoinCode newCode() {
    final code = List.generate(
      codeLength,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    return DuoNapJoinCode(code: code, expires: _clock().add(codeLife));
  }

  static String normalize(String input) {
    return input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  }

  static bool isValid(String code) {
    return code.length == codeLength && code.split('').every(alphabet.contains);
  }
}
