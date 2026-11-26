import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/duonap_family_repository.dart';
import '../data/duonap_settings_repository.dart';
import '../data/duonap_shift_repository.dart';
import '../data/duonap_sleep_repository.dart';
import '../service/duonap_family_service.dart';
import '../service/duonap_settings_service.dart';
import '../service/duonap_shift_service.dart';
import '../service/duonap_sleep_edit_service.dart';
import '../service/duonap_sleep_service.dart';

/// Overridden in `main()` once the Hive box is open.
final duoNapSleepRepositoryProvider = Provider<DuoNapSleepRepository>((ref) {
  throw UnimplementedError('duoNapSleepRepositoryProvider is not overridden.');
});

/// Overridden in `main()` once the Hive box is open.
final duoNapSettingsRepositoryProvider = Provider<DuoNapSettingsRepository>((ref) {
  throw UnimplementedError('duoNapSettingsRepositoryProvider is not overridden.');
});

/// Overridden in `main()` once the Hive box is open.
final duoNapShiftRepositoryProvider = Provider<DuoNapShiftRepository>((ref) {
  throw UnimplementedError('duoNapShiftRepositoryProvider is not overridden.');
});

/// Overridden in `main()` once Firebase and the Hive boxes are open.
final duoNapFamilyRepositoryProvider = Provider<DuoNapFamilyRepository>((ref) {
  throw UnimplementedError('duoNapFamilyRepositoryProvider is not overridden.');
});

final duoNapFamilyServiceProvider = Provider<DuoNapFamilyService>((ref) {
  return DuoNapFamilyService(repository: ref.watch(duoNapFamilyRepositoryProvider));
});

final duoNapSleepServiceProvider = Provider<DuoNapSleepService>((ref) {
  return DuoNapSleepService(
    repository: ref.watch(duoNapSleepRepositoryProvider),
    settings: ref.watch(duoNapSettingsRepositoryProvider),
    shift: ref.watch(duoNapShiftRepositoryProvider),
  );
});

final duoNapShiftServiceProvider = Provider<DuoNapShiftService>((ref) {
  return DuoNapShiftService(
    shift: ref.watch(duoNapShiftRepositoryProvider),
    settings: ref.watch(duoNapSettingsRepositoryProvider),
    sleep: ref.watch(duoNapSleepRepositoryProvider),
  );
});

final duoNapSleepEditServiceProvider = Provider<DuoNapSleepEditService>((ref) {
  return DuoNapSleepEditService(
    repository: ref.watch(duoNapSleepRepositoryProvider),
  );
});

final duoNapSettingsServiceProvider = Provider<DuoNapSettingsService>((ref) {
  return DuoNapSettingsService(
    repository: ref.watch(duoNapSettingsRepositoryProvider),
  );
});
