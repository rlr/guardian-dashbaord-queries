WITH visits AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
    REPLACE(REGEXP_EXTRACT(jsonPayload.request, "[?&]utm_source=([^&]+)"), ' HTTP/1.0', '') as source,
    REPLACE(REGEXP_EXTRACT(jsonPayload.request, "[?&]utm_medium=([^&]+)"), ' HTTP/1.0', '') as medium,
    REPLACE(REGEXP_EXTRACT(jsonPayload.request, "[?&]utm_campaign=([^&]+)"), ' HTTP/1.0', '') as campaign,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'nginx'
    AND jsonPayload.http_host = "vpn.mozilla.org"
    AND jsonPayload.request LIKE "GET %utm_source% HTTP/1.0"
  GROUP BY 1, 2, 3, 4
), conversions AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
    jsonPayload.fields.utm_source as source,
    jsonPayload.fields.utm_medium as medium,
    jsonPayload.fields.utm_campaign as campaign,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
  GROUP BY
    1, 2, 3, 4
  -- ORDER BY 1 desc, 5 desc
)

SELECT
  visits.date as date,
  visits.source as source,
  visits.medium as medium,
  visits.campaign as campaign,
  CONCAT(visits.source, '|', visits.medium, '|', visits.campaign) as combined,
  visits.count as visits,
  CASE
    WHEN conversions.count IS NULL THEN 0
    ELSE conversions.count
  END as conversions,
  CASE
    WHEN conversions.count IS NULL THEN 0
    ELSE (conversions.count / visits.count) * 100
  END as conversion_rate
FROM visits
  LEFT JOIN conversions ON visits.date = conversions.date AND visits.source = conversions.source AND visits.medium = conversions.medium AND visits.campaign = conversions.campaign
WHERE visits.count > 10
ORDER BY 1 DESC, 7 DESC
