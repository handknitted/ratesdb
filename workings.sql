SELECT * FROM rates;

SELECT r.resource_uri, r.meter_id, r.effective_date, r.rate_value, r.active, r.use_default_rate,
    rd.rate_value AS region_default, rd.effective_date AS rd_effective_date,
    dd.rate_value AS default_rate, dd.effective_date AS dd_effective_date    
FROM rates r 
LEFT OUTER JOIN rates rd ON r.meter_id = r.meter_id AND rd.effective_date < r.effective_date AND rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
LEFT OUTER JOIN rates dd ON r.meter_id = dd.meter_id AND dd.effective_date < r.effective_date AND dd.resource_uri = 'default'
WHERE r.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
ORDER BY r.effective_date ASC, rd_effective_date ASC, dd_effective_date ASC;

SELECT r.resource_uri, r.meter_id, r.effective_date, (SELECT MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) AS next_date, r.rate_value
FROM rates r;




SELECT zone_rate.resource_uri, zone_rate.meter_id, zone_rate.zone_rate_value, zone_rate.active, zone_rate.use_default_rate, rd.use_default_rate AS rd_use_default,
    zone_rate.effective_date, zone_rate.next_date, rd.effective_date AS rd_effective_date, dd.effective_date AS dd_effective_date, rd.rate_value AS region_default, 
    dd.rate_value AS default_rate FROM (
SELECT r.resource_uri AS resource_uri, r.meter_id AS meter_id, r.effective_date AS effective_date, (SELECT MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) AS next_date, r.rate_value AS zone_rate_value, r.active AS active, r.use_default_rate AS use_default_rate
FROM rates r 
) AS zone_rate   
LEFT OUTER JOIN rates rd ON zone_rate.meter_id = rd.meter_id AND rd.effective_date < zone_rate.next_date AND zone_rate.use_default_rate = TRUE AND rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
LEFT OUTER JOIN rates dd ON zone_rate.meter_id = dd.meter_id AND dd.effective_date < zone_rate.next_date AND zone_rate.use_default_rate = TRUE AND dd.resource_uri = 'default'
WHERE zone_rate.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327' AND zone_rate.active = TRUE
ORDER BY zone_rate.effective_date ASC, rd_effective_date ASC, dd_effective_date ASC;

SELECT
  GREATEST(
      IFNULL(zone_rate.effective_date, '01-01-1970'),
      IFNULL(zone_rate.rd_effective_date, '01-01-1970'),
      IFNULL(dd_effective_date, '01-01-1970'))      AS rate_start,
  LEAST(IFNULL(zone_rate.next_date, CURRENT_TIMESTAMP),
        IFNULL(rd_next_date, CURRENT_TIMESTAMP),
        IFNULL(dd_next_date, CURRENT_TIMESTAMP))    AS rate_finish,
  zone_rate.zone_rate_value,
  zone_rate.use_default_rate                        AS zone_use_df,
  rd_use_default                                    AS rd_use_df,
  DATE_FORMAT(zone_rate.effective_date, "%d-%m-%Y") AS z_rate_start,
  DATE_FORMAT(zone_rate.next_date, "%d-%m-%Y")      AS z_rate_finish,
  DATE_FORMAT(rd_effective_date, "%d-%m-%Y")        AS r_rate_start,
  DATE_FORMAT(rd_next_date, "%d-%m-%Y")             AS r_rate_finish,
  DATE_FORMAT(dd_effective_date, "%d-%m-%Y")        AS df_rate_start,
  DATE_FORMAT(dd_next_date, "%d-%m-%Y")             AS df_rate_finish,
  region_default_value,
  default_value
