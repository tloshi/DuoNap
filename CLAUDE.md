# DuoNap

Flutter app: a shared sleep plan for twins. One plan for the day, one tap per baby.

## Read first

1. `docs/project_state.json` — what was done last and what is pending. Update it after every change: `recent_changes`, `current_tasks`, `files_affected`.
2. `docs/LOGIC.md` — the sleep rules. This is the source of truth when code and tests disagree.
3. `docs/PLAN.md` — phases, acceptance criteria, design tokens.

## Commands

```
flutter create . --project-name duonap --platforms=android,ios   # once, generates android/ and ios/
flutter pub get
flutter analyze
flutter test
flutter run
```

## Architecture (strict)

```
UI  <->  ViewModel  <->  Service  <->  Repository
```

- No layer skipping. UI never imports from `lib/service` or `lib/data`.
- DTOs exist only in `lib/data`. Everything else uses domain models from `lib/domain`.
- Services and repositories return `DuoNapResult<T>`. They do not throw.
- Every class is prefixed `DuoNap`: `DuoNapSleepService`, `DuoNapTodayViewModel`, `DuoNapSleepSessionDto`.
- State: Riverpod `Notifier` with hand-written state classes. No code generation yet.
- Storage: Hive, one JSON string per session.

## Code rules

- Max 200 lines per file, 3 parameters per function, 2 levels of nesting.
- No duplication, no workarounds, explicit over implicit.
- The plan engine stays pure: no clock, no storage, no Flutter imports. Time comes in through `DuoNapPlanInput.now`.
- Every rule change in the engine comes with a test and an update to `docs/LOGIC.md`.
- UI text is Albanian for now. Code, comments and docs are English.

## Hard limits

- Never deploy, change Firebase rules, or touch keys without explicit approval from Loshi.
- Never log names or sleep data.
- Do not change the plan rules to make a test pass. Fix the code or the test according to `docs/LOGIC.md`, or ask.
