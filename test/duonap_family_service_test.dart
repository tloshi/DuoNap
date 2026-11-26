import 'dart:math';

import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/data/duonap_family_repository.dart';
import 'package:duonap/domain/duonap_family.dart';
import 'package:duonap/service/duonap_family_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the service asks for; every call succeeds.
class _RecordingRepository implements DuoNapFamilyRepository {
  String? joinedWith;
  DuoNapJoinCode? createdWith;

  @override
  Stream<void> get remoteChanges => const Stream<void>.empty();

  @override
  Stream<Object> get syncErrors => const Stream<Object>.empty();

  @override
  Future<DuoNapResult<DuoNapFamilyStatus>> status() async {
    return const DuoNapSuccess<DuoNapFamilyStatus>(DuoNapFamilyStatus.unlinked);
  }

  @override
  Future<DuoNapResult<void>> resume() async => const DuoNapSuccess<void>(null);

  @override
  Future<DuoNapResult<void>> create(DuoNapJoinCode code) async {
    createdWith = code;
    return const DuoNapSuccess<void>(null);
  }

  @override
  Future<DuoNapResult<void>> join(String code) async {
    joinedWith = code;
    return const DuoNapSuccess<void>(null);
  }

  @override
  Future<DuoNapResult<void>> renewCode(DuoNapJoinCode code) async => const DuoNapSuccess<void>(null);
}

void main() {
  final now = DateTime(2026, 11, 24, 10, 0);
  late _RecordingRepository repository;
  late DuoNapFamilyService service;

  setUp(() {
    repository = _RecordingRepository();
    service = DuoNapFamilyService(repository: repository, clock: () => now, random: Random(7));
  });

  test('a new code has 6 characters without look-alikes and lasts 24 hours', () {
    final code = service.newCode();

    expect(code.code, hasLength(6));
    expect(DuoNapFamilyService.isValid(code.code), isTrue);
    expect(code.code.contains(RegExp('[01IO]')), isFalse);
    expect(code.expires, now.add(const Duration(hours: 24)));
  });

  test('creating a family hands the repository a fresh code', () async {
    await service.create();

    expect(repository.createdWith?.expires, now.add(const Duration(hours: 24)));
  });

  test('a typed code is cleaned up before joining', () async {
    await service.join(' abc-234 ');

    expect(repository.joinedWith, 'ABC234');
  });

  test('a code that cannot exist is refused without asking the cloud', () async {
    final tooShort = await service.join('ABC23');
    final lookAlike = await service.join('ABC10O');

    expect((tooShort as DuoNapFailure<void>).code, 'CODE_INVALID');
    expect((lookAlike as DuoNapFailure<void>).code, 'CODE_INVALID');
    expect(repository.joinedWith, isNull);
  });
}
