select * from rates;

select r.resource_uri, r.meter_id, r.effective_date, r.rate_value, r.active, r.use_default_rate,
    rd.rate_value as region_default, rd.effective_date as rd_effective_date,
    dd.rate_value as default_rate, dd.effective_date as dd_effective_date    
from rates r 
left outer join rates rd on r.meter_id = r.meter_id and rd.effective_date < r.effective_date and rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
left outer join rates dd on r.meter_id = dd.meter_id and dd.effective_date < r.effective_date and dd.resource_uri = 'default'
where r.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327'
order by r.effective_date asc, rd_effective_date asc, dd_effective_date asc;

select r.resource_uri, r.meter_id, r.effective_date, (select MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) as next_date, r.rate_value
from rates r




select zone_rate.resource_uri, zone_rate.meter_id, zone_rate.zone_rate_value, zone_rate.active, zone_rate.use_default_rate, rd.use_default_rate as rd_use_default,
    zone_rate.effective_date, zone_rate.next_date, rd.effective_date as rd_effective_date, dd.effective_date as dd_effective_date, rd.rate_value as region_default, 
    dd.rate_value as default_rate from (
select r.resource_uri as resource_uri, r.meter_id as meter_id, r.effective_date as effective_date, (select MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) as next_date, r.rate_value as zone_rate_value, r.active as active, r.use_default_rate as use_default_rate
from rates r 
) as zone_rate   
left outer join rates rd on zone_rate.meter_id = rd.meter_id and rd.effective_date < zone_rate.next_date and zone_rate.use_default_rate = TRUE and rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
left outer join rates dd on zone_rate.meter_id = dd.meter_id and dd.effective_date < zone_rate.next_date and zone_rate.use_default_rate = TRUE and dd.resource_uri = 'default'
where zone_rate.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327' and zone_rate.active = TRUE
order by zone_rate.effective_date asc, rd_effective_date asc, dd_effective_date asc;


select zone_rate.resource_uri, zone_rate.meter_id, zone_rate.zone_rate_value, zone_rate.active, zone_rate.use_default_rate, rd_use_default,
    zone_rate.effective_date, zone_rate.next_date, rd_effective_date, rd_next_date, dd_effective_date, region_default_value, 
    default_value from (
select r.resource_uri as resource_uri, r.meter_id as meter_id, r.effective_date as effective_date, (select MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) as next_date, r.rate_value as zone_rate_value, r.active as active, r.use_default_rate as use_default_rate
from rates r 
) as zone_rate   
left outer join (select resource_uri as rd_resource_uri, meter_id, use_default_rate as rd_use_default, effective_date as rd_effective_date, rate_value as region_default_value, (select MIN(r2.effective_date) FROM rates r2
WHERE r2.active = TRUE AND r2.resource_uri = r.resource_uri AND r2.meter_id = r.meter_id
AND r2.effective_date > r.effective_date) as rd_next_date from rates where resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7') as rd on zone_rate.meter_id = rd.meter_id and rd_effective_date < zone_rate.next_date and zone_rate.use_default_rate = TRUE
left outer join (select resource_uri as dd_resource_uri, meter_id, effective_date as dd_effective_date, rate_value as default_value from rates where resource_uri = 'default') as dd on zone_rate.meter_id = dd.meter_id and dd_effective_date < zone_rate.next_date and zone_rate.use_default_rate = TRUE
where zone_rate.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327' and zone_rate.active = TRUE
order by zone_rate.effective_date asc, rd_effective_date asc, dd_effective_date asc;


