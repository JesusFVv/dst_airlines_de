create table flight_schedules (
	flight_number varchar(10),
	airplane varchar(10),
	duration decimal
);

insert into flight_schedules values ('1', 'a320',  1.5), ('2', 'b737',  2.1);
insert into flight_schedules values ('1', 'b320',  3.5);
insert into flight_schedules values ('1', 'a320',  5.5);

create table _flight_schedules_stagging (
	flight_number varchar(10),
	airplane varchar(10),
	duration decimal
);

create table airplanes (
	airplane varchar(10) not null,
	constraint airplanes_pkey primary key (airplane)
);
insert into airplanes values ('a320'), ('b737'), ('a380');

create table flight_schedules_normalized (
	flight_number int,
	airplane varchar(10),
	duration int,
	constraint flight_schedules_pkey primary key (flight_number, airplane),
	constraint flight_schedules_normalized_fkey foreign key (airplane) references airplanes(airplane)
);
insert into flight_schedules_normalized values (1, 'a320',  1), (2, 'b737',  2);
insert into flight_schedules_normalized values (1, 'b320',  1);

CREATE FUNCTION autoload_flight_schedules() RETURNS trigger AS 
$$
BEGIN
    insert into flight_schedules_normalized
		with row_values as (
			select new.*
		),
		normalized_flight_schedules as(
			select
				cast(flight_number as int) as flight_number,
				airplane,
				round(duration, 0) as duration
				from row_values
		)
		select * from normalized_flight_schedules
		on conflict on constraint flight_schedules_pkey do nothing;
	RETURN NULL;
EXCEPTION WHEN foreign_key_violation or invalid_foreign_key THEN
	insert into _flight_schedules_stagging select new.*;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

create trigger trigger_autoload_l1_stagging_flight_schedules after
insert
    on
    flight_schedules for each row execute function autoload_flight_schedules()
