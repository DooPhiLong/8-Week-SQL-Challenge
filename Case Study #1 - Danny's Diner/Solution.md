## Solution
### 1/ What is the total amount each customer spent at the restaurant?
```sql
select s.customer_id, sum(m.price) as 'amount each customer spent' from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225851102-acd9eb77-aa61-4716-8cc4-e79c39636bcd.png)

### 2/ How many days has each customer visited the restaurant?
```sql
SELECT s.customer_id, count(distinct(s.order_date)) as 'total_days' FROM sales as s 
group by s.customer_id
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225851850-f48ca2e2-b41e-4efb-9ef5-2db7f11210cd.png)

### 3/ What was the first item from the menu purchased by each customer?
- RANK() : Returns the rank of each row within the partition of a result set. The rank of a row is one plus the number of ranks that come before the row in question.
```sql
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
```sql
select top(1) s.product_id,m.product_name, count(*) as "times was it purchased" from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.product_id, m.product_name
order by count(*) desc
```
#### Result
![image](https://user-images.githubusercontent.com/120476961/225852726-e282aec4-d81d-4832-a344-b1c9b94124ba.png)

### 5/ Which item was the most popular for each customer?
-  RANK() : Returns the rank of each row within the partition of a result set. The rank of a row is one plus the number of ranks that come before the row in 
```sql
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
- RANK() : Returns the rank of each row within the partition of a result set. The rank of a row is one plus the number of ranks that come before the row in 
```sql
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
-  RANK() : Returns the rank of each row within the partition of a result set. The rank of a row is one plus the number of ranks that come before the row in 
```sql
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
```sql
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
```sql
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
- DATEADD : This function adds a number (a signed integer) to a datepart of an input date, and returns a modified date/time value. For example, you can use this function to find the date that is 7000 minutes from today: number = 7000, datepart = minute, date = today.
```sql
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
