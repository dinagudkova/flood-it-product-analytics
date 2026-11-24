-- 04c_exp1_ad_frequency_check: which ad_frequency value each exp_1 variant actually carried
-- (counted per event, so a few odd events cannot hide the main value)
SELECT
  (SELECT value.string_value FROM UNNEST(user_properties) WHERE key = 'firebase_exp_1') AS variant,
  (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
     FROM UNNEST(user_properties) WHERE key = 'ad_frequency') AS ad_frequency,
  COUNT(*)                       AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE EXISTS (SELECT 1 FROM UNNEST(user_properties) WHERE key = 'firebase_exp_1')
GROUP BY variant, ad_frequency
ORDER BY variant, events DESC;
