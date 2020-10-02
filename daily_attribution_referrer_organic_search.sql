WITH visits AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
    CASE
      WHEN jsonPayload.referrer LIKE "%www.google.%" THEN "google"
      WHEN jsonPayload.referrer LIKE "%duckduckgo.com%" THEN "ddg"
      WHEN jsonPayload.referrer LIKE "%bing.com%" THEN "bing"
    END as referrer,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'nginx'
    AND jsonPayload.http_host = "vpn.mozilla.org"
    AND (
      jsonPayload.referrer LIKE "%www.google.%" OR
      jsonPayload.referrer LIKE "%duckduckgo.com%" OR
      jsonPayload.referrer LIKE "%bing.com%"
    )
  GROUP BY 1, 2
  -- ORDER BY 3 desc
), conversions AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
    CASE
      WHEN jsonPayload.fields.referrer LIKE "%google.%" THEN "google"
      WHEN jsonPayload.fields.referrer LIKE "%duckduckgo.com%" THEN "ddg"
      WHEN jsonPayload.fields.referrer LIKE "%bing.com%" THEN "bing"
    END as referrer,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
    AND (
      jsonPayload.fields.referrer LIKE "%google.%" OR
      jsonPayload.fields.referrer LIKE "%duckduckgo.com%" OR
      jsonPayload.fields.referrer LIKE "%bing.com%"
    )
  GROUP BY
    1, 2
  -- ORDER BY 1 desc, 5 desc
)

SELECT
  visits.date as date,
  visits.referrer as referrer,
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
  LEFT JOIN conversions ON visits.date = conversions.date AND visits.referrer = conversions.referrer
ORDER BY 1 DESC, 3 DESC
