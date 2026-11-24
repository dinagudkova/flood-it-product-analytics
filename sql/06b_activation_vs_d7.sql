-- 06b_activation_vs_d7: D7 retention of new players who completed 5 levels within 24 hours vs the rest
-- The 24-hour window avoids reverse causality (retained players simply have more time to complete levels).
WITH installs AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS install_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING MIN(PARSE_DATE('%Y%m%d', event_date)) <= DATE '2018-09-26'
),
per_user AS (
  SELECT
    i.user_pseudo_id,
    LOGICAL_OR(e.event_name = 'completed_5_levels'
               AND e.event_timestamp < i.install_ts + 24 * 60 * 60 * 1000000) AS five_levels_24h,
    LOGICAL_OR(e.event_name IN ('session_start', 'user_engagement')
               AND DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), i.install_date, DAY) = 7) AS d7
  FROM installs i
  JOIN `firebase-public-project.analytics_153293282.events_*` e USING (user_pseudo_id)
  GROUP BY i.user_pseudo_id
)
SELECT
  five_levels_24h,
  COUNT(*)                               AS users,
  COUNTIF(d7)                            AS d7_users,
  ROUND(COUNTIF(d7) / COUNT(*) * 100, 1) AS d7_pct
FROM per_user
GROUP BY five_levels_24h
ORDER BY five_levels_24h;
