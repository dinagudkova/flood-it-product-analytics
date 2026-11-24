-- 01_dataset_overview: size and time range of the dataset
SELECT
  COUNT(*)                                                  AS events,
  COUNT(DISTINCT user_pseudo_id)                            AS users,
  COUNT(DISTINCT IF(event_name = 'first_open', user_pseudo_id, NULL)) AS new_installs,
  MIN(PARSE_DATE('%Y%m%d', event_date))                     AS first_day,
  MAX(PARSE_DATE('%Y%m%d', event_date))                     AS last_day,
  COUNT(DISTINCT event_date)                                AS days
FROM `firebase-public-project.analytics_153293282.events_*`;
