-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020, unique_products_2021, percentage_chg*/
with CTE as (
select
     count(distinct case when fiscal_year = 2020 then product_code end) as unique_product_2020,
	 count(distinct case when fiscal_year = 2021 then product_code end) as unique_product_2021
from fact_sales_monthly
where fiscal_year in (2020, 2021))
select unique_product_2020, unique_product_2021,
     (unique_product_2021  / unique_product_2020 -1 )*100 as percenatge_chg
from cte;
     

/* 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields,
segment, product_count*/
select segment, count(distinct product_code) as unique_product_count
from dim_product
group by segment
order by unique_product_count desc;

/* 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment, product_count_2020, product_count_2021, difference*/
with CTE as (
select segment,
     count(distinct case when fiscal_year = 2020 then p.product_code end) as product_count_2020,
	 count(distinct case when fiscal_year = 2021 then p.product_code end) as product_count_2021
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code
where fiscal_year in (2020, 2021)
group by segment)
select segment, product_count_2020, product_count_2021,
     (product_count_2021 - product_count_2020) as difference
from cte;

/* 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code, product, manufacturing_cost*/
(select m.product_code, p.product, max(manufacturing_cost) as manufacturing_cost
from fact_manufacturing_cost m
join dim_product p on m.product_code = p.product_code
group by m.product_code, p.product
order by manufacturing_cost desc
limit 1)
union 
(select m.product_code, p.product, min(manufacturing_cost) as manufacturing_cost
from fact_manufacturing_cost m
join dim_product p on m.product_code = p.product_code
group by m.product_code, p.product
order by manufacturing_cost asc
limit 1);

/* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
for the fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code, customer, average_discount_percentage*/
select p.customer_code, customer, 
avg(pre_invoice_discount_pct) as average_discount_per
from fact_pre_invoice_deductions p
join dim_customer c
on p.customer_code = c.customer_code
where fiscal_year = 2021 and market = 'India'
group by p.customer_code, customer
order by average_discount_per desc
limit 5;

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns:
Month, Year, Gross sales Amount*/
select concat(monthname(s.date), ' (', year(s.date), ')') as month, s.fiscal_year,
sum(g.gross_price * s.sold_quantity) as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g on s.product_code = g.product_code
join dim_customer c on s.customer_code = c.customer_code
where c.customer = 'Atliq Exclusive'
group by month, s.fiscal_year
order by s.fiscal_year;

/* 8. In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity,
Quarter, total_sold_quantity*/
SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 'Q1'
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 'Q2'
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 'Q3'
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 'Q4'
    END AS Quarters,
    round((SUM(sold_quantity)/1000000),2) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
order by round((SUM(sold_quantity)/1000000),2) desc;

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields,
channel, gross_sales_mln, percentage*/
with CTE as (
select c.channel, sum(g.gross_price * s.sold_quantity) as total_sales
from fact_sales_monthly s
join fact_gross_price g on s.product_code = g.product_code
join dim_customer c on s.customer_code = c.customer_code
where s.fiscal_year = 2021
group by c.channel)
select channel, round(total_sales / 1000000, 2) as gross_sales_mln,
round(total_sales / sum(total_sales) over()*100, 2) as percentage
from cte;

/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields 
division, product_code*/
with CTE as (
select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.division, p.product_code, p.product)
,CTE1 as (
select division, product_code, product, total_sold_quantity,
rank() over(partition by division order by total_sold_quantity desc) as rnk
from CTE)
select c.division, c.product_code, c.product, c.total_sold_quantity, c1.rnk
from CTE c
join CTE1 c1 on c.product_code = c1.product_code
where rnk in (1,2,3);

