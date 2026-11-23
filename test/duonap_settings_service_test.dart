import 'package:duonap/core/duonap_result.dart';
import 'package:duonap/domain/duonap_baby.dart';
import 'package:duonap/domain/duonap_settings.dart';
import 'package:duonap/service/duonap_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/duonap_fake_repositories.dart';

String? codeOf(DuoNapResult<void> result) {
  return result is DuoNapFailure<void> ? result.code : null;
}

void main() {
  late DuoNapFakeSettingsRepository repository;
  late DuoNapSettingsService service;

  setUp(() {
    repository = DuoNapFakeSettingsRepository();
    service = DuoNapSettingsService(repository: repository);
  });

  test('loads the defaults when nothing is saved', () async {
    final result = await service.load();

    expect(result, isA<DuoNapSuccess<DuoNapSettings>>());
    final settings = (result as DuoNapSuccess<DuoNapSettings>).data;
    expect(settings.usualWakeMinutes, 8 * 60);
    expect(settings.plannedBedtimeMinutes, 21 * 60 + 15);
  });

  test('saves trimmed names and both times', () async {
    final edited = DuoNapSettings.defaults
        .withName(DuoNapBabyId.first, '  Ana ')
        .withBedtime(20 * 60 + 30)
        .withWake(7 * 60);

    final result = await service.save(edited);

    expect(codeOf(result), isNull);
    expect(repository.stored?.firstName, 'Ana');
    expect(repository.stored?.plannedBedtimeMinutes, 20 * 60 + 30);
    expect(repository.stored?.usualWakeMinutes, 7 * 60);
  });

  test('rejects an empty name', () async {
    final edited = DuoNapSettings.defaults.withName(DuoNapBabyId.second, '   ');

    expect(codeOf(await service.save(edited)), 'NAME_EMPTY');
    expect(repository.stored, isNull);
  });

  test('rejects a name longer than the limit', () async {
    final edited = DuoNapSettings.defaults.withName(DuoNapBabyId.first, 'A' * 25);

    expect(codeOf(await service.save(edited)), 'NAME_TOO_LONG');
  });

  test('keeps the wake time inside the morning window', () async {
    final early = DuoNapSettings.defaults.withWake(4 * 60 + 30);
    final late = DuoNapSettings.defaults.withWake(14 * 60);

    expect(codeOf(await service.save(early)), 'WAKE_OUT_OF_RANGE');
    expect(codeOf(await service.save(late)), 'WAKE_OUT_OF_RANGE');
  });

  test('keeps bedtime in the evening', () async {
    final edited = DuoNapSettings.defaults.withBedtime(13 * 60);

    expect(codeOf(await service.save(edited)), 'BEDTIME_OUT_OF_RANGE');
  });
}
