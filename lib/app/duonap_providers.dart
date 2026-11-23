import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/duonap_sleep_repository.dart';
import '../service/duonap_sleep_service.dart';

/// Overridden in `main()` once the Hive box is open.
final duoNapSleepRepositoryProvider = Provider<DuoNapSleepRepository>((ref) {
  throw UnimplementedError('duoNapSleepRepositoryProvider is not overridden.');
});

final duoNapSleepServiceProvider = Provider<DuoNapSleepService>((ref) {
  return DuoNapSleepService(
    repository: ref.watch(duoNapSleepRepositoryProvider),
  );
});
