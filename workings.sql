select * from rates;

select r.resource_uri, r.meter_id, r.effective_date, r.rate_value, r.active, r.use_default_rate from rates r 
inner join rates rd on r.meter_id = r.meter_id and rd.resource_uri = '/rest/regions/fa491f92-3fbf-4715-befc-bae1f65ec0b7'
where r.resource_uri = '/rest/zones/f9ba9f8b-d4be-48f8-bab6-67c933b9b327';
