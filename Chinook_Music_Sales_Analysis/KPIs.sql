use chinook;

-- Total Customers
select count(customer_id) as total_customers from customer_copy;

-- Churn rate
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
select round(avg(churn_rate), 2) as churn_rate from YearlyChurn where prev_year_customers is not null;

-- Total Revenue
select sum(total) as total_revenue from invoice_copy;




