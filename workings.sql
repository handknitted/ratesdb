SELECT * FROM rates;

SELECT r.resource_uri, r.meter_id, r.effective_date, r.rate_value, r.active, r.use_default_rate,
    rd.rate_value AS region_default, rd.effective_date AS rd_effective_date,
    dd.rate_value AS default_rate, dd.effective_date AS dd_effective_date    
FROM rates r 
LEFT OUTER JOIN rates rd ON r.meter_id = r.meter_id AND rd.effective_date < r.effective_date AND rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
LEFT OUTER JOIN rates dd ON r.meter_id = dd.meter_id AND dd.effective_date < r.effective_date AND dd.resource_uri = 'default'
WHERE r.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
ORDER BYr.effective_date ASC, rd_effective_date ASC, dd_effective_date ASC;

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
ORDER BYzone_rate.effective_date ASC, rd_effective_date ASC, dd_effective_date ASC;




SELECT GREATEST(
           IFNULL(zone_rate.effective_date, '01-01-1970'),
           IFNULL(rd_effective_date, '01-01-1970'),
           IFNULL(dd_effective_date, '01-01-1970')) AS rate_start,
  LEAST(IFNULL(zone_rate.next_date, CURRENT_TIMESTAMP),
           IFNULL(rd_next_date, CURRENT_TIMESTAMP),
           IFNULL(dd_next_date, CURRENT_TIMESTAMP)) AS rate_finish,
  zone_rate.zone_rate_value, zone_rate.use_default_rate AS zone_use_df, rd_use_default AS rd_use_df,
  DATE_FORMAT(zone_rate.effective_date, "%d-%m-%Y") AS z_rate_start,
  DATE_FORMAT(zone_rate.next_date, "%d-%m-%Y") AS z_rate_finish,
  DATE_FORMAT(rd_effective_date, "%d-%m-%Y") AS r_rate_start,
  DATE_FORMAT(rd_next_date, "%d-%m-%Y") AS r_rate_finish,
  DATE_FORMAT(dd_effective_date, "%d-%m-%Y") AS df_rate_start,
  DATE_FORMAT(dd_next_date, "%d-%m-%Y") AS df_rate_finish,
  region_default_value, default_value from
  (
    SELECT rz1.resource_uri AS resource_uri, rz1.meter_id AS meter_id, rz1.effective_date AS effective_date,
      (
        SELECT MIN(rz2.effective_date) FROM rates rz2
        WHERE rz2.active = TRUE
              AND rz2.resource_uri = rz1.resource_uri
              AND rz2.meter_id = rz1.meter_id
              AND rz2.effective_date > rz1.effective_date
      ) AS next_date,
      rz1.rate_value AS zone_rate_value,
      rz1.active AS active,
      rz1.use_default_rate AS use_default_rate
    FROM rates rz1
    WHERE rz1.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
    AND rz1.active = TRUE
) AS zone_rate
LEFT OUTER JOIN
  (
    SELECT r1rd.resource_uri AS rd_resource_uri, r1rd.meter_id, r1rd.use_default_rate AS rd_use_default,
      r1rd.effective_date AS rd_effective_date, r1rd.rate_value AS region_default_value,
      (
        SELECT MIN(r2rd.effective_date)
        FROM rates r2rd
        WHERE r2rd.active = TRUE
              AND r2rd.resource_uri = r1rd.resource_uri
              AND r2rd.meter_id = r1rd.meter_id
              AND r2rd.effective_date > r1rd.effective_date
      ) AS rd_next_date
    FROM rates r1rd
    WHERE r1rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
  ) AS rd ON zone_rate.meter_id = rd.meter_id
             AND rd_effective_date < zone_rate.next_date
             AND zone_rate.use_default_rate = TRUE
            AND rd_use_default = TRUE
LEFT OUTER JOIN
    (
      SELECT r1dd.resource_uri AS dd_resource_uri, r1dd.meter_id, r1dd.effective_date AS dd_effective_date, r1dd.rate_value AS default_value,
        (
          SELECT MIN(r2dd.effective_date) FROM rates r2dd
          WHERE r2dd.active = TRUE
                AND r2dd.resource_uri = r1dd.resource_uri
                AND r2dd.meter_id = r1dd.meter_id
                AND r2dd.effective_date > r1dd.effective_date
        ) AS dd_next_date
      FROM rates r1dd
      WHERE r1dd.resource_uri = 'default'
    ) AS dd
      ON zone_rate.meter_id = dd.meter_id
         AND dd_effective_date < zone_rate.next_date
#          AND zone_rate.use_default_rate = TRUE
ORDER BY zone_rate.effective_date ASC, rd_effective_date ASC, dd_effective_date ASC;

