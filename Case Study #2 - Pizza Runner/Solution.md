## Solution
### A. Pizza Metrics
#### 1. How many pizzas were ordered?
```sql
select count(pizza_id) as Amount_pizza_were_ordered from #customer_orders
```
![image](https://user-images.githubusercontent.com/120476961/226347943-fce578c2-1b21-404d-ab72-7a82b5f87c25.png)
#### 2. How many unique customer orders were made?
```sql
select count(distinct(order_id)) as Amount_unique_customer_ordered from #customer_orders
```
![image](https://user-images.githubusercontent.com/120476961/226347853-58064188-fdde-4f85-b33e-5213931daaaf.png)
#### 3. How many successful orders were delivered by each runner?
```sql
select runner_id ,count(runner_id) as successful_ordered from #runner_orders
where cancellation is NULL
group by runner_id
```
![image](https://user-images.githubusercontent.com/120476961/226347768-55f99036-b6ec-4bb4-8ecb-212e9ff9e46f.png)
#### 4. How many of each type of pizza was delivered?
```sql
select pizza_id , count(pizza_id) as'Amount'from #customer_orders as c right join #runner_orders as r
on c.order_id = r.order_id
where cancellation is NULL
group by pizza_id
```
![image](https://user-images.githubusercontent.com/120476961/226347703-3c851b94-5d15-490c-908f-0d926af809d7.png)
#### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
select c.customer_id, p.pizza_name, count(*) as'Amount of pizza'from #customer_orders as c 
inner join #runner_orders as r
on c.order_id = r.order_id
inner join pizza_names as p
on c.pizza_id = p.pizza_id
group by c.customer_id, p.pizza_name
```
![image](https://user-images.githubusercontent.com/120476961/226345941-1df3b260-f448-4500-b056-49d516ca2f79.png)
#### 6. What was the maximum number of pizzas delivered in a single order?
```sql
select top(1) order_id, count(*) as Amount_pizza from #customer_orders
group by (order_id)
order by Amount_pizza desc
```
![image](https://user-images.githubusercontent.com/120476961/226347643-0ef8533c-0e77-4aec-8091-2b11d8e7f822.png)
#### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
with status_table 
as
(
select *,
(case
when exclusions is not NULL or extras is not NULL then 'change'
else 'not change'
end) as statuss
from #customer_orders 
)

SELECT customer_id, statuss,  COUNT(statuss) as count FROM status_table s 
RIGHT JOIN #runner_orders r ON s.order_id = r.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id,statuss
ORDER BY customer_id
```
![image](https://user-images.githubusercontent.com/120476961/226346426-a6cfa68a-4f24-47b0-bc6e-c68ae8b607f3.png)
#### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT count(*) FROM #customer_orders c RIGHT JOIN #runner_orders r 
ON c.order_id = r.order_id
WHERE r.cancellation is NULL and c.exclusions is not NULL and c.extras is not null
```
![image](https://user-images.githubusercontent.com/120476961/226347535-f6d3711e-82e9-4834-b4b0-cbc485322e3a.png)
#### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT DATEPART(HOUR, [order_time]) as Hour, count(*) as AMount  FROM #customer_orders
group by DATEPART(HOUR, [order_time])
```
![image](https://user-images.githubusercontent.com/120476961/226347241-8a89fca2-c4be-420c-a389-16d776807c1c.png)
#### 10. What was the volume of orders for each day of the week?
```sql
SELECT DATENAME(WEEKDAY,[order_time]) as Day, count(*) as AMount  FROM #customer_orders
group by DATENAME(WEEKDAY,[order_time])
```
![image](https://user-images.githubusercontent.com/120476961/226347308-c2ecdbe5-30a4-4fe0-91b9-14a530b6cc5f.png)


### B. Runner and Customer Experience
#### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SET DATEFIRST 1; 
SELECT DATEPART(WEEK,[registration_date])as week, 
        COUNT(runner_id) as runner_count 
FROM runners
GROUP BY DATEPART(WEEK,[registration_date]);
```
![image](https://user-images.githubusercontent.com/120476961/226356027-4ca9d7f6-ac86-491f-b54c-5e3cf26e28be.png)

#### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
WITH time_table AS (
SELECT  distinct runner_id, 
r.order_id,
order_time, 
pickup_time, 
CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
)

SELECT runner_id, round(AVG(time),2)  AS average_time
FROM time_table
GROUP BY runner_id;
```
![image](https://user-images.githubusercontent.com/120476961/226356551-53eba27a-aec2-4b8f-a9e1-58858f79e1bb.png)

#### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH CTE AS (SELECT  c.order_id,
                      COUNT(c.order_id) as pizza_order,
                      order_time, pickup_time, 
                      CAST(DATEDIFF( minute,order_time,pickup_time) AS FLOAT) as time
FROM #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id
WHERE r.cancellation IS NULL 
GROUP BY  c.order_id,order_time, pickup_time)

SELECT pizza_order,
        AVG(time) AS avg_time_per_order, 
        (AVG(time)/ pizza_order) AS avg_time_per_pizza
FROM CTE
GROUP BY pizza_order
```
![image](https://user-images.githubusercontent.com/120476961/226356669-f107c37f-625b-4779-8d23-f1b7d734a90d.png)
- Here we can see that as the number of pizzas in an order goes up, so does the total prep time for that order, as you would expect.
- But then we can also notice that the average preparation time per pizza is higher when you order 1 than when you order multiple.
#### 4. What was the average distance travelled for each customer?
```sql
select c.customer_id, round(AVG(r.distance),2) avg_dis from #customer_orders c 
INNER JOIN #runner_orders r 
ON C.order_id = R.order_id and cancellation is NULL
group by c.customer_id
``` 
![image](https://user-images.githubusercontent.com/120476961/226356789-03166a48-15ec-4af8-8a6b-8156e31b9543.png)

#### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT  max(duration) as longest,
        min(duration) as shortest,
        max(duration) - min(duration) as dif_longest_shortest
FROM #runner_orders
WHERE cancellation is NULL
```
![image](https://user-images.githubusercontent.com/120476961/226356902-c972aede-e9ac-4b15-a866-3098ffae0b91.png)

#### 6. What was the average speed for each runner for each delivery ?
```sql
select runner_id, order_id, round(AVG(distance*60/duration),2) as avg_speed from #runner_orders
where cancellation is null
group by runner_id, order_id
```
![image](https://user-images.githubusercontent.com/120476961/226357028-2f226c5d-4803-454f-82e1-77019d0ecdec.png)

#### 7. What is the successful delivery percentage for each runner?
```sql
with cte as (
select 
runner_id,
case
when cancellation is NULL then 1
else 0 
end as caculate
from #runner_orders
)
select runner_id, sum(caculate) * 100/COUNT(runner_id) as pre_succes from cte
group by runner_id
```
![image](https://user-images.githubusercontent.com/120476961/226357200-81040b65-4382-4cf7-b70d-61b8f2dd883d.png)


### C. Ingredient Optimisation
#### Data cleaning for this part
1. Cleaning pizza_recipes table by creating a clean temp table
- Splitting comma delimited lists into rows
###### Original table:
![image](https://user-images.githubusercontent.com/120476961/226626834-003e76e7-24ab-4190-8e49-5a7e5bb7067a.png)
```sql
SELECT pizza_id, 
        RTRIM(topping_id.value) as topping_id,
       topping_name
INTO #pizza_recipes  
FROM pizza_recipes p
CROSS APPLY string_split(p.toppings, ',') as topping_id
INNER JOIN pizza_toppings p2 ON TRIM(topping_id.value) = p2.topping_id
```
###### New table :
![image](https://user-images.githubusercontent.com/120476961/226627215-2b1a085c-4659-45b8-9d6b-d160e3f1e412.png)

2. Cleaning #customer_orders table for question 4 5
- Adding an Identity Column (to be able to uniquely identify every single pizza ordered)
###### Original table:
![image](https://user-images.githubusercontent.com/120476961/226628793-1d989d68-b296-4f8d-99e2-0ceb48a075dd.png)
```sql
ALTER TABLE #customer_orders
ADD record_id INT IDENTITY(1,1)
```
###### New table :
![image](https://user-images.githubusercontent.com/120476961/226628885-42083908-b305-457e-b80e-6517c73430d3.png)


3. Add New Tables: Exclusions & Extras from #customer_orders table
- Splitting the exclusions & extras comma delimited lists from #customer_orders into rows and storing in new tables
###### #customer_orders table
![image](https://user-images.githubusercontent.com/120476961/226628885-42083908-b305-457e-b80e-6517c73430d3.png)
###### New extras table
```sql
SELECT		
      c.record_id,
      TRIM(ext.value) AS topping_id
INTO #extras
FROM #customer_orders as c
CROSS APPLY string_split(c.extras, ',') as ext;
```
![image](https://user-images.githubusercontent.com/120476961/226630198-311db8fa-e7e3-46ee-ab6e-04b09a3302f1.png)

###### New exclusions table
```sql
SELECT	c.record_id,
	      TRIM(ex.value) AS topping_id
INTO #exclusions
FROM #customer_orders as c
CROSS APPLY string_split(c.exclusions, ',') as ex;
```
![image](https://user-images.githubusercontent.com/120476961/226630557-459687b2-cf07-45ac-b445-86b9abb26da4.png)

#### 1. What are the standard ingredients for each pizza?
```sql
SELECT pizza_id, String_agg(topping_name,',') as Standard_toppings
FROM #pizza_recipes
GROUP BY pizza_id;
```
![image](https://user-images.githubusercontent.com/120476961/226643044-ebad47cc-a307-4faa-b732-b1872263b514.png)

#### 2. What was the most commonly added extra?
```sql
select top(1) e.topping_id, p.topping_name, count(*) as extra_toppings_time from #extras e inner join pizza_toppings p
on e.topping_id = p.topping_id
group by e.topping_id, p.topping_name
order by(count(*)) desc
```
![image](https://user-images.githubusercontent.com/120476961/226642965-77b24c41-11ac-48cc-ac74-978d2aa1955c.png)

#### 3. What was the most commonly exclusion?
```sql
select top(1) e.topping_id, p.topping_name, count(*) as extra_toppings_time from #exclusions e inner join pizza_toppings p
on e.topping_id = p.topping_id
group by e.topping_id, p.topping_name
order by(count(*)) desc
``` 
![image](https://user-images.githubusercontent.com/120476961/226642891-a91b9681-f110-4587-aa14-a9c0224b0c23.png)

#### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
with cte_exclude as(
select  e.record_id, CONCAT(' - Exclude ', STRING_AGG(p.topping_name,', ')) as optional from #exclusions e inner join pizza_toppings p
on e.topping_id = p.topping_id
group by e.record_id),
cte_extra as (
select  e.record_id, CONCAT(' - Extras ', STRING_AGG(p.topping_name,', ')) as optional from #extras e inner join pizza_toppings p
on e.topping_id = p.topping_id
group by e.record_id),
union_cte as(
select * from cte_exclude
union
select * from cte_extra)

select c.record_id,c.order_id, CONCAT(p.pizza_name,STRING_AGG(optional,', ')) as list
from #customer_orders c
inner join pizza_names p 
on c.pizza_id = p.pizza_id 
left join union_cte u
on c.record_id = u.record_id 
group by c.record_id, c.order_id, p.pizza_name
```
![image](https://user-images.githubusercontent.com/120476961/226642786-596b5482-3f12-4c2a-8083-2b2bbfc6a80a.png)

#### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients . For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
```sql
with cte as(
select cu.record_id,p1.pizza_name,
case when
    p.topping_id in( SELECT topping_id FROM #extras e WHERE cu.record_id = e.record_id ) then 'X2'+ p.topping_name
    ELSE p.topping_name
    END AS topping
from #customer_orders cu inner join #pizza_recipes p
on cu.pizza_id = p.pizza_id
inner join pizza_names p1
on cu.pizza_id = p1.pizza_id

)
select cu.record_id, CONCAT(c.pizza_name +':' ,STRING_AGG(topping, ',' )) as list from #customer_orders cu inner join cte c
on cu.record_id = c.record_id
group by cu. record_id,c.pizza_name
order by cu.record_id
```
![image](https://user-images.githubusercontent.com/120476961/226642597-0dfcc7c4-b333-44b6-8937-b41b2e390974.png)

#### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH INGREDIENT_CTE AS (
SELECT record_id,
pizza_name, 
topping_name,
 CASE WHEN p1.topping_id in (
                             SELECT topping_id
                             FROM #extras e
                             WHERE C.record_id = e.record_id
                             ) THEN 2
ELSE 1
END AS times_used_topping
FROM #customer_orders c 
JOIN pizza_names p2 ON c.pizza_id = p2.pizza_id
JOIN #pizza_recipes p1 ON c.pizza_id = p1.pizza_id
JOIN #runner_orders r ON c.order_id = r.order_id
WHERE p1.topping_id NOT IN (SELECT topping_id 
FROM #exclusions e 
 WHERE e.record_id = c.record_id) 
 and r.cancellation is NULL
)

SELECT topping_name, 
SUM(times_used_topping) AS times_used_topping
from INGREDIENT_CTE
GROUP BY topping_name
order by times_used_topping desc;
```
![image](https://user-images.githubusercontent.com/120476961/226641611-017646f3-8396-4313-9940-dd9334dfe223.png)

### D. Pricing and Ratings
#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
with cte as (
select 
pizza_id, 
pizza_name,
case when
pizza_name = 'Meatlovers' THEN 12
ELSE 10 END AS pizza_cost
from pizza_names 
)
select sum(c.pizza_cost) as total
from #customer_orders cu 
join #runner_orders r
on cu.order_id = r.order_id
join cte c
on cu.pizza_id = c.pizza_id
where r.cancellation is null
``` 
![image](https://user-images.githubusercontent.com/120476961/226645521-44ff5935-3731-436a-9579-76604b006b5b.png)

#### 2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
```sql
with cte1 as (
select pizza_id, pizza_name,
case when
pizza_name = 'Meatlovers' THEN 12
ELSE 10 END AS cost
from pizza_names 
) ,
cte2 as(
select 
case when cu.extras is null then c.cost
else c.cost + len(replace(cu.extras,', ','' ))
end as pizza_cost
from #customer_orders cu join cte1 c
on cu.pizza_id = c.pizza_id
join #runner_orders r 
on cu.order_id = r.order_id
where r.cancellation is null
)
select sum(pizza_cost) as total from cte2
```
![image](https://user-images.githubusercontent.com/120476961/226645645-3db6bc1c-84e0-416d-8fce-ba802938bcee.png)

#### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
CREATE TABLE ratings 
 (order_id INTEGER,
    rating INTEGER);
INSERT INTO ratings
 (order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 
SELECT * from ratings
```
![image](https://user-images.githubusercontent.com/120476961/226645889-bda47613-16a2-477e-a3ab-72bf00689f8f.png)

#### 4. Using your newly generated table - can you join all of the information together to form a table 
- which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
```sql
SELECT customer_id , 
        c.order_id, 
        runner_id, 
        rating, 
        order_time, 
        pickup_time, 
        datepart( minute,pickup_time - order_time) as Time__order_pickup, 
        r.duration, 
        round(avg(distance/duration*60),2) as avg_Speed, 
        COUNT(pizza_id) AS Pizza_Count
FROM #customer_orders c
LEFT JOIN #runner_orders r ON c.order_id = r.order_id 
LEFT JOIN ratings r2 ON c.order_id = r2.order_id
WHERE r.cancellation is NULL
GROUP BY customer_id , c.order_id, runner_id, rating, order_time, pickup_time, datepart( minute,pickup_time - order_time) , r.duration
ORDER BY c.customer_id;
``` 
![image](https://user-images.githubusercontent.com/120476961/226646626-9a9c0ff8-a7eb-4183-a5c2-367a771af04d.png)

#### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
with cte as(
select 
cu.order_id,
sum(case when pizza_name = 'Meatlovers' THEN 12
else 10 end )as pizza_price
from pizza_names n
join #customer_orders cu on cu.pizza_id = n.pizza_id
group by cu.order_id
)
select  
sum(cte.pizza_price) as revenue,
sum( r.distance*0.3) as total_cost,
sum(cte.pizza_price) - sum( r.distance*0.3) as profit
from  #runner_orders r 
join cte on r.order_id = cte.order_id
where r.cancellation is null
```
![image](https://user-images.githubusercontent.com/120476961/226647063-a0980557-6be1-495b-a7f0-071bbeb18d2c.png)

