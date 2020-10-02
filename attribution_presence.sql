  SELECT
   CASE
    WHEN jsonPayload.fields.utm_source IS NULL THEN false
    ELSE true
   END as has_source,
   CASE
    WHEN jsonPayload.fields.utm_medium IS NULL THEN false
    ELSE true
   END as has_medium,
   CASE
    WHEN jsonPayload.fields.utm_campaign IS NULL THEN false
    ELSE true
   END as has_campaign,
   CASE
    WHEN jsonPayload.fields.referrer IS NULL THEN false
    ELSE true
   END as has_referrer,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
    AND timestamp >= TIMESTAMP "2020-09-01 00:00:00 UTC"
    AND timestamp < TIMESTAMP "2020-10-01 00:00:00 UTC"
  GROUP BY
    1, 2, 3, 4
  ORDER BY 5 DESC
