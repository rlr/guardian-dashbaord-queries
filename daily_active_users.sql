SELECT
  TIMESTAMP_TRUNC(timestamp, DAY) AS day,
  COUNT(distinct jsonPayload.fields.fxa_uid) as dau
FROM
  `moz-fx-guardian-prod-bfc7.log_storage.stdout`
WHERE
  resource.labels.container_name = 'guardian'
  AND jsonPayload.type like "controllers.api.%"
  and  timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
GROUP BY
  1
ORDER BY 1 desc;