FROM
  (
    SELECT
      rz1.resource_uri     AS resource_uri,
      rz1.meter_id         AS meter_id,
      rz1.effective_date   AS effective_date,
      (
        SELECT MIN(rz2.effective_date)
        FROM rates rz2
        WHERE rz2.active = TRUE
              AND rz2.resource_uri = rz1.resource_uri
              AND rz2.meter_id = rz1.meter_id
              AND rz2.effective_date > rz1.effective_date
      )                    AS next_date,
      rz1.rate_value       AS zone_rate_value,
      rz1.active           AS active,
      rz1.use_default_rate AS use_default_rate,
      rd.rd_resource_uri, rd.rd_use_default, rd.rd_effective_date, rd.region_default_value, rd.rd_next_date,
      dd.dd_resource_uri, dd.dd_effective_date, dd.default_value, dd.dd_next_date
    FROM rates rz1
      LEFT OUTER JOIN
      (
        SELECT
          r1rd.resource_uri     AS rd_resource_uri,
          r1rd.meter_id,
          r1rd.use_default_rate AS rd_use_default,
          r1rd.effective_date   AS rd_effective_date,
          r1rd.rate_value       AS region_default_value,
          (
            SELECT MIN(r2rd.effective_date)
            FROM rates r2rd
            WHERE r2rd.active = TRUE
                  AND r2rd.resource_uri = r1rd.resource_uri
                  AND r2rd.meter_id = r1rd.meter_id
                  AND r2rd.effective_date > r1rd.effective_date
          )                     AS rd_next_date
        FROM rates r1rd
        WHERE r1rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
      ) AS rd ON rz1.meter_id = rd.meter_id
                 AND rz1.use_default_rate = TRUE
                 AND rd_use_default = TRUE
      LEFT OUTER JOIN
      (
        SELECT
          r1dd.resource_uri   AS dd_resource_uri,
          r1dd.meter_id,
          r1dd.effective_date AS dd_effective_date,
          r1dd.rate_value     AS default_value,
          (
            SELECT MIN(r2dd.effective_date)
            FROM rates r2dd
            WHERE r2dd.active = TRUE
                  AND r2dd.resource_uri = r1dd.resource_uri
                  AND r2dd.meter_id = r1dd.meter_id
                  AND r2dd.effective_date > r1dd.effective_date
          )                   AS dd_next_date
        FROM rates r1dd
        WHERE r1dd.resource_uri = 'default'
      ) AS dd
        ON rz1.meter_id = dd.meter_id
    #          AND zone_rate.use_default_rate = TRUE
    WHERE rz1.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
          AND rz1.active = TRUE
  ) AS zone_rate;

SELECT

  GREATEST(
      IFNULL(zone_rate.effective_date, '01-01-1970'),
#       IFNULL(zone_rate.rrd_during_effective_date, '01-01-1970'),
      IFNULL(zone_rate.default_effective_date, '01-01-1970'))      AS rate_start,
  LEAST(IFNULL(zone_rate.next_date, CURRENT_TIMESTAMP),
        IFNULL(zone_rate.rrd_before_next_date, CURRENT_TIMESTAMP),
        IFNULL(zone_rate.default_next_date, CURRENT_TIMESTAMP))    AS rate_finish,
  zone_rate.rate_value,
  zone_rate.use_default_rate                        AS zone_use_df,
#   zone_rate.rrd_before_use_default OR zone_rate.rrd_during_use_default AS rd_use_default,
  DATE_FORMAT(zone_rate.effective_date, '%d-%m-%Y') AS z_rate_start,
  DATE_FORMAT(zone_rate.next_date, '%d-%m-%Y')      AS z_rate_finish,
#   DATE_FORMAT(IFNULL(zone_rate.rrd_before_effective_date, zone_rate.rrd_during_effective_date), '%d-%m-%Y')        AS r_rate_start,
#   DATE_FORMAT(IFNULL(zone_rate.rrd_before_next_date, zone_rate.rrd_during_effective_date), '%d-%m-%Y')             AS r_rate_finish,
  DATE_FORMAT(zone_rate.default_effective_date, '%d-%m-%Y')        AS df_rate_start,
  DATE_FORMAT(zone_rate.default_next_date, '%d-%m-%Y')             AS df_rate_finish
FROM
  (
    SELECT
      zrd.meter_id,
      zrd.rate_value,
      zrd.effective_date,
      zrd.next_date,
      zrd.use_default_rate,
      rrd_before.effective_date as rrd_before_effective_date,
      rrd_before.next_date as rrd_before_next_date,
      rrd_before.use_default_rate as rrd_before_use_default,
#       rrd_during.effective_date as rrd_during_effective_date,
#       rrd_during.next_date as rrd_during_next_date,
#       rrd_during.use_default_rate as rrd_during_use_default,
      drd.effective_date as default_effective_date,
      drd.next_date as default_next_date
    FROM rate_dates zrd
      LEFT JOIN rate_dates rrd_before
        ON rrd_before.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
           AND zrd.meter_id = rrd_before.meter_id
           AND zrd.use_default_rate = TRUE
           AND rrd_before.effective_date < zrd.next_date
           AND rrd_before.next_date > zrd.effective_date
#       LEFT OUTER JOIN rate_dates rrd_during
#         ON rrd_during.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
#            AND zrd.meter_id = rrd_during.meter_id
#            AND zrd.use_default_rate = TRUE
#            AND rrd_during.effective_date < zrd.next_date
#            AND rrd_during.effective_date >= zrd.effective_date
      LEFT OUTER JOIN rate_dates drd ON drd.resource_uri = 'default'
                                        AND zrd.meter_id = drd.meter_id
      AND zrd.effective_date > drd.effective_date
      AND drd.next_date > zrd.effective_date
      AND zrd.use_default_rate = TRUE
      AND (rrd_before.use_default_rate IS NULL OR rrd_before.use_default_rate = TRUE)
#       AND (rrd_during.use_default_rate IS NULL OR rrd_during.use_default_rate = TRUE)
    WHERE zrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
          AND zrd.active = TRUE
    ORDER BY zrd.effective_date
  ) AS zone_rate
  ORDER BY rate_start ASC;


