create database dominose;

use dominose;

CREATE TABLE customers (
    custid INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20)
);

CREATE TABLE order_details (
    order_details_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    custid INT NOT NULL,
    status VARCHAR(20),

    FOREIGN KEY (custid) REFERENCES customers(custid)
);


CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients TEXT
);

CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50) NOT NULL,
    size VARCHAR(5) NOT NULL,
    price DECIMAL(5,2) NOT NULL,

    FOREIGN KEY (pizza_type_id)
    REFERENCES pizza_types(pizza_type_id)
);

SELECT * FROM customers;
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;

-- Data_cleaning_
-- 1.duplicates
-- 2.null values
-- 3.check data_types

select email,count(*)
from customers
group by email
having count(*) > 1;

select coalesce(email,'unkown')
from customers;

describe pizza_types;

### 1. Orders Volume Analysis
-- - Total unique orders, orders by month, day-of-week analysis, repeat customers, average orders per customer, cumulative order trend.

-- 1.Total unique orders

select distinct count(order_id) from orders;

-- 2.orders by month

select year(order_date),
       monthname(order_date),
count(order_id) as count_order
from orders
group by year(order_date),
       monthname(order_date);

-- 3.day-of-week analysis

select dayname(order_date),
count(order_id) as count_of_order
from orders
group by dayname(order_date);

-- 4.repeat customers

select custid,count(*) as count_of_customers
from customers
group by custid
having count(*) > 1;

-- 5.average orders per customer

select avg(total_orders) as avg_order_by_customers
from
(select custid,count(order_id) as total_orders
from orders
group by custid) t;

-- 6.cumulative order trend

WITH monthly AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(order_id) AS monthly_orders
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT 
    month,
    monthly_orders,
    SUM(monthly_orders) OVER (ORDER BY month) AS cumulative_orders
FROM monthly;

-- ### 2. Total Revenue from Pizza Sales
-- - Calculate total revenue from all pizza sales.

select sum(order_details.quantity * pizzas.price) as total_revenue
from order_details join pizzas
using(pizza_id);

-- ### 3. Highest-Priced Pizza
-- - Identify the most expensive pizza on the menu.

select pizza_types.name,pizzas.price
from pizza_types join pizzas
using(pizza_type_id)
order by pizzas.price desc
limit 1;

-- ### 5. Top 5 Most Ordered Pizza Types
-- - Find the top 5 pizza types based on quantity sold

select pizza_types.name,sum(order_details.quantity * pizzas.price) as total_orders
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by pizza_types.name
limit 5;

-- 6.### 6. Total Quantity by Pizza Category
-- - Calculate total pizzas sold in each category.

select pizza_types.category,sum(order_details.quantity) as total_pizzas
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by  pizza_types.category;


-- ### 7. Orders by Hour of the Day
-- - Understand peak ordering hours to optimize staffing.

select hour(order_time) as order_hour,
count(order_id) as total_orders
from orders
group by hour(order_time)
order by total_orders desc;

-- ### 8. Category-Wise Pizza Distribution
-- - Analyze category-wise sales and percentage share.

select pizza_types.category,
sum(order_details.quantity) as total_sales,
round(sum(order_details.quantity) * 100.0/ (select sum(quantity) from order_details),2) as percentage
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by pizza_types.category 
order by total_sales desc ;

-- ### 9. Average Pizzas Ordered per Day
-- - Measure daily pizza demand consistency.

select avg(sales) as avg_daily_pizzas
from
(select orders.order_date,sum(order_details.quantity) as sales
from orders join order_details
using(order_id) 
group by orders.order_date) t;

-- ### 10. Top 3 Pizzas by Revenue
-- - Identify pizzas generating the highest revenue.

with a as(select pizza_types.name,sum(order_details.quantity * pizzas.price) as total_revenue,
dense_rank() over( order by  sum(order_details.quantity * pizzas.price) desc) as rnk
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by pizza_types.name) 
select * 
from a
where rnk <=3;

-- ### 11. Revenue Contribution per Pizza
-- - Percentage contribution of each pizza to total revenue.

select pizza_types.name,
sum(order_details.quantity) as total_sales,
round(sum(order_details.quantity) * 100.0/ (select sum(quantity) from order_details),2) as percentage
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by pizza_types.name
order by total_sales desc ;

-- ### 12. Cumulative Revenue Over Time
-- - Monthly cumulative revenue trend since launch.

select orders.order_date,sum(order_details.quantity * pizzas.price) as total_revenue,
sum(sum(order_details.quantity * pizzas.price)) over(order by orders.order_date) as running_total
from orders join order_details
using(order_id)
join pizzas
using(pizza_id) 
group by orders.order_date;

-- ### 13. Top 3 Pizzas by Category (Revenue-Based)
-- - Top 3 pizzas by revenue in each category.

select pizza_types.category,sum(order_details.quantity * pizzas.price) as total_revenue
from pizza_types join pizzas
using(pizza_type_id)
join order_details
using(pizza_id)
group by pizza_types.category
limit 3;

-- ### 14. Top 10 Customers by Spending
-- - Identify the highest-spending customers.

select orders.custid,sum(order_details.quantity * pizzas.price) as totaL_spend,
dense_rank() over(order by sum(order_details.quantity * pizzas.price)  desc) as rnk
from orders join order_details
using(order_id)
join pizzas
using(pizza_id)
group by orders.custid;

-- ### 15. Orders by Weekday
-- - Determine busiest days of the week for orders.

select weekday(order_date) as weekday,count(order_id) as count_of_order
from orders
group by weekday(order_date);

-- --##16.Revenue by Pizza Size
-- - Revenue contribution of each pizza size (S, M, L, XL, XXL).

select pizzas.size,sum(order_details.quantity * pizzas.price) as total_revenue
from pizzas join order_details
using(pizza_id)
group by pizzas.size
order by total_revenue desc;

--##17.Customer Segmentation
-- - Classify customers as High Value or Regular based on spend.

select orders.custid,sum(order_details.quantity * pizzas.price) as Total_spend,
case 
when sum(order_details.quantity * pizzas.price) > 80000 then 'high value customer'
else 'reguler customer'
end as customer_segmentation
from orders join order_details
using(order_id) 
join pizzas
using(pizza_id)
group by orders.custid
order by Total_spend ;

-- --##18.Seasonal Trends
-- - Analyze sales patterns by month and holidays.

select month(orders.order_date) as months,sum(order_details.quantity * pizzas.price) as total_revenue
from orders join order_details
using(order_id)
join pizzas
using(pizza_id)
group by month(orders.order_date);

select monthname(orders.order_date) as months,sum(order_details.quantity * pizzas.price) as total_revenue
from orders join order_details
using(order_id)
join pizzas
using(pizza_id)
group by monthname(orders.order_date);

-- --##19.Average Order Size
-- - Calculate average number of pizzas per order.

select pizzas.size,avg(order_details.quantity) as avg_order_size
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size
order by avg_order_size desc;


-- ### 20. Repeat Customer Rate
-- - Percentage of repeat customers versus one-time buyers.

WITH customer_orders AS (
    SELECT
        custid,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY custid
)

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM customer_orders;


-- ## Key Findings

-- - **Customer Behavior**: High-value and repeat customers identified.  
-- - **Order Trends**: Peak hours, weekends, and seasonal patterns discovered.  
-- - **Menu Insights**: Top-selling pizzas, revenue contributors, and popular sizes identified.  
-- - **Revenue Analysis**: Monthly revenue, cumulative trends, and category-wise contributions analyzed.  
-- - **Operational Insights**: Average order size, daily pizzas, and staffing optimization recommendations provided.


