-- 06_new_user_funnel: how far new players get in their first 7 days
-- install -> started a level -> completed a level -> completed 5 levels (both game modes)
WITH installs AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING MIN(PARSE_DATE('%Y%m%d', event_date)) <= DATE '2018-09-26'
),
first_week AS (
  SELECT e.user_pseudo_id, e.event_name
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN installs i USING (user_pseudo_id)
  WHERE e.event_timestamp >= i.install_ts
    AND e.event_timestamp <  i.install_ts + 7 * 24 * 60 * 60 * 1000000  -- 7 days in microseconds
),
per_user AS (
  SELECT
    user_pseudo_id,
    LOGICAL_OR(event_name LIKE 'level_start%')    AS started_level,
    LOGICAL_OR(event_name LIKE 'level_complete%') AS completed_level,
    LOGICAL_OR(event_name = 'completed_5_levels') AS completed_5
  FROM first_week
  GROUP BY user_pseudo_id
),
steps AS (
  SELECT 1 AS step_no, '1_install' AS step, COUNT(*) AS users FROM per_user
  UNION ALL SELECT 2, '2_started_level',      COUNTIF(started_level)   FROM per_user
  UNION ALL SELECT 3, '3_completed_level',    COUNTIF(completed_level) FROM per_user
  UNION ALL SELECT 4, '4_completed_5_levels', COUNTIF(completed_5)     FROM per_user
)
SELECT
  step,
  users,
  ROUND(users / FIRST_VALUE(users) OVER (ORDER BY step_no) * 100, 1) AS pct_of_installs,
  ROUND(users / LAG(users)         OVER (ORDER BY step_no) * 100, 1) AS pct_of_previous_step
FROM steps
ORDER BY step_no;
