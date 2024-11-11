
-- Create needed tables in l2 for normalization
create table l2.flight_scheduled_dates (
	date_idx varchar(50) not null unique,
	scheduled_time timestamptz not null,
	constraint flight_scheduled_dates_pkey primary key (date_idx)
);

create  table l2.flight_schedules (
	departure_date_idx varchar(50) not null,
	departure_airport_code varchar(10) not null,
	arrival_date_idx varchar(50) not null,
	arrival_airport_code varchar(10) not null,
	airline_code varchar(50) not null,
	fligh_duration_hours decimal,
	monday bool,
	tuesday bool,
	wednesday bool,
	thursday bool,
	friday bool,
	saturday bool,
	sunday bool,
	constraint flight_schedules_pkey primary key (departure_date_idx, departure_airport_code, arrival_date_idx, arrival_airport_code, airline_code),
	constraint flight_schedules_departure_date_idx_fkey foreign key (departure_date_idx) references l2.flight_scheduled_dates(date_idx),
	constraint flight_schedules_arrival_date_idx_fkey foreign key (arrival_date_idx) references l2.flight_scheduled_dates(date_idx),
	constraint flight_schedules_departure_airport_code_fkey foreign key (departure_airport_code) references l2.refdata_airports(airport),
	constraint flight_schedules_arrival_airport_code_fkey foreign key (arrival_airport_code) references l2.refdata_airports(airport),
	constraint flight_schedules_airline_code_fkey foreign key (airline_code) references l2.refdata_airlines(airlineid)
);
