# DuoNap sleep logic

How the day plan is calculated, where each rule came from, and what is still a guess.
This is a planning aid for parents, not medical advice. Night feeds at this age are normal and the plan does not try to remove them.

## 1. Goal

- One shared plan for two babies, rebuilt after every logged event.
- Move night sleep gradually toward **19:00 – 07:00**.
- Keep it honest: with three naps a day the earliest workable night is about 19:15 – 19:30. 19:00 becomes easy once the babies are on two naps.

## 2. Evidence

Four days from the family's log in the app they use now (one child's log).

| Day | Wake-up | Naps | Night began |
|---|---|---|---|
| 21 Oct | 08:45 | 4 naps, one of them 12:55 – 14:43 | not visible |
| 28 Oct | 08:17 | 4 naps, one of them 14:47 – 15:14 | 21:10 |
| 3 Nov | 07:51 | 09:37 – 11:07, 13:29 – 15:02, 18:15 – 18:50 | 22:24 |
| about 5 Nov | 08:13 | 2 done (second ended 14:27), third predicted 16:41 – 17:34 | predicted 21:27 |

What the numbers show:

- **Wake windows grow through the day.** 3 Nov: 1 h 46, 2 h 22, 3 h 13, then 3 h 34 before night.
- **Averages:** wake-up about 08:15, night about 21:45, so nights are about 10 h 30 min.
- **Nap count is dropping** from four to three.
- **The late third nap is the blocker.** A nap ending 18:50 makes a 19:00 night impossible.

## 3. What the reference app appears to do

Inferred from screenshots. Confidence is noted on each line.

| Behaviour | Evidence | Confidence |
|---|---|---|
| Next nap = end of previous sleep + a wake window for that position | 14:27 + 2 h 14 = 16:41 | High |
| Expected nap length is learned | third nap predicted at 53 min | High |
| Night is recalculated live | nap started 19:01, night moved 21:27 to 22:13 | High |
| Night is at least about 2 h 20 after the last nap ends | 19:54 + 2 h 19 = 22:13 | Medium, one observation |
| No extra nap is added to bridge a long evening | 17:34 to 21:27 predicted awake | High |
| Daily nap target (270 min one day) = 24-hour need minus last night | number changes daily | Low, unconfirmed |

To test the last line: compare the daily nap target on the morning after a long night and after a short night. If it drops after the long night, the hypothesis holds.

## 4. Rules DuoNap implements

Code: `lib/service/duonap_plan_engine.dart`. Numbers: `DuoNapSleepProfile.starter`, except the usual wake time and the planned bedtime, which come from the family settings (`DuoNapSettings`, defaults 08:00 and 21:15).

1. **The morning wake-up starts the day.** Until it is logged, the usual wake time (settings, default 08:00) is the anchor.
2. **Next nap = end of the previous sleep + the wake window for that nap position.** Starter windows: 1 h 45, 2 h 20, 2 h 15.
3. **Expected nap length per position.** Starter: 1 h 30, 1 h 30, 30 min. A running nap is assumed to end at its usual length, or now if it has run over.
4. **Daytime sleep is capped at 3 h 30.** A planned nap is shortened to fit, and dropped if less than 15 minutes is left.
5. **No nap close to night.** A nap is not planned if it would start within 2 h 50 of the planned bedtime (min last window + 30 min).
6. **Night = the planned bedtime (settings, default 21:15), kept inside two limits:**
   - never sooner than last nap end + 2 h 20,
   - never later than last nap end + 4 h. This limit is ignored once that moment has passed.
7. **An overdue nap keeps its planned time** and is flagged. The rest of the day is calculated as if it starts now.
8. **A logged night closes the day.** Nothing more is planned.

### Twins

Code: `lib/service/duonap_twin_plan_merger.dart`.

- Each baby gets its own plan from its own log.
- Predicted times within **20 minutes** of each other become one shared time: the **earlier** one for naps, the **later** one for night.
- Further apart, the first baby's time is shown with the second baby's time beside it.

### Learning

Code: `lib/service/duonap_profile_learner.dart`.

- For each nap position, the wake window and nap length become the **median** of the last 10 logged days.
- A position needs **3 days** of data before it replaces the starter value.
- The median means one odd day does not move the plan.

