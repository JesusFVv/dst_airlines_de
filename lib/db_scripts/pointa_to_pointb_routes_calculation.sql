-- Create a table for the available routes (scheduled)
create table l3.scheduled_routes (
	departure_airport_code varchar(50),
	arrival_airport_code varchar(50),
	constraint scheduled_routes_pkey primary key (departure_airport_code, arrival_airport_code),
	constraint scheduled_routes_dep_code_fkey foreign key (departure_airport_code) references l2.refdata_airports(airport),
	constraint scheduled_routes_arr_code_fkey foreign key (arrival_airport_code) references l2.refdata_airports(airport)
)

insert into l3.scheduled_routes select distinct departure_airport_code, arrival_airport_code from l2.flight_schedules;

-- 
with recursive routes_cte as (
    select departure_airport_code || '->' || arrival_airport_code as route
          ,0 as transfers_count
          ,departure_airport_code
          ,arrival_airport_code
    from l3.scheduled_routes
    union all
    select r.route || '->' || r1.arrival_airport_code as route
          ,transfers_count + 1
          ,r.departure_airport_code
          ,r1.arrival_airport_code
    from routes_cte r
    inner join l3.scheduled_routes r1
        on r.arrival_airport_code = r1.departure_airport_code
            and r1.arrival_airport_code <> r.departure_airport_code)
select route
from routes_cte 
where departure_airport_code = 'LAX'
    and arrival_airport_code = 'LOZ'
    and transfers_count <= 2;
    
   
select 'q' || '->' || 'c' as route
;


CREATE TABLE l3.scheduled_routes_tmp (
	departure_airport_code varchar(50) NOT NULL,
	arrival_airport_code varchar(50) NOT NULL
);
delete from l3.scheduled_routes_tmp;
insert into l3.scheduled_routes_tmp values ('LAX', 'CDG'), ('LAX', 'MAD'), ('CDG', 'MAD'), ('MAD', 'LOZ'), ('MAD', 'ORY'), ('ORY', 'LOZ'), ('LAX', 'LOZ');
-- 
with recursive routes_cte as (
    select departure_airport_code || '->' || arrival_airport_code as route
          ,0 as transfers_count
          ,departure_airport_code
          ,arrival_airport_code
    from l3.scheduled_routes_tmp
    union all
    select r.route || '->' || r1.arrival_airport_code as route
          ,transfers_count + 1
          ,r.departure_airport_code
          ,r1.arrival_airport_code
    from routes_cte r
    inner join l3.scheduled_routes_tmp r1
        on r.arrival_airport_code = r1.departure_airport_code
            and r1.arrival_airport_code <> r.departure_airport_code)
select route
from routes_cte 
where departure_airport_code = 'LAX'
    and arrival_airport_code = 'LOZ'
    and transfers_count <= 2;
    
   
select 'q' || '->' || 'c' as route
;
