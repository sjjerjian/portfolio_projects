CREATE TABLE orders(
	order_id INT UNIQUE NOT NULL PRIMARY KEY,
	order_date DATE,
	order_time TIME
);

CREATE TABLE pizza_types (
	pizza_type_id VARCHAR(20) UNIQUE NOT NULL PRIMARY KEY,
	pizza_name VARCHAR(60),
	category VARCHAR(15),
	ingredients VARCHAR(100)
);

CREATE TABLE pizzas(
	pizza_id VARCHAR(20) UNIQUE NOT NULL PRIMARY KEY,
	pizza_type_id VARCHAR(20) REFERENCES pizza_types(pizza_type_id),
	pizza_size VARCHAR(10),
	price DECIMAL(4,2)
);

CREATE TABLE order_details(
	order_details_id INT UNIQUE NOT NULL PRIMARY KEY,
	order_id INT REFERENCES orders(order_id),
	pizza_id VARCHAR(20) REFERENCES pizzas(pizza_id),
	quantity INT
);



/*
Easy:
*/

-- 1. How many unique pizza types are available in each category (Classic, Chicken, Supreme, Veggie)?

SELECT category, COUNT(category) as cnt FROM pizza_types
GROUP BY category
ORDER BY cnt DESC;

-- 2. What is the average price of pizzas in each size category (Small, Medium, Large, etc.)?
SELECT pizza_size, CAST(AVG(price) AS DECIMAL(4,2)) as avg_price FROM pizzas
GROUP BY pizza_size
ORDER BY avg_price DESC;

-- 3. How many orders were placed on a specific date?
SELECT MIN(order_date), MAX(order_date) FROM ORDERS;  # check date range

SELECT order_date, COUNT(order_date) FROM orders
WHERE order_date = '2015-07-23'
GROUP BY order_date;

-- 4. List the top 5 pizza types with the highest quantity ordered.
SELECT pizza_id, MAX(quantity) as max_order FROM order_details
GROUP BY pizza_id
ORDER BY max_order DESC
LIMIT 5;


-- 5. Calculate the total revenue generated from pizza sales on a specific date.
SELECT order_date, SUM(order_details.quantity*pizzas.price) as total_revenue FROM orders
JOIN order_details ON order_details.order_id = orders.order_id
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
WHERE order_date = '2015-07-23'
GROUP BY order_date

/* Medium:
*/
--6. For each pizza category, what is the most popular pizza size based on the total quantity ordered?

/* This was a step up, and I had to learn about partitioning
The row number and partition creates a group for each category containing the total order quantity for each size, and numbers the rows
this query returns a table called ranked_pizzas, from which I then select the first row. Since we ordered by descending sum(quantity)

*/


WITH ranked_pizzas AS (
	SELECT 
		pizza_types.category,
		pizza_size,
		SUM(order_details.quantity) as total_q,
		ROW_NUMBER() OVER(PARTITION BY pizza_types.category ORDER BY SUM(order_details.quantity) DESC) AS row_num 
		FROM pizzas
	JOIN order_details ON order_details.pizza_id = pizzas.pizza_id
	JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
	GROUP BY pizza_types.category, pizza_size
)
SELECT category, pizza_size, total_q FROM ranked_pizzas
WHERE row_num = 1;


--7. Identify the top 3 pizza types that have the highest average order quantity.

--8. List the pizza types that include "Mushrooms" as an ingredient and the number of times they've been ordered.
SELECT pizza_types.pizza_name, SUM(quantity) as total_times_ordered FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
WHERE pizza_types.ingredients LIKE '%Mushroom%'
GROUP BY pizza_types.pizza_name;

--9. Find the average number of pizzas ordered per order for each pizza category.
SELECT pizza_types.category, CAST(AVG(order_details.quantity) AS DECIMAL(4,3)) FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category;

--10. Identify the pizza type that has the highest revenue generated and the corresponding pizza category.
SELECT pizza_types.pizza_name, pizza_types.category, SUM(order_details.quantity*pizzas.price) as total_revenue FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.pizza_name, pizza_types.category
ORDER BY total_revenue DESC
LIMIT 1;

/* Hard:
*/
--11. Determine the month with the highest revenue and the top 3 pizza types sold in that month.

--12. Calculate the cumulative revenue for each month, considering the revenue is accumulated from the start of the year.

--13. Identify the top 5 customers who have ordered the most pizzas, including the quantity and total spent.

--14. Calculate the percentage contribution of each pizza type to the total revenue.

--15. List the pizza types that have shown an increasing trend in the number of orders over the past 3 months.


/* 
My own ideas

-- How many pizzas are sold each day of the week/each month of the year on average?
-- How many of each type of pizza is sold (and on which days of the week)
-- What the 3 most popular (best-selling) pizzas?
-- What the 3 most popular orders (1 or more pizzas)

*/