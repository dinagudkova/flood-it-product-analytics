-- 04_experiment_groups: players per Firebase experiment and variant,
-- plus players seen in more than one variant of the same experiment (contamination)
WITH exp AS (
  SELECT DISTINCT
    user_pseudo_id,
    up.key                 AS experiment,
    up.value.string_value  AS variant
  FROM `firebase-public-project.analytics_153293282.events_*`, UNNEST(user_properties) AS up
  WHERE up.key LIKE 'firebase_exp_%'
),
per_user AS (
  SELECT experiment, user_pseudo_id, COUNT(DISTINCT variant) AS n_variants
  FROM exp
  GROUP BY experiment, user_pseudo_id
)
SELECT
  e.experiment,
  e.variant,
  COUNT(DISTINCT e.user_pseudo_id)                              AS users,
  COUNT(DISTINCT IF(p.n_variants > 1, e.user_pseudo_id, NULL))  AS users_in_several_variants
FROM exp e
JOIN per_user p USING (experiment, user_pseudo_id)
GROUP BY e.experiment, e.variant
ORDER BY e.experiment, e.variant;
