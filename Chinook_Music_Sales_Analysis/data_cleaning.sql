-- customer table cleaning
-- Dropping columns
create table customer_copy as
select customer_id, first_name, last_name, city, country, support_rep_id from customer;
select * from customer_copy;

-- check for dupes and remove them - no duplicates
select
	*,
    row_number() over(partition by customer_id, first_name, last_name, city, country, support_rep_id) as rn
from customer_copy;

-- data standardization
SET SQL_SAFE_UPDATES = 0;
update customer_copy
set first_name = trim(first_name),
last_name = trim(last_name),
city = trim(city),
country = trim(country);
SET SQL_SAFE_UPDATES = 1;



-- employee table cleaning
-- dropping columns
select * from employee;
create table employee_copy as
select employee_id, first_name, last_name, title, reports_to, city, state, country from employee;

-- checking dupes - no
select 
	*,
	row_number() over(partition by employee_id, first_name, last_name, title, reports_to, city, state, country) as rn
from employee_copy;

-- data standardization
SET SQL_SAFE_UPDATES = 0;
update employee_copy
set first_name = trim(first_name),
last_name = trim(last_name),
title = trim(title),
city = trim(city), 
state = trim(state), 
country = trim(country);
SET SQL_SAFE_UPDATES = 1;



-- playlist table cleaning
select * from playlist;
-- no dropping columns
create table playlist_copy as
select *, row_number() over(partition by `name`) as rn from playlist order by playlist_id;
-- checking dupes and removing them
set SQL_SAFE_UPDATES = 0;
delete
from playlist_copy
where rn > 1;
set SQL_SAFE_UPDATES = 1;

set SQL_SAFE_UPDATES = 0;
alter table playlist_copy
drop column rn;
set SQL_SAFE_UPDATES = 1;



-- playlist_track table cleaning
select * from playlist_track;
-- no dropping columns
create table playlist_track_copy as
select *, row_number() over(partition by playlist_id, track_id) as rn from playlist_track;
-- no dupes
select * from playlist_track_copy
where rn > 1;

-- deleting rows having playlist_id = 8 and 10
set SQL_SAFE_UPDATES = 0;
delete
from playlist_track_copy
where playlist_id in (8, 10);
set SQL_SAFE_UPDATES = 1;

set SQL_SAFE_UPDATES = 0;
alter table playlist_track_copy
drop column rn;
set SQL_SAFE_UPDATES = 1;



-- artist table cleaning
select * from artist;
-- no dropping and no null values
-- no dupes
create table artist_copy as
select * from artist;



-- album table cleaning
-- no null values, no dropping columns and no dupes
create table album_copy as
select * from album;



-- media_type table cleaning
-- no cleaning needed
create table media_type_copy as
select * from media_type;



-- genre table cleaning
-- no cleaning needed
create table genre_copy as
select * from genre;



-- invoice table cleaning
-- no nulls
-- dropping columns address, state, postal_code
create table invoice_c as
select * from invoice;

alter table invoice_c
drop column billing_address, 
drop column billing_state,
drop column billing_postal_code;

-- no dupes found
select 
	*,
    row_number() over(partition by invoice_id, customer_id, invoice_date, billing_city, billing_country, total) as rn
from invoice_c;

create table invoice_copy as
select * from invoice_c;

drop table if exists invoice_c;



-- invoice_line table cleaning
-- no nulls
-- no dupes
create table invoice_line_copy as
select * from invoice_line;



-- track table cleaning
-- null values in composer column drop it
create table track_c as
select track_id, `name`, album_id, media_type_id, genre_id, milliseconds, bytes, unit_price from track;
-- no dupes
select
	*,
    row_number() over(partition by track_id, `name`, album_id, media_type_id, genre_id, milliseconds, bytes, unit_price) as rn
from track_c;

create table track_copy as
select * from track_c;

drop table track_c;

