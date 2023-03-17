# Case Study #1 - Danny's Diner
![image](https://user-images.githubusercontent.com/120476961/225848936-b987861f-636f-4a3e-b4d6-e9c032df36c9.png)
## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.
## Data
### Relationship diagram
![image](https://user-images.githubusercontent.com/120476961/225849612-fb41d27f-1544-4f2b-8381-4e234fdbe663.png)
## Task questions
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
## Solution
### 1/ What is the total amount each customer spent at the restaurant?
```c
select s.customer_id, sum(m.price) as 'amount each customer spent' from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225851102-acd9eb77-aa61-4716-8cc4-e79c39636bcd.png)

### 2/ How many days has each customer visited the restaurant?
```c
SELECT s.customer_id, count(distinct(s.order_date)) as 'total_days' FROM sales as s 
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225851850-f48ca2e2-b41e-4efb-9ef5-2db7f11210cd.png)

### 3/ What was the first item from the menu purchased by each customer?
```c
WITH PURCHASED_RANK AS (
SELECT customer_id, 
order_date,
product_name, 
RANK() over (partition by customer_id order by order_date asc) as rankkk
FROM sales LEFT JOIN menu
ON sales.product_id = menu.product_id )

SELECT distinct customer_id,product_name
FROM PURCHASED_RANK 
WHERE rankkk =1 
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225852461-e77e7131-f253-49a8-8384-566da79b4737.png)

### 4/ What is the most purchased item on the menu and how many times was it purchased by all customers?
```c
select top(1) s.product_id,m.product_name, count(*) as "times was it purchased" from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.product_id, m.product_name
order by count(*) desc
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225852726-e282aec4-d81d-4832-a344-b1c9b94124ba.png)

### 5/ Which item was the most popular for each customer?
```c
WITH number_of_purchase AS (
select s.customer_id, s.product_id, count(*) as number_of from sales as s
group by s.customer_id, s.product_id
),

number_of_purchase_rank as (
select 
number_of_purchase.customer_id,
number_of_purchase.product_id , 
number_of_purchase.number_of,
RANK() over (partition by customer_id order by number_of_purchase.number_of desc) as rank
from number_of_purchase
)

select a.customer_id,a.product_id , a.number_of from number_of_purchase_rank as a
WHERE rank = 1
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225853007-d968f021-dc6f-4d51-8890-7293fba929bd.png)

### 6/ Which item was purchased first by the customer after they became a member?
```c
with rank_purchase_item as (
select s.customer_id,
s.product_id,
me.product_name,
RANK() over (partition by s.customer_id order by s.order_date asc) as rank
from sales as s inner join members as m
on s.customer_id = m.customer_id  
inner join menu as me
on s.product_id = me.product_id 
where m.join_date <= s.order_date 
)

select * from rank_purchase_item 
where rank_purchase_item.rank = 1
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225853150-0894d198-6d79-4a30-973d-9b23832c0cb9.png)

### 7/ Which item was purchased just before the customer became a member?
```c
with rank_purchase_item as
(
select s.customer_id, s.product_id, me.product_name,
RANK() over (partition by s.customer_id order by s.order_date desc) as rank
from sales as s inner join members as m
on s.customer_id = m.customer_id  
inner join menu as me
on s.product_id = me.product_id 
where m.join_date > s.order_date 
)

select * from rank_purchase_item 
where rank_purchase_item.rank = 1
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225853361-97678e10-42f3-4fec-98c1-ba74fc817caf.png)

### 8/ What is the total items and amount spent for each member before they became a member?
```c
select s.customer_id, count(*) as total_item, sum(me.price) as total_spent from sales as s inner join members as m
on s.customer_id = m.customer_id  
inner join menu as me
on s.product_id = me.product_id 
where m.join_date > s.order_date 
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225853814-806504f0-e9ee-47ca-a7f1-013151399b9b.png)

### 9/ If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```c
select 
s.customer_id, 
sum(
(case
when me.product_name = 'sushi' then me.price*2*10
else  me.price*10
end)) as point
from sales as s inner join  menu as me
on s.product_id = me.product_id 
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225853933-3bb3a7a1-18ad-458c-8c54-6000dfbb0948.png)

### 10/ In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```c
select 
s.customer_id, 
sum(
(case
when me.product_name = 'sushi' then me.price*2*10
when s.order_date >= m.join_date and  s.order_date < DATEADD(day, 7, m.join_date ) then me.price*2*10
else  me.price*10
end)) as point
from sales as s 
inner join  menu as me
on s.product_id = me.product_id 
inner join members as m
on s.customer_id = m.customer_id  
where s.customer_id in ('A','B') and month(s.order_date) <2
group by s.customer_id

```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225854216-175bac63-e131-44a0-a045-5ea5618c602a.png)

## Method applied 
- JOINS
- Aggregate Functions
- Window Functions
- CTE's
- Subqueries
