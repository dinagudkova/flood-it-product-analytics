-- 07_experiment_users: one row per participant of Firebase experiment 1 (ad_frequency)
-- Day 0 = first day the player carries firebase_exp_1. Output is exported to data/07_experiment_users.csv
WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    PARSE_DATE('%Y%m%d', event_date) AS event_day,
    (SELECT value.string_value FROM UNNEST(user_properties) WHERE key = 'firebase_exp_1') AS variant,
    (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
       FROM UNNEST(user_properties) WHERE key = 'ad_frequency') AS ad_frequency,
    (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
       FROM UNNEST(user_properties) WHERE key = 'initial_extra_steps') AS initial_extra_steps,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_msec
  FROM `firebase-public-project.analytics_153293282.events_*`
),
exposure AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(variant)             AS variant,
    MIN(event_timestamp)           AS exposure_ts,
    MIN(event_day)                 AS exposure_date,
    ANY_VALUE(initial_extra_steps) AS initial_extra_steps,
    COUNT(*)                       AS exp_events,
    COUNTIF(ad_frequency = CASE variant
                             WHEN '0' THEN '4' WHEN '1' THEN '2'
                             WHEN '2' THEN '8' WHEN '3' THEN '16' END) AS events_with_assigned_freq
  FROM events
  WHERE variant IS NOT NULL
  GROUP BY user_pseudo_id
),
installs AS (
  SELECT user_pseudo_id, MIN(event_day) AS install_date
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
after_exposure AS (
  SELECT
    e.user_pseudo_id,
    LOGICAL_OR(e.event_name IN ('session_start', 'user_engagement')
               AND DATE_DIFF(e.event_day, x.exposure_date, DAY) = 1) AS d1,
    LOGICAL_OR(e.event_name IN ('session_start', 'user_engagement')
               AND DATE_DIFF(e.event_day, x.exposure_date, DAY) = 7) AS d7,
    ROUND(SUM(IF(e.event_name = 'user_engagement'
                 AND e.event_timestamp < x.exposure_ts + 7 * 24 * 60 * 60 * 1000000,
                 e.engagement_msec, 0)) / 60000, 2) AS minutes_7d
  FROM events e
  JOIN exposure x USING (user_pseudo_id)
  WHERE e.event_timestamp >= x.exposure_ts
  GROUP BY e.user_pseudo_id
)
SELECT
  x.user_pseudo_id,
  x.variant,
  x.exposure_date,
  i.install_date,
  i.install_date IS NOT NULL                           AS is_new_user,
  x.initial_extra_steps,
  x.exp_events,
  x.events_with_assigned_freq,
  ROUND(x.events_with_assigned_freq / x.exp_events, 3) AS assigned_freq_share,
  IFNULL(a.d1, FALSE)                                  AS d1,
  IFNULL(a.d7, FALSE)                                  AS d7,
  IFNULL(a.minutes_7d, 0)                              AS minutes_7d,
  x.exposure_date <= DATE '2018-09-26'                 AS d7_mature
FROM exposure x
LEFT JOIN installs i       USING (user_pseudo_id)
LEFT JOIN after_exposure a USING (user_pseudo_id)
ORDER BY x.variant, x.user_pseudo_id;
