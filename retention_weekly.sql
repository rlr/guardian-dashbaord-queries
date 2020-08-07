WITH cohort_count AS (
  SELECT
    EXTRACT(DATE FROM TIMESTAMP_TRUNC(timestamp, WEEK)) AS date,
    count(DISTINCT jsonPayload.fields.fxa_uid) AS count
  FROM
    `moz-fx-guardian-prod-bfc7.log_storage.stdout`
  WHERE
    resource.labels.container_name = 'guardian'
    AND jsonPayload.type like "controllers.api.%"
    AND timestamp >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK), interval 56 day)
    AND timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK)
  GROUP BY 1
)

SELECT * FROM
  (
    SELECT
      date as week,
      period AS week_number,
      new_users AS total_users,
      retained_users,
      retention
    FROM (
      SELECT
        EXTRACT(DATE FROM TIMESTAMP_TRUNC(anow.timestamp, WEEK)) AS date,
        DATE_DIFF(DATE_TRUNC(EXTRACT(DATE FROM athen.timestamp), WEEK), DATE_TRUNC(EXTRACT(DATE FROM anow.timestamp), WEEK), WEEK) AS period,
        max(cohort_size.count) AS new_users,
        count(DISTINCT anow.jsonPayload.fields.fxa_uid) AS retained_users,
        count(DISTINCT anow.jsonPayload.fields.fxa_uid) / max(cohort_size.count) AS retention
      FROM `moz-fx-guardian-prod-bfc7.log_storage.stdout` anow
        LEFT JOIN `moz-fx-guardian-prod-bfc7.log_storage.stdout` AS athen ON
          anow.jsonPayload.fields.fxa_uid = athen.jsonPayload.fields.fxa_uid
          AND anow.timestamp <= athen.timestamp
          AND TIMESTAMP_ADD(anow.timestamp, interval 56 day) >= athen.timestamp
        LEFT JOIN cohort_count AS cohort_size ON
          EXTRACT(DATE FROM anow.timestamp) = cohort_size.date
        WHERE
          anow.resource.labels.container_name = 'guardian'
          AND anow.jsonPayload.type like "controllers.api.%"
          AND athen.resource.labels.container_name = 'guardian'
          AND athen.jsonPayload.type like "controllers.api.%"
          AND athen.timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK)
          AND anow.timestamp < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK)
          AND athen.timestamp >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK), interval 56 day)
          AND anow.timestamp >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), WEEK), interval 56 day)
      GROUP BY 1, 2
    ) t
  WHERE
    period IS NOT NULL
    AND date > DATE_SUB(CURRENT_DATE(), interval 56 day)
    ORDER BY date, period
  );
