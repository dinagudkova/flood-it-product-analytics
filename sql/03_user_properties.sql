-- 03_user_properties: user property keys (settings, experiment membership)
SELECT
  up.key,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT COALESCE(up.value.string_value, CAST(up.value.int_value AS STRING))) AS distinct_values
FROM `firebase-public-project.analytics_153293282.events_*`, UNNEST(user_properties) AS up
GROUP BY up.key
ORDER BY users DESC;
