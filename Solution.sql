use Casestudy1
go

--1/ what is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as 'amount each customer spent' from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.customer_id

--2/ How many days has each customer visited the restaurant?
select s.customer_id, count(distinct(s.order_date)) as 'total_days' from sales as s 
group by s.customer_id

--3/ What was the first item from the menu purchased by each customer?
WITH PURCHASED_RANK AS (
    			SELECT customer_id, 
			       order_date,
			       product_name, 
    			   RANK() over (partition by customer_id order by order_date asc) as rankkk
			FROM sales
			LEFT JOIN menu
			ON sales.product_id = menu.product_id 
			)
SELECT distinct customer_id,product_name
FROM PURCHASED_RANK 
WHERE rankkk =1 

--4/ What is the most purchased item on the menu and how many times was it purchased by all customers?
select top(1) s.product_id,m.product_name, count(*) as "times was it purchased" from sales as s inner join menu as m
on s.product_id = m.product_id
group by s.product_id, m.product_name
order by count(*) desc

--5/ Which item was the most popular for each customer?
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
where rank = 1

--6/ Which item was purchased first by the customer after they became a member?
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

--7/ Which item was purchased just before the customer became a member?
with rank_purchase_item as
(
select s.customer_id,
s.product_id,
me.product_name,
RANK() over (partition by s.customer_id order by s.order_date desc) as rank
from sales as s inner join members as m
on s.customer_id = m.customer_id  
inner join menu as me
on s.product_id = me.product_id 
where m.join_date > s.order_date 
)

select * from rank_purchase_item 
where rank_purchase_item.rank = 1

--8/ What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(*) as total_item, sum(me.price) as total_spent
from sales as s inner join members as m
on s.customer_id = m.customer_id  
inner join menu as me
on s.product_id = me.product_id 
where m.join_date > s.order_date 
group by s.customer_id


--9/ If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
s.customer_id, sum(
(case
when me.product_name = 'sushi' then me.price*2*10
else  me.price*10
end)) as point
from sales as s inner join  menu as me
on s.product_id = me.product_id 
group by s.customer_id


--10/ In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?
select 
s.customer_id, sum(
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