# success with the default rates alone
SELECT * FROM rate_dates zrd
  LEFT OUTER JOIN rate_dates drd
  ON zrd.meter_id = drd.meter_id
  AND zrd.use_default_rate = TRUE
  AND drd.resource_uri = 'default'
WHERE zrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
AND zrd.meter_id = 'ncs.resource.annual.cost'
AND zrd.active = TRUE
AND (drd.use_default_rate IS NULL OR drd.resource_uri = 'default');

# success with the region defaults alone
SELECT
  DATE_FORMAT(zrd.effective_date, '%d-%m-%Y') AS ZRED,
  DATE_FORMAT(zrd.next_date, '%d-%m-%Y') AS ZRND,
  zrd.rate_value AS ZVAL,zrd.use_default_rate AS ZDEFAULT,
  rrd.use_default_rate AS RDEFAULT,
  DATE_FORMAT(rrd.effective_date, '%d-%m-%Y') AS RRED,
  DATE_FORMAT(rrd.next_date, '%d-%m-%Y') AS RRND,
  zrd.resource_uri, rrd.rate_value, rrd.resource_uri
FROM rate_dates zrd
  LEFT OUTER JOIN rate_dates rrd
  ON zrd.use_default_rate = TRUE
  AND zrd.meter_id = rrd.meter_id
  AND zrd.effective_date > rrd.effective_date
#   LEFT OUTER JOIN rate_dates drd
#   ON ((rrd.use_default_rate = TRUE OR (zrd.use_default_rate = TRUE AND rrd.use_default_rate IS NULL))
#   AND zrd.meter_id = drd.meter_id)

WHERE zrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
# AND (rrd.resource_uri IS NULL OR rrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7')
      AND zrd.active = TRUE
#   AND (rrd.resource_uri IS NULL OR rrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7')

  AND zrd.meter_id = 'ncs.resource.annual.cost'
ORDER BY zrd.effective_date;
#   , rrd.effective_date ASC;
# AND (rrd.use_default_rate IS NULL OR rrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7');





SELECT * FROM rate_dates WHERE resource_uri = 'default' AND meter_id = 'ncs.resource.annual.cost';

CREATE OR REPLACE VIEW rate_dates AS SELECT
  r1dd.id as id,
          r1dd.resource_uri   AS resource_uri,
  r1dd.resource_terminated as resource_terminated,
  r1dd.name as name,
  r1dd.unit as unit,
  r1dd.active as active,
  r1dd.use_default_rate as use_default_rate,
          r1dd.meter_id,
          r1dd.effective_date AS effective_date,
          r1dd.rate_value     AS rate_value,
          (
            SELECT MIN(r2dd.effective_date)
            FROM rates r2dd
            WHERE r2dd.active = TRUE
                  AND r2dd.resource_uri = r1dd.resource_uri
                  AND r2dd.meter_id = r1dd.meter_id
                  AND r2dd.effective_date > r1dd.effective_date
          )                   AS next_date
        FROM rates r1dd;

SELECT * FROM rate_dates;

DESCRIBE rates;

DROP TABLE default_rates;
CREATE TEMPORARY TABLE IF NOT EXISTS default_rates AS (SELECT
          r1dd.resource_uri   AS dd_resource_uri,
          r1dd.meter_id,
          r1dd.effective_date AS dd_effective_date,
          r1dd.rate_value     AS default_value,
          (
            SELECT MIN(r2dd.effective_date)
            FROM rates r2dd
            WHERE r2dd.active = TRUE
                  AND r2dd.resource_uri = r1dd.resource_uri
                  AND r2dd.meter_id = r1dd.meter_id
                  AND r2dd.effective_date > r1dd.effective_date
          )                   AS dd_next_date
        FROM rates r1dd
        WHERE r1dd.resource_uri = 'default'
AND meter_id = 'ncs.resource.annual.cost');

SELECT * FROM default_rates;


# success with the regional default defaults
SELECT
  zrd.use_default_rate AS z_use_def,
  zrd.resource_uri AS z_res_uri,
  zrd.effective_date AS z_eff,
  zrd.next_date AS z_nexd,
  zrd.rate_value AS z_val,
  rrd.use_default_rate AS r_use_def,
  rrd.resource_uri AS r_res_uri,
  rrd.effective_date AS r_eff,
  rrd.next_date AS r_nexd,
  rrd.rate_value AS r_val
