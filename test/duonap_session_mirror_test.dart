import 'dart:io';

import 'package:duonap/data/duonap_cloud.dart';
import 'package:duonap/data/duonap_session_mirror.dart';
import 'package:duonap/data/duonap_sleep_repository.dart';
import 'package:duonap/data/duonap_sleep_session_dto.dart';
import 'package:duonap/data/duonap_synced_repositories.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_sleep_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'fakes/duonap_fake_cloud.dart';

DuoNapSleepSessionDto nap(String id, int updatedAtMs) {
  return DuoNapSleepSessionDto(
    id: id,
    baby: 'first',
    kind: 'nap',
    startMs: 1000,
    endMs: 2000,
    updatedAtMs: updatedAtMs,
  );
}

void main() {
  late Directory dir;
  late DuoNapHiveSleepRepository local;
  late DuoNapFakeCloudSessions cloud;
  late DuoNapSessionMirror mirror;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('duonap_mirror');
    Hive.init(dir.path);
    final box = await Hive.openBox<String>('sessions');
    local = DuoNapHiveSleepRepository(box, clock: () => DateTime.fromMillisecondsSinceEpoch(5000));
    cloud = DuoNapFakeCloudSessions();
    mirror = DuoNapSessionMirror(local: local, cloud: cloud);
  });

  tearDown(() async {
    await mirror.stop();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<void> receive(List<DuoNapRemoteSessionChange> changes) async {
    cloud.incoming.add(changes);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('last write wins: only a newer copy replaces the local one', () {
    expect(DuoNapSessionMirror.isNewer(nap('a', 20), nap('a', 10)), isTrue);
    expect(DuoNapSessionMirror.isNewer(nap('a', 10), nap('a', 20)), isFalse);
    expect(DuoNapSessionMirror.isNewer(nap('a', 10), nap('a', 10)), isFalse);
    expect(DuoNapSessionMirror.isNewer(nap('a', 10), null), isTrue);
  });

  test('the other phone\'s newer session replaces the local copy', () async {
    await local.putDto(nap('a', 10));
    await mirror.start('family-1', 'uid-a');

    await receive([DuoNapRemoteSessionChange(id: 'a', dto: nap('a', 20))]);

    expect(local.dtoOf('a')?.updatedAtMs, 20);
  });

  test('an older remote copy leaves the local session alone', () async {
    await local.putDto(nap('a', 30));
    await mirror.start('family-1', 'uid-a');

    await receive([DuoNapRemoteSessionChange(id: 'a', dto: nap('a', 20))]);

    expect(local.dtoOf('a')?.updatedAtMs, 30);
  });

  test('a delete on the other phone removes the session here', () async {
    await local.putDto(nap('a', 10));
    await mirror.start('family-1', 'uid-a');

    await receive([const DuoNapRemoteSessionChange(id: 'a')]);

    expect(local.dtoOf('a'), isNull);
  });

  test('applied changes are announced so the screen refreshes', () async {
    await mirror.start('family-1', 'uid-a');
    final announced = mirror.changes.first;

    cloud.incoming.add([DuoNapRemoteSessionChange(id: 'a', dto: nap('a', 20))]);

    await expectLater(announced.timeout(const Duration(seconds: 2)), completes);
  });

  test('a local save is sent with the time and this phone\'s user', () async {
    final synced = DuoNapSyncedSleepRepository(local, mirror);
    await mirror.start('family-1', 'uid-a');

    await synced.save(
      DuoNapSleepSession(
        id: 'b',
        babyId: DuoNapBabyId.second,
        kind: DuoNapSleepKind.nap,
        start: DateTime.fromMillisecondsSinceEpoch(1000),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cloud.stored['b']?.updatedAtMs, 5000);
    expect(cloud.stored['b']?.updatedBy, 'uid-a');
  });

  test('nothing is sent before the phone belongs to a family', () async {
    final synced = DuoNapSyncedSleepRepository(local, mirror);

    await synced.delete('a');
    await local.putDto(nap('c', 10));
    mirror.push('c');

    expect(cloud.stored, isEmpty);
  });
}
