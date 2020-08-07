WITH latest AS (
  SELECT
    1 as joiner,
    timestamp,
    jsonPayload.fields.activeSubscriptions,
    jsonPayload.fields.activatedDevices,
    jsonPayload.fields.waitlistCount
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type = "bin.update_metrics.metrics"
  ORDER BY 2 desc
  LIMIT 1
), yesterday AS (
  SELECT
    1 as joiner,
    timestamp,
    jsonPayload.fields.activeSubscriptions,
    jsonPayload.fields.activatedDevices,
    jsonPayload.fields.waitlistCount
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type = "bin.update_metrics.metrics"
    AND timestamp <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
  ORDER BY 2 desc
  LIMIT 1
), twodaysago AS (
  SELECT
    1 as joiner,
    timestamp,
    jsonPayload.fields.activeSubscriptions,
    jsonPayload.fields.activatedDevices,
    jsonPayload.fields.waitlistCount
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type = "bin.update_metrics.metrics"
    AND timestamp <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
  ORDER BY 2 desc
  LIMIT 1
), lastweek AS (
  SELECT
    1 as joiner,
    timestamp,
    jsonPayload.fields.activeSubscriptions,
    jsonPayload.fields.activatedDevices,
    jsonPayload.fields.waitlistCount
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type = "bin.update_metrics.metrics"
    AND timestamp <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  ORDER BY 2 desc
  LIMIT 1
)

SELECT
  latest.activeSubscriptions as Customers,
  latest.activatedDevices as Devices,
  latest.waitlistCount as Waitlist,
  latest.activeSubscriptions - yesterday.activeSubscriptions as NewCustomers24h,
  latest.activatedDevices - yesterday.activatedDevices as NewDevices24h,
  latest.waitlistCount - yesterday.waitlistCount as NewWaitlist24h,
  latest.activeSubscriptions - twodaysago.activeSubscriptions as NewCustomers24to48h,
  latest.activatedDevices - twodaysago.activatedDevices as NewDevices24to48h,
  latest.waitlistCount - twodaysago.waitlistCount as NewWaitlist24to48h,
  latest.activeSubscriptions - lastweek.activeSubscriptions as NewCustomers7d,
  latest.activatedDevices - lastweek.activatedDevices as NewDevices7d,
  latest.waitlistCount - lastweek.waitlistCount as NewWaitlist7d
FROM latest
  INNER JOIN yesterday ON latest.joiner = yesterday.joiner
  INNER JOIN twodaysago ON latest.joiner = twodaysago.joiner
  INNER JOIN lastweek ON latest.joiner = lastweek.joiner;
