# DuoNap

Sleep plan for twins. One shared plan for the day, one tap per baby.

## Run it

The repo holds only the Dart code. Generate the platform folders once, then run:

```
flutter create . --project-name duonap --platforms=android,ios
flutter pub get
flutter test
flutter run
```

`flutter create .` adds `android/` and `ios/` and leaves `lib/` and `test/` alone.
Add `--org your.reverse.domain` if you want a specific application id.

## What it does today

- **Today screen:** a 24-hour ring per baby, the next step with a countdown, the full day plan, and three buttons (first baby, both, second baby).
- **Plan engine:** rebuilds the rest of the day after every tap and every 30 seconds.
- **Learning:** after three logged days per nap position, the starter numbers are replaced by the baby's own medians.
- **Storage:** on the device only (Hive). No account, no network.

## The plan rules

1. The morning wake-up starts the day. Until it is logged, the usual wake time is used.
2. Next nap = end of the previous sleep + the wake window for that nap position.
3. Daytime sleep is capped (3 h 30 min), and no nap starts within 2 h 50 min of the planned bedtime.
4. Night = the planned bedtime, but never sooner than last nap end + 2 h 20 min and never later than last nap end + 4 h.
5. For twins: predicted times within 20 minutes of each other are shared (earlier time for naps, later for night). Further apart, both times are shown.

The starter numbers in `DuoNapSleepProfile.starter` come from the family's own logs. They are a starting point, not medical advice.

## Structure

```
UI  <->  ViewModel  <->  Service  <->  Repository
```

| Folder | Holds |
|---|---|
| `lib/ui/today` | Today screen, its state and ViewModel, widgets |
| `lib/service` | Plan engine, twin merger, profile learner, sleep service |
| `lib/data` | Repository and DTO (the only place DTOs exist) |
| `lib/domain` | Models shared across layers |
| `lib/core` | `DuoNapResult`, base interfaces |
| `lib/app` | App widget, theme, providers |

State is plain Riverpod `Notifier` with hand-written state classes, so there is no code generation step. Moving to `riverpod_generator` + `freezed` is a mechanical change once `build_runner` is part of the workflow.

## Not built yet

- Shift plan toward an earlier bedtime (15 minutes every few days).
- Earlier bedtime after a short night.
- Editing or deleting a logged sleep.
- Sync between two phones (Firestore).
- Notifications before the next nap.
- Settings: baby names, planned bedtime, language.

## Status of this first commit

Written without a Flutter SDK at hand. The plan rules and the expected values in `test/duonap_plan_engine_test.dart` were checked against a separate implementation of the same rules; the Dart code itself has not been compiled or run yet.
