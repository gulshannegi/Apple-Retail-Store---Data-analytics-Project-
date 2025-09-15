# Apple-Retail-Store---Data-analytics-Project-
This project highlights the application of SQL for real-world analytics beyond simple querying. It demonstrates the ability to work with complex datasets, use advanced SQL functions, and deliver insights that matter to business strategy.

-- 10. For each store, identify the best-selling day based on highest quantity sold.
select store_id , day_name ,totalquant from
( select  store_id ,to_char(sale_date,'Day') as day_name,
  sum(quantity)as totalquant ,
  rank() over (partition by store_id order by sum(quantity) desc) as rank
  from sales
  group by sale_date,store_id) as tbl1
where rank = 1 
order by totalquant desc;

--- Medium Difficulty Questions 

-- 1. Identify the least selling product in each country for each year based on total units sold.
with product_rank as
(select st.country,
extract(year from sl.sale_date) as sale_year,
p.product_name, 
sum(sl.quantity) as total_units,
rank() over (partition by st.country, extract(year from sl.sale_date)          
order by sum(sl.quantity) asc) as ranking
from stores st
join sales sl on sl.store_id = st.store_id
join products p on p.product_id = sl.product_id
group by st.country, extract(year from sl.sale_date), p.product_name)
select *
from product_rank
where ranking = 1;

-- 2. Calculate how many warranty claims were filed within 180 days of a product sale.

select count(*)
from warranty w
left join sales s on w.sale_id = s.sale_id 
where w.claim_date <= sale_date + interval '180 days'  ;

-- 3. Determine how many warranty claims were filed for products launched in the last two years.
select p.product_name, 
count(w.claim_id)
from warranty w 
join sales s on w.sale_id = s.sale_id
join products p on s.product_id = p.product_id 
where p.launch_date >= current_date - interval '2 years' 
group by 1;

-- 4. List the months in the last three years where sales exceeded 5,000 units in the USA.

select to_char(sale_date, 'MM-YYYY'), 
sum(quantity) as total_sales 
from  sales join stores 
on stores.store_id = sales.store_id 
where country = 'United States' 
and sale_date >= (select max(sale_date) - interval '3 years' from sales)
group by 1
having sum(quantity) > 20000
order by 1;

-- 5. Identify the product category with the most warranty claims filed in the last two years.

select category_name, count(claim_id) from warranty w
join sales s on s.sale_id = w.sale_id
join products p on p.product_id = s.product_id
join category c on c.category_id =  p.category_id 
where claim_date >= (select max(claim_date) - interval '2 years' from warranty)
group by category_name
order by 2 desc;

-- ADVANCE COMPLEXITY QUESTIONS 

-- Determine the percentage chance of receiving warranty claims after each purchase for each country.

select country, units_sold, 
total_claims , 
round(COALESCE(total_claims :: numeric /units_sold :: numeric * 100, 0 ),2)
from(
select st.country, sum(sl.quantity) as units_sold, count(w.claim_id) as total_claims
from sales sl  
join stores st on st.store_id = sl.store_id
left join warranty w on sl.sale_id = w.sale_id
group by st.country) as tb1 ;

-- Analyze the year-by-year growth ratio for each store.
with yearly_sales as 
(
	select sl.store_id, st.store_name,
	extract(year from sale_date) as year,
	sum(sl.quantity * p.price) as total_sales
	from sales sl 
	join products p on p.product_id = sl.product_id  
	join stores st on st.store_id = sl.store_id 
	group by 1,2,3
	order by 2,3 asc) ,
growth_ratio as (
	SELECT store_name , year, total_sales as current_year_sales, 
	lag(total_sales,1) over (partition by store_name order by year) as lastyear_sales
	from yearly_sales)
SELECT store_name,lastyear_sales, current_year_sales,
round((current_year_sales - lastyear_sales)::numeric/lastyear_sales::numeric * 100 ,2)
From growth_ratio	
where lastyear_sales is not null
;	

**-- Calculate the correlation between product price and warranty claims for products sold, segmented by price range.
**
select  case when price < 1000 then 'Lower Range' 
		when price between 1000 and 1800 then 'Mid Range' 
		else 'High Range' end as price_range, 
		count(w.claim_id) 
from warranty w 
join sales s on s.sale_id = w.sale_id 
join products p on p.product_id = s.product_id 
group by price_range;

**-- Identify the store with the highest percentage of "Rejected" claims relative to total claims filed.
**
WITH total_repairs AS (
    SELECT 
        store_id, 
        COUNT(claim_id) AS total_cases
    FROM sales sl
    LEFT JOIN warranty w 
        ON w.sale_id = sl.sale_id 
    GROUP BY 1
    ORDER BY store_id),
rejected_claims AS (
    SELECT 
        store_id, 
        COUNT(claim_id) AS rejected_cases
    FROM sales sl
    LEFT JOIN warranty w 
        ON w.sale_id = sl.sale_id 
    WHERE repair_status = 'Rejected'
    GROUP BY 1
    ORDER BY store_id)
SELECT 
    tr.store_id, 
    store_name, 
    total_cases, 
    rejected_cases,
    ROUND(rejected_cases / total_cases::numeric * 100, 2)::text || '%' AS rejection_rate
FROM total_repairs tr
JOIN rejected_claims rc
    ON tr.store_id = rc.store_id 
JOIN stores 
    ON stores.store_id = tr.store_id;

**--  Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
**
with monthly_sales as (
select 
	s.store_id , store_name,
	extract(year from sale_date) as  year,
	extract(month from sale_date) AS month_num,
	sum(price*quantity) as total_revenue	
from sales s
join products p on s.product_id = p.product_id  
join stores st on st.store_id = s.store_id 
group by 1,2,3,4
order by 1,2,3)
select 
	store_name, year ,
	to_char(to_date(month_num::text,'MM'),'Month'),
	total_revenue,
	sum(total_revenue) over (partition by store_id order by year,month_num) as running_total,
	LAG(total_revenue) OVER (PARTITION BY store_id  ORDER BY year, month_num) AS prev_year_revenue,
	round(
    (total_revenue - lag(total_revenue) over (partition by store_id order by year, month_num))::numeric
    * 100.0 / nullif(lag(total_revenue) over (partition by store_id order by year, month_num), 0)::numeric
, 2) as yoy_growth_percent
From monthly_sales;

**-- Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.**

select * from (
select
	p.product_name,
	case 
		when sale_date between launch_date and launch_date + interval '6 month' then '0-6 month' 
		when sale_date between launch_date + interval '6 month' and launch_date + interval '12 month' then '6-12 month' 
		when sale_date between launch_date + interval '12 month' and launch_date + interval '18 month' then '12-18 month'
		else '18+ months'
	end as plc,
	sum(s.quantity) as total_sales
from sales s join products p 
on p.product_id = s.product_id 
group by 1,2)
order by 1, case 
        when plc = '0-6 month' then 1
        when plc = '6-12 month' then 2
        when plc = '12-18 month' then 3
        else 4
    end;
