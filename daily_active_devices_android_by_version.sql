SELECT
  TIMESTAMP_TRUNC(timestamp, DAY) AS day,
  SUBSTR(REGEXP_EXTRACT(jsonPayload.fields.useragent, r"\/\s?[()a-zA-Z0-9_.+-]+"), 2) as version,
  COUNT(distinct jsonPayload.fields.device) as DAD
FROM
  `moz-fx-guardian-prod-bfc7.log_storage.stdout`
WHERE
  resource.labels.container_name = 'guardian'
  AND jsonPayload.type like "controllers.api.%"
  AND jsonPayload.fields.platform = "ANDROID"
  AND (jsonPayload.fields.useragent like 'Guardian%' OR jsonPayload.fields.useragent like 'FirefoxPrivateNetworkVPN%')
GROUP BY
  1, 2
ORDER BY 1 desc, 2, 3;
