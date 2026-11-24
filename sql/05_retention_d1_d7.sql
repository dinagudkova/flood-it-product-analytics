-- 05_retention_d1_d7: D1 and D7 retention of new players
-- New player = has first_open. Active = session_start or user_engagement that day.
-- Only installs up to 2018-09-26, so day 7 falls inside the data (data ends 2018-10-03).
WITH installs AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS install_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
activity AS (
  SELECT DISTINCT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS activity_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name IN ('session_start', 'user_engagement')
),
user_days AS (
  SELECT
    i.user_pseudo_id,
    LOGICAL_OR(DATE_DIFF(a.activity_date, i.install_date, DAY) = 1) AS d1,
    LOGICAL_OR(DATE_DIFF(a.activity_date, i.install_date, DAY) = 7) AS d7
  FROM installs i
  LEFT JOIN activity a USING (user_pseudo_id)
  WHERE i.install_date <= DATE '2018-09-26'
  GROUP BY i.user_pseudo_id
)
SELECT
  COUNT(*)                               AS new_users,
  COUNTIF(d1)                            AS d1_users,
  ROUND(COUNTIF(d1) / COUNT(*) * 100, 1) AS d1_pct,
  COUNTIF(d7)                            AS d7_users,
  ROUND(COUNTIF(d7) / COUNT(*) * 100, 1) AS d7_pct
FROM user_days;
