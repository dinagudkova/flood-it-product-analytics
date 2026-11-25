# Tracking plan: Flood-It!

A tracking plan lists which events and properties the app sends, what each one means and which metric it serves.
Part 1 documents what the data already contains (as observed in this project). Part 2 proposes what to add,
based on the gaps that limited the analysis.

**Conventions:** Firebase / GA4 naming, `snake_case`. Event = something that happened at a moment;
parameter = a detail of that event; user property = an attribute of the player that is attached to all their events.

## Part 1. Current state (observed in the data)

### Events used in this project

| Event | Type | When it fires | Used for |
|---|---|---|---|
| `first_open` | automatic | first launch after install | new-player cohorts, day 0 |
| `session_start` | automatic | app opened after a period of inactivity | "active on day N" (retention) |
| `user_engagement` | automatic | app in foreground; parameter `engagement_time_msec` | "active on day N", minutes played |
| `level_start_quickplay` and other `level_start…` events | custom | a level starts (both modes) | funnel step 2 |
| `level_complete_quickplay` and other `level_complete…` events | custom | a level is won | funnel step 3 |
| `level_fail…`, `level_reset…`, `level_retry…` | custom | a level is lost or restarted | not used yet (difficulty analysis) |
| `completed_5_levels` | custom | milestone: 5 levels completed | funnel step 4, activation candidate |
| `level_up`, `post_score` | custom (GA4 recommended game events) | progressive-mode level up; score saved | not used yet |
| `use_extra_steps`, `spend_virtual_currency`, `no_more_extra_steps` | custom | extra steps used or run out | not used yet (in-game economy) |
| `ad_reward` | custom | player watched a rewarded ad | context: 354 players |
| `in_app_purchase` | automatic | purchase in the store | context: 27 players |
| `app_remove` | automatic (Android only) | app uninstalled | churn context, 2,635 players |

### User properties

| Property | Values | Meaning | Used for |
|---|---|---|---|
| `firebase_exp_1` | `0`–`3` | variant of Firebase experiment 1 | test groups |
| `ad_frequency` | 2, 4, 8, 16 (+ others) | Remote Config setting tested in experiment 1; exact meaning not documented | compliance check |
| `initial_extra_steps` | 3, 5, 10, 20 | extra steps a player starts with | balance check |
| `firebase_exp_3/4/5/7` | variant ids | other experiments | excluded |

## Part 2. Gaps found during the analysis

| Question we could not fully answer | What was missing |
|---|---|
| Did players in the "more ads" arm actually see more ads? Did they earn more money? | no event for regular (interstitial) ad impressions, no ad revenue |
| When exactly did a player enter the experiment and get the variant? | no exposure event; reconstructed from user properties, which is less precise |
| Where in the first levels do players struggle? | level events carry no level number, moves used or difficulty |
| What does `ad_frequency` = N mean? | no documentation of Remote Config parameters |

## Part 3. Proposed additions

| Event / property | When it fires | Parameters | Serves metric |
|---|---|---|---|
| `ad_impression` | an ad is shown (any format) | `ad_format` (interstitial / rewarded / banner), `ad_platform`, `ad_unit_name`, `value`, `currency`, `level_number` | ad impressions per player, **ad revenue per player** (primary metric of the follow-up test) |
| `experiment_exposure` | the first time the app *uses* an experiment value (e.g. the first ad decision), once per experiment | `experiment_id`, `variant`, `parameter_value` | exposure date, compliance, SRM on exposed players |
| Parameters on all `level_*` events | as today | `level_number`, `game_mode`, `moves_used`, `extra_steps_used`, `board_size` | difficulty curve, where new players drop off |
| `tutorial_begin`, `tutorial_complete` (GA4 recommended) | onboarding starts / ends | none | onboarding funnel |
| User property `install_cohort_week` | set once at first open | ISO week | cohort reports without recomputing |
| Remote Config documentation | n/a | a table of every parameter, its values and its effect in the game | correct interpretation of experiments |

`ad_impression` follows the parameters of GA4's recommended ad impression event, so it works with standard reports.

## Part 4. Metric → events map

| Metric | Events and fields |
|---|---|
| New players (cohort) | `first_open` |
| D1 / D7 retention | `first_open` + `session_start` or `user_engagement` on day 1 / day 7 |
| Minutes played | `user_engagement.engagement_time_msec` |
| New-player funnel | `first_open` → `level_start…` → `level_complete…` → `completed_5_levels` |
| Activation candidate | `completed_5_levels` within 24 h of `first_open` |
| Ad revenue per player | `ad_impression.value` (proposed) |
| Experiment groups and compliance | `experiment_exposure` (proposed), today `firebase_exp_*` + `ad_frequency` |

## Part 5. QA checklist before a release with new tracking

- [ ] Events visible in Firebase DebugView on a test device, with correct names and parameter types (numbers as numbers).
- [ ] Each event fires **once** per action (no duplicates on re-render, app resume or retry).
- [ ] `experiment_exposure` fires once per player per experiment and matches the Remote Config value.
- [ ] Ad revenue in `ad_impression` matches the ad network's own report within an agreed tolerance after the first week.
- [ ] No personal data in event parameters; tracking respects the player's consent choice where consent is required.
- [ ] Day after release: event counts per day compared with the previous version, to catch drops or spikes.
