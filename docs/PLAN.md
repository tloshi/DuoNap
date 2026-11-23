# DuoNap build plan

What to build, in what order, and how to tell each step is done.
The sleep rules behind it are in [LOGIC.md](LOGIC.md).

## Where things stand

- First commit is in: domain, Hive storage, plan engine, twin merger, learner, Today screen, unit tests.
- **Phase 0 done** (branch `phase-0-first-run`): compiles on Flutter stable 3.41.9, analyze clean, runs on an Android emulator.
- **Phase 1 built** (branch `phase-1-daily-use`): edit and delete, "woke up at…", settings, night view. Checked on the emulator; not yet used by the family for a full day, which is the done criterion.
- The rules and the expected values in the engine tests were checked against a second implementation of the same rules.

## Phase 0: first compile and run

Goal: the app starts on a phone and the tests pass.

1. `flutter create . --project-name duonap --platforms=android,ios`
2. `flutter pub get`
3. `flutter analyze` and fix every error and warning.
4. `flutter test` and fix failures. If a test and the engine disagree, LOGIC.md decides which one is right.
5. `flutter run` on an emulator or a phone.
6. Check the Today screen against the design notes below.

Done when: analyze is clean, all tests pass, and tapping the three buttons changes the plan on screen.

Known risks to check first:

- `flutter_riverpod` is pinned to 2.x. If the installed Flutter needs 3.x, the `Notifier` code should still work, but check the changelog.
- `google_fonts` downloads Sora at first run. Release builds on Android need the INTERNET permission, or the font bundled as an asset.
- `Color.withAlpha` is used instead of `withOpacity` to avoid the deprecation.

## Phase 1: usable every day

1. **Edit and delete a logged sleep.** Bottom sheet as in the "D · Dialogu" mockup: baby selector (first, second, both), start and end with plus and minus one minute, delete, save.
2. **Log the first morning by hand.** Today, a wake-up can only be logged by ending a night sleep. Add "woke up at…" for the first day.
3. **Settings.** Baby names, planned bedtime, usual wake time. Move them out of `DuoNapFamily` and `DuoNapSleepProfile.starter`.
4. **Night view.** Dim screen with large buttons for night wake-ups.

Done when: both parents can use it for a full day without touching code.

## Phase 2: the path to 19:00 – 07:00

1. `DuoNapShiftPlan` as specified in LOGIC.md section 6, with unit tests.
2. Screen "Rruga" as in the "D · Rruga 19–07" mockup: today's wake-up and bedtime, next steps with dates, the hold rule.
3. Earlier night after a short night.

Done when: the planned bedtime moves on its own every three days and holds after two late nights.

## Phase 3: two phones

1. Firebase project, `flutterfire configure`, anonymous auth, a family joined by a short code.
2. Firestore repository behind the existing `DuoNapSleepRepository` interface. Hive stays as the offline cache.
3. Data model:

```
families/{familyId}
  members: [uid, ...]
  babies: [{ id, name }]
  settings: { plannedBedtimeMinutes, usualWakeMinutes }
families/{familyId}/sessions/{sessionId}
  babyId, kind, startMs, endMs, updatedAtMs, updatedBy
```

4. Security rules: read and write only for uids listed in `members`.
5. Conflicts: last write wins per session, by `updatedAtMs`. Two phones ending the same sleep is harmless.

Done when: a tap on one phone shows on the other within a few seconds, and both work offline.

No deploys, rule changes or key operations without explicit approval from Loshi.

## Phase 4: notifications

- Local notification 10 minutes before the next nap and before bedtime.
- Rescheduled every time the plan is rebuilt.

## Phase 5: history

- Day view as in the "D · Dita" mockup: full 24-hour ring, per-baby wake-up, day sleep, night.
- Week view: wake-up and bedtime trend toward the target.

## Phase 6: AI, optional

Not for prediction. The engine stays deterministic and offline.

- Log by voice or text ("Diana fell asleep 10 minutes ago") turned into an event.
- Weekly summary in Albanian from computed statistics, not raw history.
- Firebase AI Logic from Flutter. Send aggregates only.

## Later

- Languages: Albanian, German, English.
- Age table for families with no history.
- Store release: check the name DuoNap for trademarks and domains first.

## Design notes

Direction D from the mockup canvas: https://claude.ai/artifact/7nJnGijomKiwM4h94VDgQu

| Token | Value |
|---|---|
| Font | Sora, weights 400, 600, 700, 800 |
| Ground | `#0B0C1A`, with a soft radial glow `#1B1D3D` behind the ring |
| Surface | `#15172B` |
| Raised | `#1D2040` |
| Highlight | `#23264A` |
| Text | `#F4F2FF` |
| Muted text | `#A3A6C8` |
| First baby | `#F6BE7A` |
| Second baby | `#7C9FF0` |
| Primary button | `#F4F2FF` fill, `#0B0C1A` text, soft glow |

Principles:

- No stock Material components on screen. Pills, rings and sheets are custom.
- One primary action per screen. Buttons at least 56 px high, reachable with one thumb.
- Bright means it happened, faint means predicted.
- The two babies are told apart by colour and by name or initial, never by colour alone.
- Corners: 24 for cards, 14 for rows, full pill for buttons.