FROM rate_dates zrd
  LEFT OUTER JOIN rate_dates rrd
    ON zrd.meter_id = rrd.meter_id
       AND zrd.use_default_rate = TRUE
       AND rrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'

      WHERE zrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
            AND zrd.active = TRUE
UNION SELECT
        uzrd.use_default_rate AS z_use_def,
        uzrd.resource_uri AS z_res_uri,
        uzrd.effective_date AS z_eff,
        uzrd.next_date AS z_nexd,
        uzrd.rate_value AS z_val,
        urrd.use_default_rate AS r_use_def,
        urrd.resource_uri AS r_res_uri,
        urrd.effective_date AS r_eff,
        urrd.next_date AS r_nexd,
        urrd.rate_value AS r_val
      FROM rate_dates uzrd
        LEFT OUTER JOIN rate_dates urrd
          ON uzrd.meter_id = urrd.meter_id
             AND uzrd.use_default_rate = TRUE
             AND (urrd.resource_uri IS NULL OR urrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7')
             AND urrd.effective_date < uzrd.effective_date
      WHERE uzrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
            AND uzrd.active = TRUE
ORDER BY z_eff, r_eff ASC;


# success with the regional and default defaults - albeit with a DISTINCT and a little bit of optimism
SELECT DISTINCT
  IF(NOT z_use_def, z_val,
     IF(ISNULL(r_use_def) OR r_use_def, drd.rate_value, r_val)) AS RATE,
  GREATEST(IFNULL(r_eff, '01-01-1970'), z_eff, IFNULL(drd.effective_date, '01-01-1970')) AS EFF_DATE
#   z_id,
#   z_use_def,
#   z_eff,
#   z_nexd,
#   z_val,
#   r_id,
#   r_use_def,
#   r_res_uri,
#   r_eff,
#   r_nexd,
#   r_val,
#   drd.id AS d_id,
#   drd.effective_date AS d_eff,
#   drd.next_date      AS d_nexd,
#   drd.rate_value     AS d_val
FROM (
       SELECT
         zrd.id AS z_id,
         zrd.meter_id         AS meter_id,
         zrd.use_default_rate AS z_use_def,
         zrd.resource_uri     AS z_res_uri,
         zrd.effective_date   AS z_eff,
         zrd.next_date        AS z_nexd,
         zrd.rate_value       AS z_val,
         rrd.id AS r_id,
         rrd.use_default_rate AS r_use_def,
         rrd.resource_uri     AS r_res_uri,
         rrd.effective_date   AS r_eff,
         rrd.next_date        AS r_nexd,
         rrd.rate_value       AS r_val
       FROM rate_dates zrd
         LEFT OUTER JOIN rate_dates rrd
           ON zrd.meter_id = rrd.meter_id
              AND zrd.use_default_rate = TRUE
              AND rrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'

       WHERE zrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
             AND zrd.active = TRUE
       # this union is to pick up default rates in the absence of or prior to any
       #  region default rates, unfortunately it causes duplicates
       UNION SELECT
               uzrd.id AS z_id,
               uzrd.meter_id         AS meter_id,
               uzrd.use_default_rate AS z_use_def,
               uzrd.resource_uri     AS z_res_uri,
               uzrd.effective_date   AS z_eff,
               uzrd.next_date        AS z_nexd,
               uzrd.rate_value       AS z_val,
               urrd.id AS r_id,
               urrd.use_default_rate AS r_use_def,
               urrd.resource_uri     AS r_res_uri,
               urrd.effective_date   AS r_eff,
               urrd.next_date        AS r_nexd,
               urrd.rate_value       AS r_val
             FROM rate_dates uzrd
               LEFT OUTER JOIN rate_dates urrd
                 ON uzrd.meter_id = urrd.meter_id
                    AND uzrd.use_default_rate = TRUE
                    AND
#                     (
                      urrd.resource_uri IS NULL
#                       OR
#                      urrd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7')
                    AND urrd.effective_date < uzrd.effective_date
             WHERE uzrd.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
                   AND uzrd.active = TRUE
       ORDER BY z_eff, r_eff ASC
     ) AS starting_point
  LEFT OUTER JOIN rate_dates drd
    ON starting_point.meter_id = drd.meter_id
       # TODO it's the AND  (starting_point.r_use_def IS NULL
       # TODO that is causing the duplicate record here
       # TODO and necessitating the SELECT DISTINCT
       AND (starting_point.z_use_def = TRUE AND (starting_point.r_use_def IS NULL OR starting_point.r_use_def IS TRUE))
       AND drd.resource_uri = 'default'
ORDER BY EFF_DATE ASC;