### Nap or night, and day boundaries

Code: `lib/service/duonap_sleep_service.dart`, `lib/service/duonap_day_history.dart`.

- Sleep that starts within 60 minutes of the planned bedtime, or before 05:00, is **night**. Everything else is a **nap**. The bedtime is the one in settings. (Open question in section 7: the code counts every start from 60 minutes before bedtime until midnight as night.)
- The morning wake-up is the latest end, between 05:00 and 14:00, of either a night sleep or a **wake-up logged by hand**.
- A wake-up logged by hand is stored as its own session of kind `wake`, with start and end at the same moment. It is not sleep: it is never a nap, never night sleep, never overlaps anything, and is not counted in any sleep length.
- A night that began at or after 14:00 belongs to that evening.
- The night view is shown once tonight's night sleep is logged, and before 05:00.

### Correcting the log

Code: `lib/service/duonap_sleep_edit_service.dart`, `lib/service/duonap_sleep_edit_rules.dart`.

- A logged sleep can be moved minute by minute, or deleted, for one baby or for both at once. "Both" is offered only when both babies have that sleep logged and both are either still asleep or both finished.
- A correction is refused when a time is in the future, the end is not after the start, or a finished sleep would lose its end.
- A sleep keeps its date, and its start stays in the hours of its kind: a nap from 05:00 on, night sleep from 14:00 on or before 05:00. Otherwise the day rules above would no longer find it where it was.
- A correction may not overlap another sleep of the same baby.
- **"Woke up at…"** sets the morning wake-up for one baby or both, between 05:00 and 14:00 and not in the future. If the wake-up already comes from a sleep, that sleep's end moves. If a night is still running, it ends then. Otherwise a hand wake-up is added. Nothing is saved unless it works for every chosen baby.
- A hand wake-up can be deleted. A wake-up that is the end of a logged night cannot, because that would delete the night.
- When a night is split by night wake-ups, the "Nata" row opens the first part only.

## 5. Where DuoNap differs on purpose

| Topic | Reference app | DuoNap | Why |
|---|---|---|---|
| Bad night | more daytime sleep the next day | daytime sleep stays capped | long naps push the next night later |
| Long evening | night stays at the usual hour | night moves earlier after 4 h awake | every hard day moves toward the goal |
| Two babies | one child per profile | one shared plan | the parents act on one schedule |

## 6. Designed, not built yet

### Shift plan toward the target

- Start from the current averages: wake-up 08:15, night 21:45.
- Every **3 days**, both move **15 minutes earlier**.
- Wake-up stops at 07:00. Night continues to the target.
- **Hold rule:** if night began more than 30 minutes after the planned bedtime two nights in a row, the step is held for 2 more days.
- With three naps the target is 19:30. It becomes 19:00 when the plan drops to two naps.
- Implementation: `plannedBedtimeMinutes` and `usualWakeMinutes` stop being constants and come from a `DuoNapShiftPlan` for the given date.

### Earlier night after a short night

- Typical night length = median of the last 7 nights.
- If last night was more than 45 minutes shorter, tonight's bedtime moves earlier by half the shortfall, at most 45 minutes.
- Naps are never lengthened to make up for it.

### Nap count changes

- Drop the last nap when it has been skipped or under 20 minutes on 5 of the last 7 days.
- When a nap is dropped, the remaining wake windows are relearned from the next days.

## 7. Open questions

- **Night or nap by the clock.** Section 4 says sleep starting "within 60 minutes of the planned bedtime" is night. The code counts any start from 60 minutes before bedtime until midnight as night, so a sleep at 23:34 is night. Decide which is meant, then align this file or the code.
- **The babies' exact age.** The reference app showed 5 months 30 days on 3 Nov. The starter numbers come from the log, not from an age table, so the plan works either way, but an age table is needed for new users.
- **The 2 h 20 minimum last window** rests on one observation. Check it against a week of DuoNap data.
- **The daily nap target hypothesis** in section 3 is unconfirmed.
- **Shared plan when the babies drift apart** by more than 20 minutes most days: keep showing two times, or steer them back together?
