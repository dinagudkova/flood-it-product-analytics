-- 02_event_names: which events exist and how many players triggered each
SELECT
  event_name,
  COUNT(*)                       AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY event_name
ORDER BY events DESC;
