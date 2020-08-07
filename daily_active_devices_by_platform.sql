SELECT
  TIMESTAMP_TRUNC(timestamp, DAY) AS day,
  jsonPayload.fields.platform AS platform,
  COUNT(distinct jsonPayload.fields.device) as dad
FROM
  `moz-fx-guardian-prod-bfc7.log_storage.stdout`
WHERE
  resource.labels.container_name = 'guardian'
  AND jsonPayload.type like "controllers.api.%"
  AND jsonPayload.fields.platform IN ("ANDROID", "WINDOWS", "IOS")
  AND  timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
GROUP BY
  1, 2
ORDER BY 1 desc, 2;
