-- Subjectives
use chinook;

-- 1.	Recommend the three albums from the new record label that should be prioritised 
-- for advertising and promotion in the USA based on genre sales analysis.
-- For every Genre wise top 3 albums in USA
with cte as (
select
	a.title as album_name,
    g.name as genre_name,
    i.total,
    row_number() over(partition by g.name order by i.total desc) as rn
from album_copy a
join track_copy t on a.album_id = t.album_id
join genre_copy g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice_copy i on il.invoice_id = i.invoice_id
where i.billing_country = 'USA'
group by 1,2,3)

select
	album_name,
    genre_name
from cte
where rn <= 3
group by 1,2;



-- 2. Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
-- Top selling genres outside USA
with cte as (
select
    g.name as genre_name,
    i.billing_country as country,
    i.total,
    row_number() over(partition by i.billing_country order by i.total desc, g.name asc) as rn
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
where i.billing_country <> 'USA'
group by 1, 2, 3
)

-- select
-- 	genre_name,
--     country
-- from cte
-- where rn <= 5
-- group by 1,2;

select
	genre_name,
    count(*) as genre_counts
from cte
group by 1
order by 2 desc;

-- In USA Top genres are
select
    g.name as genre_name,
    count(g.name) as genre_counts
from track_copy t
join album_copy al on t.album_id = al.album_id
join artist_copy ar on al.artist_id = ar.artist_id
join genre g on t.genre_id = g.genre_id
join invoice_line_copy il on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
where i.billing_country = 'USA'
group by 1
order by 2 desc;



-- 3.	Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of 
-- long-term customers differ from those of new customers? What insights can these patterns provide about customer loyalty 
-- and retention strategies?
with customer_first_purchase as (
select
	c.customer_id,
    min(i.invoice_date) as first_purchase_date
from customer_copy c
join invoice_copy i on c.customer_id = i.customer_id
group by 1
),
customer_classification as (
select
	c.customer_id,
    case
		-- taking more than 3 years as Old customer
		when datediff((select max(invoice_date) from invoice_copy), cfp.first_purchase_date) > 365*3 then 'Long Term'
        else
			'New'
	end as customer_type
from customer_copy c
join customer_first_purchase cfp on cfp.customer_id = c.customer_id
),
customer_spending as (
select
	i.customer_id,
    count(distinct i.invoice_id) as purchase_frequency,
    avg(il.quantity) as avg_basket_size,
    sum(i.total) as total_spent
from invoice_copy i
join invoice_line_copy il on i.invoice_id = il.invoice_id
group by 1
)

select
    cc.customer_type,
    round(avg(cs.purchase_frequency), 2) as avg_purchase_frequency,
    round(avg(cs.avg_basket_size), 2) as avg_basket_size,
    round(avg(cs.total_spent), 2) as avg_total_spent
from customer_spending cs
join customer_classification cc on cs.customer_id = cc.customer_id
group by cc.customer_type;



-- 4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? 
-- How can this information guide product recommendations and cross-selling initiatives?
-- Genre pairs
with invoice_genre as (
select
	il.invoice_id,
	g.name as genre_name
from invoice_line_copy il
join track_copy t on il.track_id = t.track_id
join genre_copy g on t.genre_id = g.genre_id
)
select
	a.genre_name as genre_1,
    b.genre_name as genre_2,
    count(*) as purchase_count
from invoice_genre a
join invoice_genre b on a.invoice_id = b.invoice_id and a.genre_name < b.genre_name -- Avoid duplicate pairs
group by 1,2
order by 3 desc
limit 10;

-- Album Pairs
with invoice_album as (
select
	il.invoice_id,
	a.album_id
from invoice_line_copy il
join track_copy t on il.track_id = t.track_id
join album_copy a on a.album_id = t.album_id
)
select
	a.album_id as album_1,
    b.album_id as album_2,
    count(*) as purchase_count
from invoice_album a
join invoice_album b on a.invoice_id = b.invoice_id
where a.album_id < b.album_id -- Avoid duplicate pairs
group by 1,2
order by 3 desc
limit 10;



-- 5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or 
-- store locations? How might these correlate with local demographic or economic factors?
with latest_invoice_date as (
    select max(invoice_date) as max_date from invoice_copy
),
churned_customers as (
select 
	c.customer_id, 
    c.country
from customer_copy c
left join invoice_copy i 
on c.customer_id = i.customer_id and i.invoice_date >= date_sub((select max_date from latest_invoice_date), interval 6 month)
where i.customer_id is null
)
select
	c.country, 
	count(distinct c.customer_id) as total_customers,
	count(distinct ch.customer_id) as churned_customers,
	(count(distinct ch.customer_id) / count(distinct c.customer_id)) * 100 as churn_rate,
    case
		when (count(distinct ch.customer_id) / count(distinct c.customer_id)) * 100 > 75 then 'High rate'
        when (count(distinct ch.customer_id) / count(distinct c.customer_id)) * 100 between 25 and 75 then 'Medium rate'
        else
			'Low rate'
	end as churn_classification
