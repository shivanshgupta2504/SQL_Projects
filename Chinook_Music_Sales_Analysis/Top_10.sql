use chinook;

-- Top 10 Artists
select
    ar.name as artist_name,
    sum(i.total) as total_revenue
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
group by 1
order by 2 desc
limit 10;

-- Top 10 Albums
select
    al.title as album_name,
    sum(i.total) as total_revenue
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
group by 1
order by 2 desc
limit 10;

-- Top 10 Genres
select
    g.name as genre_name,
    sum(i.total) as total_revenue
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
group by 1
order by 2 desc
limit 10;