import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/duonap_settings_repository.dart';
import '../data/duonap_sleep_repository.dart';
import '../service/duonap_settings_service.dart';
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

final duoNapSleepServiceProvider = Provider<DuoNapSleepService>((ref) {
  return DuoNapSleepService(
    repository: ref.watch(duoNapSleepRepositoryProvider),
    settings: ref.watch(duoNapSettingsRepositoryProvider),
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
