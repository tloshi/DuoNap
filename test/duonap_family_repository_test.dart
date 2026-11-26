import 'dart:io';

import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/data/duonap_family_dto.dart';
import 'package:duonap/data/duonap_family_link_store.dart';
import 'package:duonap/data/duonap_family_mirror.dart';
import 'package:duonap/data/duonap_family_repository.dart';
import 'package:duonap/data/duonap_session_mirror.dart';
import 'package:duonap/data/duonap_settings_dto.dart';
import 'package:duonap/data/duonap_settings_repository.dart';
import 'package:duonap/data/duonap_shift_repository.dart';
import 'package:duonap/data/duonap_sleep_repository.dart';
import 'package:duonap/data/duonap_sleep_session_dto.dart';
import 'package:duonap/domain/duonap_family.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'fakes/duonap_fake_cloud.dart';

final code = DuoNapJoinCode(code: 'ABC234', expires: DateTime(2026, 11, 25, 10));

String? codeOf(DuoNapResult<void> result) {
  return result is DuoNapFailure<void> ? result.code : null;
}

void main() {
  late Directory dir;
  late DuoNapLocalStores local;
  late DuoNapFakeCloudFamily cloud;
  late DuoNapFakeCloudSessions sessions;
  late DuoNapFamilyLinkStore link;
  late DuoNapCloudFamilyRepository repository;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('duonap_family');
    Hive.init(dir.path);
    final sleepBox = await Hive.openBox<String>('sessions');
    final settingsBox = await Hive.openBox<String>('settings');
    local = DuoNapLocalStores(
      sleep: DuoNapHiveSleepRepository(sleepBox),
      settings: DuoNapHiveSettingsRepository(settingsBox),
      shift: DuoNapHiveShiftRepository(settingsBox),
    );
    cloud = DuoNapFakeCloudFamily();
    sessions = DuoNapFakeCloudSessions();
    link = DuoNapFamilyLinkStore(settingsBox);
    repository = DuoNapCloudFamilyRepository(
      cloud: cloud,
      link: link,
      sessions: DuoNapSessionMirror(local: local.sleep, cloud: sessions),
      family: DuoNapFamilyMirror(cloud: cloud, settings: local.settings, shift: local.shift),
      local: local,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  DuoNapSleepSessionDto nap(String id) {
    return DuoNapSleepSessionDto(id: id, baby: 'first', kind: 'nap', startMs: 1000, endMs: 2000);
  }

  test('creating a family links the phone and sends its log and settings', () async {
    await local.sleep.putDto(nap('a'));
    await local.settings.save(DuoNapSettings.defaults.withBedtime(20 * 60 + 30));

    expect(codeOf(await repository.create(code)), isNull);
    await Future<void>.delayed(Duration.zero);

    expect(link.familyId, DuoNapFakeCloudFamily.familyId);
    expect(cloud.created?.members, ['uid-a']);
    expect(cloud.created?.joinCode, 'ABC234');
    expect(cloud.created?.settings.bedtimeMinutes, 20 * 60 + 30);
    expect(sessions.stored.keys, ['a']);
  });

  test('right after creating, the status shows the new code', () async {
    await repository.create(code);

    final status = (await repository.status() as DuoNapSuccess<DuoNapFamilyStatus>).data;

    expect(status.linked, isTrue);
    expect(status.joinCode, 'ABC234');
  });

  test('a linked phone cannot create or join again', () async {
    await repository.create(code);

    expect(codeOf(await repository.create(code)), 'ALREADY_LINKED');
    expect(codeOf(await repository.join('ABC234')), 'ALREADY_LINKED');
  });

  test('joining replaces this phone\'s log with the family\'s', () async {
    cloud.codes['XYZ789'] = DuoNapFakeCloudFamily.familyId;
    cloud.uid = 'uid-b';
    await local.sleep.putDto(nap('mine'));

    expect(codeOf(await repository.join('XYZ789')), isNull);

    expect(local.sleep.dtoOf('mine'), isNull);
    expect(link.familyId, DuoNapFakeCloudFamily.familyId);
    expect(cloud.joins, ['family-1/uid-b/XYZ789']);
  });

  test('the family\'s settings arrive on the joining phone', () async {
    cloud.codes['XYZ789'] = DuoNapFakeCloudFamily.familyId;
    await repository.join('XYZ789');

    cloud.incoming.add(
      const DuoNapFamilyDto(
        members: ['uid-a', 'uid-b'],
        joinCode: 'XYZ789',
        joinCodeExpiresAtMs: 0,
        settings: DuoNapSettingsDto(firstName: 'A', secondName: 'B', bedtimeMinutes: 1200, wakeMinutes: 420),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final settings = (await local.settings.load() as DuoNapSuccess<DuoNapSettings>).data;
    final status = (await repository.status() as DuoNapSuccess<DuoNapFamilyStatus>).data;
    expect(settings.plannedBedtimeMinutes, 1200);
    expect(status.members, 2);
  });

  test('an unknown code is refused and nothing changes', () async {
    await local.sleep.putDto(nap('mine'));

    expect(codeOf(await repository.join('NOPE22')), 'CODE_UNKNOWN');
    expect(local.sleep.dtoOf('mine'), isNotNull);
    expect(link.familyId, isNull);
  });

  test('without a connection creating fails as offline', () async {
    cloud.offline = true;

    expect(codeOf(await repository.create(code)), 'OFFLINE');
    expect(link.familyId, isNull);
  });
}
