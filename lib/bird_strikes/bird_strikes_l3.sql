-- Normalize the table bird strikes
-- insert into l3.bird_strikes as
create table l3.bird_strikes as
	with bird_strikes_selected as (
		select 
			cast(event_date as date) as event_day,
			aircraft_model,
			event_tag,
			airline,
			event_location,
			event_description,
			ac_model_extracted
			from l1.avherald_only_bird_strikes
	),
	bird_strikes_and_airport as (
		select a.*, b.city as city_code, c.airport as airport_code
			from bird_strikes_selected as a
			left outer join (select city, name from l2.refdata_city_names where lang = 'EN') as b
				on a.event_location = b.name
			left outer join (select city, airport from l2.refdata_airports where locationtype = 'Airport') as c
				on b.city = c.city
	),
	bird_strikes_airport_and_airline as (
		select a.*, b.airline as airline_code
			from bird_strikes_and_airport as a
			left outer join (select name, airline from l2.refdata_airline_names where lang = 'EN') as b
				on a.airline = b.name
	),
	duplicates_are_tagged as (
		select *,
			row_number() over(partition by event_day, aircraft_model, event_tag, airline, event_location, event_description, ac_model_extracted order by city_code asc, airport_code asc, airline_code asc) as tag
			from bird_strikes_airport_and_airline
	)
	select
		event_day,
		aircraft_model,
		event_tag,
		airline,
		airline_code,
		event_location as city,
		city_code,
		airport_code,
		event_description,
		ac_model_extracted
		from duplicates_are_tagged
		where tag = 1;
