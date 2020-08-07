SELECT
  day,
  count,
  count(distinct fxa_uid) as DAU
FROM (
SELECT
  TIMESTAMP_TRUNC(timestamp, DAY) AS day,
  jsonPayload.fields.fxa_uid as fxa_uid,
  COUNT(distinct jsonPayload.fields.device) AS count
FROM
  `moz-fx-guardian-prod-bfc7.log_storage.stdout`
WHERE
  resource.labels.container_name = 'guardian'
  AND jsonPayload.type like "controllers.api.%"
  and  timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
GROUP BY
  1, 2
)
WHERE count < 6
GROUP BY 1, 2
ORDER BY 1 desc;
