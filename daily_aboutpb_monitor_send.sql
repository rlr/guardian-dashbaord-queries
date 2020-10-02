WITH visits AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
  CASE
    WHEN jsonPayload.request LIKE "%utm_source=monitor.firefox.com%" THEN 'monitor'
    WHEN jsonPayload.request LIKE "%utm_source=send.firefox.com%" THEN 'send'
    WHEN jsonPayload.request LIKE "%utm_medium=firefox-release-browser%" THEN 'about:pb:release'
    WHEN jsonPayload.request LIKE "%utm_medium=firefox-beta-browser%" THEN 'about:pb:beta'
    WHEN jsonPayload.request LIKE "%utm_medium=firefox-nightly-browser%" THEN 'about:pb:nightly'
   END as source,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'nginx'
    AND (jsonPayload.request IN ("GET /?utm_source=firefox-browser&utm_medium=firefox-nightly-browser&utm_campaign=private-browsing-vpn-link HTTP/1.0", "GET /?utm_source=firefox-browser&utm_medium=firefox-beta-browser&utm_campaign=private-browsing-vpn-link HTTP/1.0", "GET /?utm_source=firefox-browser&utm_medium=firefox-release-browser&utm_campaign=private-browsing-vpn-link HTTP/1.0", "GET /?utm_source=monitor.firefox.com&utm_medium=referral&utm_content=Try+Mozilla+VPN&utm_campaign=contextual-recommendations HTTP/1.0")
    OR jsonPayload.request LIKE "GET /?%utm_source=send.firefox.com% HTTP/1.0")
  GROUP BY 1, 2
), conversions AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, DAY)) AS date,
  CASE
    WHEN jsonPayload.fields.utm_source = "monitor.firefox.com" THEN 'monitor'
    WHEN jsonPayload.fields.utm_source = "send.firefox.com" THEN 'send'
    WHEN jsonPayload.fields.utm_medium = "firefox-release-browser" THEN 'about:pb:release'
    WHEN jsonPayload.fields.utm_medium = "firefox-beta-browser" THEN 'about:pb:beta'
    WHEN jsonPayload.fields.utm_medium = "firefox-nightly-browser" THEN 'about:pb:nightly'
   END as source,
    count(*) as count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "lib.utils.subscription-activated"
    AND (
      jsonPayload.fields.utm_source = "monitor.firefox.com"
      OR jsonPayload.fields.utm_campaign = "private-browsing-vpn-link"
      OR jsonPayload.fields.utm_source = "send.firefox.com"
    )
  GROUP BY
    1, 2
)

SELECT
  visits.date as date,
  visits.source as source,
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
  LEFT JOIN conversions ON visits.date = conversions.date AND visits.source = conversions.source
ORDER BY 1 DESC;
