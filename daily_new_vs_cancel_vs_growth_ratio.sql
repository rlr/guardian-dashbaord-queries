WITH new_subs AS (
  SELECT
    EXTRACT(date from timestamp) AS new_date,
    COUNT(distinct jsonPayload.fields.fxa_uid) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
    AND timestamp >= TIMESTAMP "2020-05-06"
  AND  timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
  GROUP BY
    1
), cancelled_subs AS (
  SELECT
    EXTRACT(date from timestamp) AS cancelled_date,
    COUNT(distinct jsonPayload.fields.fxa_uid) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "controllers.webhook.subscription-deactivated"
    AND timestamp >= TIMESTAMP "2020-05-06"
  AND  timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
  GROUP BY
    1
)

SELECT
  new_date as date,
  new_subs.count as new_subs,
  cancelled_subs.count as cancelled_subs,
  ROUND(new_subs.count / cancelled_subs.count, 3) as growth_ratio
from new_subs
INNER JOIN cancelled_subs ON new_date = cancelled_date
ORDER BY 1 DESC
