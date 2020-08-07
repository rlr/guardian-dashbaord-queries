WITH distribution AS (
  SELECT
    1 as one,
    daysActive as DaysActive,
    COUNT(DISTINCT(fxa_uid)) as Users
  FROM
    (
      SELECT
        jsonPayload.fields.fxa_uid as fxa_uid,
        COUNT(DISTINCT EXTRACT(DATE FROM timestamp)) AS daysActive
      FROM
        `moz-fx-guardian-prod-bfc7.log_storage.stdout`
      WHERE
        resource.labels.container_name = 'guardian'
        AND jsonPayload.type like "controllers.api.%"
        AND timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
        AND timestamp >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY), interval 30 day)
      GROUP BY 1
    )
  GROUP BY 1, 2
),

total AS (
  SELECT
    1 as one,
    COUNT(DISTINCT(jsonPayload.fields.fxa_uid)) as TotalCount
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "controllers.api.%"
    AND timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
    AND timestamp >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY), interval 30 day)
)

SELECT
  DaysActive,
  Users,
  Users / TotalCount as PercentageOfUsers
FROM distribution JOIN total ON total.one = distribution.one
ORDER BY 1 DESC;