from customer_copy c
left join churned_customers ch on c.customer_id = ch.customer_id
group by c.country
order by churn_rate desc;

select
	c.country, 
	count(distinct i.invoice_id) as total_orders,
	sum(i.total) as total_revenue,
	avg(i.total) as avg_order_value,
	count(distinct i.customer_id) as active_customers,
	(sum(i.total) /count(distinct i.customer_id)) as revenue_per_customer
from customer_copy c
join invoice_copy i on c.customer_id = i.customer_id
group by 1
order by total_revenue desc;



-- 6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments 
-- are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?
with customer_spending as (
select 
	i.customer_id, 
    c.country, 
	count(i.invoice_id) as total_orders,
	sum(i.total) as total_spent,
	avg(i.total) as avg_order_value,
	max(i.invoice_date) as last_purchase_date
from customer_copy c
join invoice_copy i on c.customer_id = i.customer_id
group by i.customer_id, c.country
),
recent_spenders as (
    select customer_id from invoice_copy
    where invoice_date >= DATE_SUB((select MAX(invoice_date) from invoice), interval 6 month)
)
select 
	cs.customer_id, 
    cs.country, 
    cs.total_orders, 
	cs.total_spent, cs.avg_order_value,
	case 
		when rs.customer_id is null then 'High Churn Risk'
		when cs.total_orders < 3 then 'Medium Risk'
		else 
			'Low Risk'
	end as risk_category
from customer_spending cs
left join recent_spenders rs on cs.customer_id = rs.customer_id
order by cs.country asc;

with latest_invoice_date as (
    select max(invoice_date) as max_date from invoice_copy
),
churned_customers as (
select 
	c.customer_id, 
    c.country
from customer_copy c
left join invoice_copy i 
on c.customer_id = i.customer_id and i.invoice_date >= date_sub((select max_date from latest_invoice_date), interval 6 month)
where i.customer_id is null
)
select 
	e.employee_id, 
    concat(e.first_name, ' ', e.last_name) as full_name,
	count(distinct c.customer_id) as total_customers,
	count(distinct ch.customer_id) as churned_customers,
	coalesce(round(count(distinct ch.customer_id) / count(distinct c.customer_id) * 100, 2), 0) as churn_rate
from employee_copy e
left join customer_copy c on e.employee_id = c.support_rep_id
left join churned_customers ch on c.customer_id = ch.customer_id
group by e.employee_id, e.first_name, e.last_name
order by churn_rate desc;



-- 7. Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) 
-- to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program 
-- strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
with customer_purchase_data as (
select 
	i.customer_id, 
	min(i.invoice_date) as first_purchase_date,
	max(i.invoice_date) as last_purchase_date,
	count(i.invoice_id) as total_orders,
	sum(i.total) as total_spent,
	round(avg(i.total), 2) as avg_order_value,
	timestampdiff(month, min(i.invoice_date), max(i.invoice_date)) as customer_lifespan
from invoice_copy i
group by i.customer_id
),
customer_frequency as (
select 
	customer_id, 
	round(total_orders / NULLIF(customer_lifespan, 0), 2) as purchase_frequency
from customer_purchase_data
),
customer_clv as (
select 
	cpd.customer_id, 
    cpd.total_spent, 
    cpd.avg_order_value, 
	cf.purchase_frequency, 
    cpd.customer_lifespan,
	round(cpd.avg_order_value * cf.purchase_frequency * cpd.customer_lifespan, 2) as predicted_clv
from customer_purchase_data cpd
join customer_frequency cf on cpd.customer_id = cf.customer_id
)
select * from customer_clv
order by predicted_clv desc;



-- 10. How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year
--  of each album?
-- Assuming release year of each album as the year in which each album id bought earliest, just to put some value in that column
create table album_copy_1 as
select * from album_copy;

alter table album_copy_1
add column release_year int;

set SQL_SAFE_UPDATES = 0;
update album_copy_1 a
set release_year = (
	select min(year(i.invoice_date))
    from invoice_copy i
    join invoice_line_copy il on i.invoice_id = il.invoice_id
    join track_copy t on il.track_id = t.track_id
    where t.album_id = a.album_id
);
set SQL_SAFE_UPDATES = 1;
select * from album_copy_1;



-- 11. Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. 
-- They want to know the average total amount spent by customers from each country, along with the number of customers 
-- and the average number of tracks purchased per customer. Write an SQL query to provide this information.
select 
	c.country,
	count(distinct c.customer_id) as num_customers,
	round(avg(i.total), 2) as avg_spent_per_customer,
	round(avg(track_count.tracks_per_customer), 2) as avg_tracks_per_customer
from customer_copy c
left join invoice_copy i on c.customer_id = i.customer_id
left join (
    select i.customer_id, COUNT(il.track_id) as tracks_per_customer
    from invoice_copy i
    join invoice_line_copy il on i.invoice_id = il.invoice_id
    group by i.customer_id
) as track_count on c.customer_id = track_count.customer_id
group by c.country
order by 2 desc, 3 desc, 4 desc;
















