-- Objectives
use chinook;
-- 2.	Find the top-selling tracks and top artist in the USA and identify their most famous genres.
create view track_artist_genre_view as
select
	t.name as track_name,
    ar.name as artist_name,
    g.name as genre_name,
    i.total,
    il.unit_price,
    il.quantity
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
where i.billing_country = 'USA';


select 
	track_name,
    genre_name,
    artist_name,
    sum(unit_price*quantity) as total_price
from track_artist_genre_view
group by 1,2,3
order by 4 desc
limit 10;

select 
    artist_name,
    sum(unit_price*quantity) as total_price
from track_artist_genre_view
group by 1
order by 2 desc
limit 10;

select 
    genre_name,
    sum(unit_price*quantity) as total_price
from track_artist_genre_view
group by 1
order by 2 desc
limit 10;



-- 3.	What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
select 
    country,
    count(customer_id) as total_customers
from customer_copy
group by 1;



-- 4.	Calculate the total revenue and number of invoices for each country, state, and city?
select
	billing_city as city,
    billing_country as country,
    sum(total) as revenue,
    count(invoice_id) as total_invoices
from invoice_copy
group by 1,2;



-- 5.	Find the top 5 customers by total revenue in each country
select
	concat(c.first_name, ' ', c.last_name) as full_name,
    i.billing_country as country,
    sum(i.total) as total_revenue
from customer_copy c
left join invoice_copy i on c.customer_id = i.customer_id
group by 1,2
order by 3 desc
limit 5;



-- 6.	Identify the top-selling track for each customer
with cte as (
select
    concat(c.first_name, ' ',c.last_name) as full_name,
    i.total,
    t.name as track_name,
    dense_rank() over(partition by concat(c.first_name, ' ',c.last_name) order by i.total desc, t.name asc) as rn
from customer_copy c
left join invoice i on c.customer_id = i.customer_id
left join invoice_line_copy il on i.invoice_id = il.invoice_id
left join track_copy t on il.track_id = t.track_id
)

select
	full_name,
    track_name
from cte
where rn = 1;



-- 7.	Are there any patterns or trends in customer purchasing behavior 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?
-- Frequency of purchases per customer and Average Order Value (AOV) per customer
select 
	concat(c.first_name, ' ', c.last_name) as full_name,
	count(i.invoice_id) AS purchase_count,
    round(avg(i.total), 2) as avg_order_value
from customer_copy c
left join invoice i on c.customer_id = i.customer_id
group by 1
order by 2 desc, 3 desc;



-- 8.	What is the customer churn rate?
with LatestInvoiceDate as (
select max(invoice_date) AS latest_invoice_date FROM invoice_copy
),
YearlyCustomerPurchases as (
select
	year(i.invoice_date) as purchase_year,
	count(distinct i.customer_id) as active_customers
from invoice_copy i
group by year(i.invoice_date)
),
YearlyChurn as (
select
	ycp.purchase_year,
	ycp.active_customers,
	lag(ycp.active_customers) over (order by ycp.purchase_year) as prev_year_customers,
	(lag(ycp.active_customers) over (order by ycp.purchase_year) - ycp.active_customers) as churned_customers,
	round(100 * ((lag(ycp.active_customers) over 
    (order by ycp.purchase_year) - ycp.active_customers) / nullif(lag(ycp.active_customers) over (order by ycp.purchase_year), 0)), 2) 
    as churn_rate
from YearlyCustomerPurchases ycp
)
select purchase_year, churned_customers, churn_rate from YearlyChurn where prev_year_customers is not null;




-- 9.	Calculate the percentage of total sales contributed by each genre in the USA and 
-- identify the best-selling genres and artists.
with cte1 as (
select
	genre_name,
    total
from track_artist_genre_view
group by 1,2
),
cte2 as (
select 
	genre_name,
    sum(total) as total_revenue_per_genre,
    a.total_revenue,
    round(sum(total) / a.total_revenue * 100, 2) as percentage
from cte1 cross join (select sum(total) as total_revenue from cte1) a
group by 1,3
order by 4 desc
)

select genre_name, percentage from cte2;



-- 10.	Find customers who have purchased tracks from at least 3 different genres
select
    concat(c.first_name, ' ',c.last_name) as full_name,
    count(distinct t.genre_id) as total_different_genres_purchased
from customer_copy c
left join invoice i on c.customer_id = i.customer_id
left join invoice_line_copy il on i.invoice_id = il.invoice_id
left join track_copy t on il.track_id = t.track_id
group by 1
having count(distinct t.genre_id) >= 3
order by 2 desc, 1 asc;



-- 11.	Rank genres based on their sales performance in the USA
with cte1 as (
select
	genre_name,
    total
from track_artist_genre_view
group by 1,2
),
cte2 as (
select
	genre_name,
    sum(total) as total_revenue
from cte1
group by 1
)
select
	*,
    dense_rank() over(order by total_revenue desc) as `rank`
from cte2;



-- 12.	Identify customers who have not made a purchase in the last 3 months
with latest_invoice_date as (
    select max(invoice_date) as max_date from invoice_copy
)
select concat(c.first_name, ' ',c.last_name) as full_name
from customer_copy c
left join invoice i 
    on c.customer_id = i.customer_id
    and i.invoice_date >= date_sub((select max_date from latest_invoice_date), interval 3 month)
where i.customer_id is null;




























