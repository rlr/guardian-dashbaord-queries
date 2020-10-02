  SELECT
   jsonPayload.fields.referrer,
   count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
    AND timestamp >= TIMESTAMP "2020-09-01 00:00:00 UTC"
    AND timestamp < TIMESTAMP "2020-10-01 00:00:00 UTC"
    AND jsonPayload.fields.utm_source IS NULL
    AND jsonPayload.fields.utm_medium IS NULL
    AND jsonPayload.fields.utm_campaign IS NULL
  GROUP BY
    1
  ORDER BY 2 DESC
