-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select
    distinct market
from
    dim_customer
where
    customer = 'Atliq Exclusive' and region = 'APAC';
    
-- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020, unique_products_2021, percentage_chg

with info as (
select
    count(distinct case when fiscal_year = 2020 then product_code end) as unique_products_2020,
    count(distinct case when fiscal_year = 2021 then product_code end) as unique_products_2021
from
    fact_sales_monthly )
    
select
    unique_products_2020,
    unique_products_2021,
    (unique_products_2021 - unique_products_2020) / (unique_products_2021 + unique_products_2020) * 100 as percentage_change
from
    info;
    
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields; segment, product_count

select
    segment,
    count(product_code) as unique_product_counts
from
    dim_product
group by
    segment
order by
    unique_product_counts desc;
    
-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
-- segment, product_count_2020, product_count_2021, difference

with info_ as (
select
    segment,
    count(distinct case when fiscal_year = 2020 then fact_sales_monthly.product_code end) as product_count_2020,
    count(distinct case when fiscal_year = 2021 then fact_sales_monthly.product_code end) as product_count_2021
from 
    fact_sales_monthly inner join dim_product
    on (fact_sales_monthly.product_code = dim_product.product_code)
group by
    segment )
    
select
    segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 as difference
from
    info_;
    
-- Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code
-- product, manufacturing_cost

 select
    fact_manufacturing_cost.product_code,
    product,
    manufacturing_cost
from
    fact_manufacturing_cost left join dim_product
    on (fact_manufacturing_cost.product_code = dim_product.product_code)
order by
    manufacturing_cost desc;
    
-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 
-- and in the Indian market. The final output contains these fields, customer_code, customer, average_discount_percentage

select
    dim_customer.customer_code,
    customer,
    avg(pre_invoice_discount_pct) as average_discount_percentage
from
    dim_customer right join fact_pre_invoice_deductions
    on (dim_customer.customer_code = fact_pre_invoice_deductions.customer_code)
where
    fiscal_year = 2021 and market = 'India'
group by
    customer_code,
    customer
order by
    average_discount_percentage desc
limit 5;

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month, Year, Gross sales Amount

select
    month(date) as month_,
    fact_sales_monthly.fiscal_year,
    concat(round(sum(gross_price * sold_quantity) / 1000000, 2), ' M') as gross_sales_amount
from
    fact_sales_monthly  
    left join fact_gross_price on (fact_sales_monthly.product_code = fact_gross_price.product_code)
    left join dim_customer on (fact_sales_monthly.customer_code = dim_customer.customer_code)
where
    customer = 'Atliq Exclusive'
group by
	month(date),
    fact_sales_monthly.fiscal_year
order by
    month(date) desc;
    
-- In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by 
-- the total_sold_quantity, Quarter, total_sold_quantity

select
    format(sum(sold_quantity), 0) as total_sold_quantity,
    case when month(date) in (1,2,3) then 'Q1'
    when month(date) in (4,5,6) then 'Q2'
    when month(date) in (7,8,9) then 'Q3'
    else 'Q4' 
    end as Quarters
from
    fact_sales_monthly
group by
    Quarters
order by
    total_sold_quantity desc;
    
-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, channel, gross_sales_mln, percentage

select
    channel,
    concat(round(sum(sold_quantity * gross_price) / 1000000, 2), 'M') as gross_sales_mln
from
    fact_sales_monthly
    join fact_gross_price on (fact_sales_monthly.product_code = fact_gross_price.product_code)
    join dim_customer on (fact_sales_monthly.customer_code = dim_customer.customer_code)
where
    fact_sales_monthly.fiscal_year = 2021
group by
    channel;
    
    
-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order

select
    division,
    dim_product.product_code,
    product,
    sum(sold_quantity) as total_sold_quantity,
    dense_rank() over(order by sum(sold_quantity) asc) as rnk
from
    dim_product join fact_sales_monthly
    on (dim_product.product_code = fact_sales_monthly.product_code)
where
    fiscal_year = 2021
group by
    division,
    product_code,
    product
order by
    total_sold_quantity
limit 3;
