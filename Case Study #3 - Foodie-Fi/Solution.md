## Solution

### A. Customer Journey
#### 1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
- LEAD : Provides access to a row at a given physical offset that follows the current row. Use this analytic function in a SELECT statement to compare values in the current row with values in a following row.
```sql
CREATE TABLE subscriptions_demo (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);

INSERT INTO subscriptions_demo
  (customer_id, plan_id, start_date)
VALUES 
('1',	'0',	'2020-08-01'),
('1',	'1',	'2020-08-08'),
('2',	'0',	'2020-09-20'),
('2',	'3',	'2020-09-27'),
('11','0',	'2020-11-19'),
('11','4'	,'2020-11-26'),
('13','0',	'2020-12-15'),
('13','1'	,'2020-12-22'),
('13',	'2'	,'2021-03-29'),
('15',	'0'	,'2020-03-17'),
('15', '2'	,'2020-03-24'),
('15',	'4'	,'2020-04-29'),
('16',	'0'	,'2020-05-31'),
('16',	'1'	,'2020-06-07'),
('16',	'3'	,'2020-10-21'),
('18',	'0'	,'2020-07-06'),
('18',	'2'	,'2020-07-13'),
('19',	'0'	,'2020-06-22'),
('19',	'2'	,'2020-06-29'),
('19',	'3',	'2020-08-29');
```
![image](https://user-images.githubusercontent.com/120476961/228120918-5f57d122-fd7e-4658-abb7-32a8b1fe2f89.png)

```sql
select 
s.*,
p.plan_name,
datediff(day,  s.start_date,lead(s.start_date) over (partition by s.customer_id order by s.start_date)) as day_contacted,
datediff(month,s.start_date, lead(s.start_date) over (partition by s.customer_id order by s.start_date) ) as month_contacted
from subscriptions_demo as s join plans as p
on s.plan_id = p.plan_id
```
![image](https://user-images.githubusercontent.com/120476961/228121079-0bc080a5-3ebe-4d4e-8e49-5aba92834836.png)

- Customer 1 signed up for a free trial on the 1st of August 2020 and decided to subscribe to the basic monthly plan right after it ended. 
- Customer 2 signed up for a free trial on the 20th of September 2020 and decided to upgrade to the pro annual plan right after it ended.
- Customer 11 signed up for a free trial on the 19th of November 2020 decided to upgrade to the churn plan right after it ended.
- Customer 13 signed up for a free trial on the 15th of December 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro monthly plan three months later. 
- Customer 15 signed up for a free trial on the 17th of March 2020 and then decided to upgrade to the pro monthly plan right after it ended for one month before cancelling it. 
- Customer 16 signed up for a free trial on the 31st of May 2020, decided to subscribe to the basic monthly plan right after it ended and upgraded to the pro annual plan four months later.
- Customer 18 signed up for a free trial on the 6th of July 2020 and then went on to pay for the pro monthly plan right after it ended. 
- Customer 19 signed up for a free trial on the 22nd of June 2020, and then decided to upgrade to the pro monthly plan right after it ended and upgraded to the pro annual plan two months later. 
### B. Data Analysis Questions
#### 1. How many customers has Foodie-Fi ever had?
```sql
select count(distinct(customer_id)) as Number_of_customer from subscriptions
```
![image](https://user-images.githubusercontent.com/120476961/228122346-8ab2d9ae-3a3f-4053-89f0-9cb1ac303aa9.png)

#### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value. 
- DATEPART : Returns a time value of the passed argument, which can be a day, month, year, quarter, hour, minute, second, millisecond... The return value is an integer (int).
```sql
SELECT DATEPART(month, s.start_date) as month , COUNT(s.customer_id) as number_of_trial
FROM subscriptions s LEFT JOIN plans p 
ON s.plan_id =p.plan_id 
where plan_name = 'trial'
GROUP BY DATEPART(month, start_date)
order by DATEPART(month, start_date)
```
![image](https://user-images.githubusercontent.com/120476961/228122494-48bdf7fe-aeac-4862-bfc7-bcd26154284e.png)

#### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
- DATEPART : Returns a time value of the passed argument, which can be a day, month, year, quarter, hour, minute, second, millisecond... The return value is an integer (int).
```sql
SELECT  p.plan_name, COUNT(s.customer_id) as number_of_trial
FROM subscriptions s LEFT JOIN plans p 
ON s.plan_id =p.plan_id 
where DATEPART(YEAR, s.start_date) > 2020
GROUP BY p.plan_name
```
![image](https://user-images.githubusercontent.com/120476961/228122618-dc97f510-4b42-446d-b241-0b1182523ba1.png)

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
- Cast : Change the data type
```sql
with 
num_of_cus as (
select count(distinct(customer_id)) as Number_of_customer from subscriptions
),
num_of_churned_cus as(
select count(distinct(customer_id)) as Number_of_churned_customer from subscriptions s left join plans p
on s.plan_id = p.plan_id
where p.plan_name = 'churn'
)
select 
Number_of_churned_customer,
Number_of_customer,
cast(Number_of_churned_customer as float)*100 / cast(Number_of_customer as float)
from num_of_cus, num_of_churned_cus
``` 
![image](https://user-images.githubusercontent.com/120476961/228122708-7ba6117c-2a77-4cc4-86b0-8559ee4f714c.png)

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole numbe
- LEAD : Provides access to a row at a given physical offset that follows the current row. Use this analytic function in a SELECT statement to compare values in the current row with values in a following row.
```sql
WITH CTE AS(
SELECT *, 
LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions
) 
SELECT 
plan_name , 
COUNT(next_plan) as number_churn, 
CAST(count(next_plan) AS FLOAT) * 100 / (select count(distinct customer_id) from subscriptions) as perc_straight_churn
FROM CTE c
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE next_plan = 4 and c.plan_id = 0
GROUP BY plan_name;
```
![image](https://user-images.githubusercontent.com/120476961/228123005-ec56ee33-5e2a-490b-a8dc-5b1810fe0f41.png)

#### 6. What is the number and percentage of customer plans after their initial free trial?
- LEAD : Provides access to a row at a given physical offset that follows the current row. Use this analytic function in a SELECT statement to compare values in the current row with values in a following row.
- Cast : Change the data type
```sql
WITH CTE AS(
SELECT *, 
LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions) 

SELECT plan_name, 
count(*) as num_plan, 
Cast(count(next_plan) as float) * 100 / (select count(distinct customer_id) from subscriptions) as perc_next_plan
FROM CTE c 
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE  c.plan_id = 0 and next_plan is not NULL
GROUP BY plan_name,next_plan;
```
![image](https://user-images.githubusercontent.com/120476961/228123248-96fbee63-9d8a-4f5c-a2aa-ccd6378c28c9.png)

#### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
- LEAD : Provides access to a row at a given physical offset that follows the current row. Use this analytic function in a SELECT statement to compare values in the current row with values in a following row.
```sql
with cte as (
select * ,
LEAD(start_date,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_date
FROM subscriptions
where start_date <= '2020-12-31'
)
SELECT C.plan_id,
plan_name, 
count(C.plan_id)  AS customer_count,  
(CAST(count(C.plan_id) AS Float) *100 / (select count(distinct customer_id) FROM subscriptions) ) as Percentage_customer
FROM CTE c
LEFT JOIN plans P ON C.plan_id= P.plan_id
WHERE c.next_date is NULL or c.next_date >'2020-12-31' 
GROUP BY C.plan_id,plan_name
ORDER BY plan_id
```
![image](https://user-images.githubusercontent.com/120476961/228123345-b92b426b-4b35-4a41-9e62-709e553da511.png)
#### 8. How many customers have upgraded to an annual plan in 2020?
```sql
SELECT plan_name, COUNT(s.plan_id) as number_annual_plan
FROM subscriptions s
INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' and start_date <='2020-12-31'
GROUP BY plan_name
```
![image](https://user-images.githubusercontent.com/120476961/228123473-e2bb79ed-5caa-4cbd-bd92-161a566948b4.png)
#### 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?
- DATEDIFF : Returns the difference between two time values based on the specified time period. The two time values must be dates or date and time expressions.
```sql
WITH START_CTE AS (
SELECT customer_id, start_date 
FROM subscriptions s
INNER JOIN plans p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'trial' ),

ANNUAL_CTE AS (
SELECT customer_id, start_date as start_annual
FROM subscriptions s
INNER JOIN 
plans p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' )

SELECT Avg(DATEDIFF(day,start_date,start_annual)) as average_day
FROM ANNUAL_CTE C2
LEFT JOIN START_CTE C1 ON C2.customer_id =C1.customer_id;
```
![image](https://user-images.githubusercontent.com/120476961/228123649-34701bb6-2dab-4ae5-8e52-bc92a60e9412.png)
#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
- DATEDIFF : Returns the difference between two time values based on the specified time period. The two time values must be dates or date and time expressions.
```sql
WITH START_CTE AS (   
SELECT customer_id,start_date 
FROM subscriptions s
INNER JOIN 
plans p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'trial'),

ANNUAL_CTE AS ( 
SELECT customer_id, start_date as start_annual
FROM subscriptions s
INNER JOIN 
plans p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' ),

DIFF_DAY_CTE AS (
SELECT DATEDIFF(day,start_date,start_annual) as diff_day
FROM ANNUAL_CTE C2
LEFT JOIN 
START_CTE C1 
ON C2.customer_id =C1.customer_id),

GROUP_DAY_CTE AS (
SELECT*, FLOOR(diff_day/30) as group_day
FROM DIFF_DAY_CTE)

SELECT 
CONCAT((group_day *30) +1 , '-',(group_day +1)*30, ' days') as days,
COUNT(group_day) as number_days
FROM GROUP_DAY_CTE
GROUP BY group_day;
```
![image](https://user-images.githubusercontent.com/120476961/228123761-180d4cc0-6609-48bc-b5be-b91e242378a2.png)
#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
- LEAD : Provides access to a row at a given physical offset that follows the current row. Use this analytic function in a SELECT statement to compare values in the current row with values in a following row.
```sql
WITH CTE AS(
SELECT *, 
LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscriptions
WHERE start_date <= '2020-12-31')

SELECT COUNT(*) as num_downgrade
FROM CTE 
WHERE next_plan = 1 and plan_id = 2;
```
![image](https://user-images.githubusercontent.com/120476961/228123909-e7b5e2a5-cf13-4b45-a4c3-52e3aebed56e.png)
