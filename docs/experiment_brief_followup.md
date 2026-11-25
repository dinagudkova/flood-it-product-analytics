# Experiment brief: more frequent ads (ad_frequency 2 vs 4)

**Status:** design only, written before launch. This is a proposed follow-up to Firebase experiment 1
(see the [README](../README.md) and [notebooks/02_ab_test_ad_frequency.ipynb](../notebooks/02_ab_test_ad_frequency.ipynb)).
It was not run; the numbers below are planning estimates from the 2018 sample data.

## 1. Background

Experiment 1 tested four values of `ad_frequency` (4 = control, 2, 8, 16) on 2,344 new players.
It was healthy (no SRM, balanced groups) but found no detectable effect on D7, D1 or playtime, because it was
too small: the minimum detectable effect for D7 was about 4.3 pp on a 5% base.

Two lessons for the next test:

- **Fewer arms.** Four arms split ~2,300 players four ways. Two arms put all traffic into the one comparison that matters.
- **Measure the money.** Ad impressions and ad revenue were not tracked, so the test could not show the upside of more ads.
  See [tracking_plan.md](tracking_plan.md).

## 2. Decision and hypothesis

**Decision to make:** can we show ads twice as often (`ad_frequency` 2 instead of 4) to earn more per player,
without losing a meaningful share of new players?

**Hypothesis:** doubling ad frequency increases ad revenue per new player in the first 7 days,
and lowers D7 retention by less than 2 percentage points.

> Assumption to confirm with the game team before launch: `ad_frequency` = N means "an interstitial ad every N levels",
> so 2 shows ads more often than 4.

This is a **non-inferiority** question for retention: we do not need more ads to *improve* D7,
we need to show that D7 does not get *worse by more than an agreed margin*.

## 3. Design

| Item | Choice | Why |
|---|---|---|
| Arms | Control: `ad_frequency` = 4 · Treatment: `ad_frequency` = 2 | the business question is "more ads or not" |
| Split | 50 / 50 | maximises power for two arms |
| Unit of randomization | app installation (`user_pseudo_id`) | metrics are per player |
| Who is eligible | new installs only, assigned at `first_open` | day 0 = install day for everyone; avoids old players with pre-set values |
| Exposure | log `experiment_exposure` when the first ad decision uses the variant | lets us check compliance directly instead of reconstructing it |
| Other tests | no other ad or onboarding test on the same players | avoids overlap like exp_3 / exp_1 |
| Duration | fixed in advance (section 5), whole weeks | no stopping early when results "look good" |

## 4. Metrics

| Role | Metric | Definition | Data needed |
|---|---|---|---|
| **Primary** | Ad revenue per new player, 7 days | sum of ad revenue in the first 7 days ÷ players in the arm | `ad_impression` with `value` and `currency` (new) |
| **Guardrail (non-inferiority)** | D7 retention | active (`session_start` or `user_engagement`) on day 7 after install | existing events |
| Guardrail | D1 retention | active on day 1 | existing events |
| Guardrail | Minutes played, 7 days | sum of `engagement_time_msec` from `user_engagement` | existing events |
| Guardrail | Uninstall rate, 7 days | share of players with `app_remove` (Android only) | existing events |
| Health | SRM, compliance | group sizes vs 50/50; share of exposed players with the assigned value | `experiment_exposure` (new) |
| Secondary | Ad impressions per player, levels per player | to explain *why* revenue or retention moved | `ad_impression`, `level_*` |

## 5. Sample size and duration

**Traffic assumption:** ~38 new installs per day (4,319 installs over 114 days in the sample).
The real game may have had more traffic; recalculate with current numbers before launch.

**D7 guardrail (non-inferiority).** Baseline D7 ≈ 5.1% (control in experiment 1), one-sided α = 0.05, power 80%,
true difference assumed 0. Players needed per arm to show that D7 does not drop by more than the margin:

| Non-inferiority margin | Players per arm | Days at ~38 installs/day |
|---|---|---|
| −1.5 pp | ~2,650 | ~140 |
| **−2 pp (proposed)** | **~1,500** | **~79** |
| −3 pp | ~660 | ~35 |

**Proposed:** margin −2 pp, ~1,500 players per arm, about **11–12 weeks**. A drop of 2 pp from 5.1% means losing
about 2 in 5 players who would still be playing on day 7; the product team must confirm this is the largest loss
it can accept for the expected revenue.

**Revenue (primary).** Ad revenue per player is skewed and its variance is unknown, because it was never tracked.
Plan: ship the new ad tracking first, collect 2 weeks of baseline data, then compute the sample size for the smallest
revenue lift worth shipping. The test runs for the **longer** of the two durations.

For comparison, detecting a **±1 pp** change in D7 in a classic two-sided test would need ~8,300 players per arm
(~436 days at this traffic). This is why the D7 question is framed as non-inferiority with an agreed margin.

## 6. Analysis plan (fixed before launch)

1. **Health first:** SRM (chi-square vs 50/50, alarm at p < 0.001); compliance from `experiment_exposure`.
   If either fails, stop and fix, do not read results.
2. **Primary:** difference in 7-day ad revenue per player, 95% bootstrap CI (10,000 resamples); Mann–Whitney U as a check.
3. **D7 non-inferiority:** one-sided 95% CI for the difference (treatment − control). Non-inferior if the lower bound is above −2 pp.
4. **Other guardrails:** two-sided tests (z-test for rates, Mann–Whitney for minutes) with Holm correction.
5. **Population:** intention-to-treat (all assigned new installs); per-protocol only as a sensitivity check.
6. **No peeking:** results are read once, at the planned end date. Daily monitoring is only for health checks and crashes.

## 7. Decision rules

| Outcome | Decision |
|---|---|
| Revenue up (CI above 0) **and** D7 non-inferior **and** no guardrail significantly worse | Ship `ad_frequency` = 2 |
| D7 fails non-inferiority (lower bound below −2 pp) | Do not ship, whatever the revenue |
| Revenue not significantly different, D7 non-inferior | Do not ship; more ads without more money is all risk |
| Health check fails | Fix the setup and rerun |

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Ad tracking is new and may be wrong | QA in Firebase DebugView before launch; compare impressions with the ad network's own report for the first week |
| Weekly patterns (weekends) | run whole weeks only |
| Players reinstall and get re-randomized | report the share of reinstalls; analysis is per installation, as in experiment 1 |
| Long duration (~3 months) | agree on it upfront; if too long, test a larger change or accept a wider margin, and say so explicitly |
| Meaning of `ad_frequency` is wrong | confirm with the game team before launch (section 2) |

## 9. Next in the backlog: onboarding

The strongest retention signal in the project is early progression: new players who complete 5 levels within 24 hours
have about 2× higher D7 (8.5% vs 4.5%, correlation only). A separate test could make the first levels easier or give
more starting extra steps, with D7 as the primary metric. `initial_extra_steps` (3 / 5 / 10 / 20) already varies between
players; before designing a new test, check with the team whether it was randomized, because then its effect on D7
can be analysed from existing data.
