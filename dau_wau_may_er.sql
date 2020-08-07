WITH dates_list AS (
  Select *
  FROM UNNEST(GENERATE_DATE_ARRAY('2020-01-01', DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY))) AS dates
),
usage_dates AS (
  SELECT
    EXTRACT(date from timestamp) AS date,
    jsonPayload.fields.fxa_uid AS users
FROM
  `moz-fx-guardian-prod-bfc7.log_storage.stdout`
WHERE
  resource.labels.container_name = 'guardian'
  AND jsonPayload.type like "controllers.api.%"
GROUP BY
  1,2
ORDER BY
  2 Desc
),
dau_calcs AS (
  SELECT
   dates_list.dates as dau_date,
   COUNT(distinct users) as DAU,
  FROM dates_list
  INNER JOIN usage_dates
  ON (usage_dates.date = dates_list.dates)
  GROUP BY 1
),
wau_calcs AS (
  SELECT
   dates_list.dates as wau_date,
   COUNT(distinct users) as WAU,
  FROM dates_list
  INNER JOIN usage_dates
  ON (usage_dates.date <= dates_list.dates) and (usage_dates.date >= date_sub(dates_list.dates, interval 7 day))
  GROUP BY 1
),
mau_calcs AS (
  SELECT
    dates_list.dates as mau_date,
    COUNT(distinct users) as MAU,
  FROM dates_list
  INNER JOIN usage_dates
  ON (usage_dates.date <= dates_list.dates) and (usage_dates.date >= date_sub(dates_list.dates, interval 30 day))
  GROUP by 1
)

SELECT
  mau_date as date,
  MAU,
  WAU,
  DAU,
  ROUND(dau_calcs.dau / mau_calcs.mau, 3) as ER
from mau_calcs
INNER JOIN wau_calcs
ON (mau_calcs.mau_date = wau_calcs.wau_date)
INNER JOIN dau_calcs
ON (dau_calcs.dau_date = mau_calcs.mau_date)
ORDER BY 1 ASC;
