# Case Study #2 - Pizza Runner
![image](https://user-images.githubusercontent.com/120476961/225864035-9731b922-da09-42f1-9335-ef1d72cb359e.png)
## Introduction
Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.
## Data
### Relationship diagram
![image](https://user-images.githubusercontent.com/120476961/225865271-ae9e8750-df58-4c8a-a920-efcb2dcb82c3.png)
## Task questions
This case study has LOTS of questions - they are broken up by area of focus including:
### A. Pizza Metrics 
1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

### B. Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?

### C. Ingredient Optimisation
1. What are the standard ingredients for each pizza?
2. What was the most commonly added extra?
3. What was the most common exclusion?
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

### D. Pricing and Ratings
1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
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
5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
## Data cleaning
Before going through questions of Case Study #2. We need to clean database ('null' values, strings,etc ...). And some new table for specific questions.
### 1. Table customer_orders
#### Create a clean temp table #customer_orders
- Change all the blanks value or 'null' to NULL value
```sql
SELECT order_id, 
        customer_id,
        pizza_id, 
        CASE WHEN exclusions = '' OR exclusions like 'null' THEN NULL
            ELSE exclusions END AS exclusions,
        CASE WHEN extras = '' OR extras like 'null' THEN NULL
            ELSE extras END AS extras, 
        order_time
INTO #customer_orders -- create TEMP TABLE
FROM customer_orders;
```
#### Original table :
![image](https://user-images.githubusercontent.com/120476961/226275857-4a806e2b-ccd4-4bad-99d7-ee2e62f4068a.png)
#### Cleaned table :
![image](https://user-images.githubusercontent.com/120476961/226276116-52a5e4c8-eeae-4a9a-aa0b-1d901ebc505c.png)
### 2. Table runner_orders
#### Create a clean temp table #runner_orders
- Changing all the NULL and 'null' to blanks for strings
- Changing all the 'null' to NULL for non strings
- Removing 'km' from distance
- Removing anything after the numbers from duration
```sql
SELECT  order_id, 
        runner_id,
        CASE 
          WHEN pickup_time LIKE 'null' THEN NULL
          ELSE pickup_time 
          END AS pickup_time,
        CASE 
          WHEN distance LIKE 'null' THEN NULL
          WHEN distance LIKE '%km' THEN TRIM('km' from distance) 
          ELSE distance END AS distance,
        CASE 
          WHEN duration LIKE 'null' THEN NULL 
          WHEN duration LIKE '%mins' THEN TRIM('mins' from duration) 
          WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)        
          WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)       
          ELSE duration END AS duration,
        CASE 
          WHEN cancellation LIKE 'null' THEN NULL
          WHEN cancellation = '' THEN NULL
          ELSE cancellation END AS cancellation
INTO #runner_orders
FROM runner_orders;
```
#### Original table :
![image](https://user-images.githubusercontent.com/120476961/226289713-fa823df2-a1c9-4720-a19a-f5e2a17915a3.png)
#### Cleaned table :
![image](https://user-images.githubusercontent.com/120476961/226289489-05a4fd12-39a5-49b1-8914-cbbc6a3c2f6e.png)
### 3. Change several data types of columns
```sql
ALTER TABLE #runner_orders 
ALTER COLUMN pickup_time DATETIME

ALTER TABLE #runner_orders
ALTER COLUMN distance FLOAT

ALTER TABLE #runner_orders
ALTER COLUMN duration INT;

ALTER TABLE pizza_names
ALTER COLUMN pizza_name VARCHAR(MAX);

ALTER TABLE pizza_recipes
ALTER COLUMN toppings VARCHAR(MAX);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name VARCHAR(MAX)
```
## Solution
## Method applied
- Data Cleaning
- Creating Tables
- JOINS
- Aggregate Functions including STRING_AGG()
- CTE's
- CASE Statements
- Subqueries
- String Functions like CONCAT()
