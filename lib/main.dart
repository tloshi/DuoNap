import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/duonap_app.dart';
import 'app/duonap_providers.dart';
import 'data/duonap_settings_repository.dart';
import 'data/duonap_sleep_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final sleepBox = await Hive.openBox<String>(DuoNapHiveSleepRepository.boxName);
  final settingsBox =
      await Hive.openBox<String>(DuoNapHiveSettingsRepository.boxName);

  runApp(
    ProviderScope(
      overrides: [
        duoNapSleepRepositoryProvider.overrideWithValue(
          DuoNapHiveSleepRepository(sleepBox),
        ),
        duoNapSettingsRepositoryProvider.overrideWithValue(
          DuoNapHiveSettingsRepository(settingsBox),
        ),
      ],
      child: const DuoNapApp(),
    ),
  );
}
