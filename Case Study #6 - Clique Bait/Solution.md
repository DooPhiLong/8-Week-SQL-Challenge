## Solution
### A. Digital Analysis
**1. How many users are there?**

````sql
SELECT COUNT(DISTINCT user_id)  AS Total_User 
FROM users 
````

![image](https://user-images.githubusercontent.com/101379141/197101422-886c3d1a-da6e-4e06-86b4-a277f150c2d8.png)

**2. How many cookies does each user have on average?**

````sql
SELECT COUNT(DISTINCT user_id)  AS Total_User,
        COUNT(cookie_id) as total_cookie,
        cast(COUNT(cookie_id) as float) / COUNT(DISTINCT user_id)  as average_cookie
FROM users 
````

![image](https://user-images.githubusercontent.com/101379141/197101610-555e3807-4f4d-4a49-b7b4-c97720752551.png)

**3. What is the unique number of visits by all users per month?**
- First, extract numerical month from `event_time` so that we can group the data by month.
- Unique is a keyword to use `DISTINCT`.

````sql
SELECT DATEPART(MONTH, event_time) AS month ,
        COUNT(DISTINCT visit_id ) as number_visit
FROM events
GROUP BY DATEPART(MONTH, event_time)
ORDER BY month
````

![image](https://user-images.githubusercontent.com/101379141/197101708-7c643a7b-ea33-4164-ad63-2ac9ea023b25.png)

**4. What is the number of events for each event type?**

````sql
SELECT event_type,
        count(event_type) as number_events
FROM events
GROUP BY event_type 
ORDER BY event_type;
````

![image](https://user-images.githubusercontent.com/101379141/197101756-7afab09d-a239-46f1-9afa-8490b42d45d3.png)

**5. What is the percentage of visits which have a purchase event?**
- Join the events and events_identifier table and filter by `Purchase` event only. 
- As the data is now filtered to having `Purchase` events only, counting the distinct visit IDs would give you the number of purchase events.
- Then, divide the number of purchase events with a subquery of total number of distinct visits from the `events` table.

````sql
SELECT event_name, 
        COUNT(e1.event_type) as number_events,
        CAST(100* CAST(COUNT(e1.event_type) AS FLOAT) / (SELECT COUNT( DISTINCT VISIT_ID) FROM events) AS DECIMAL(10,2)) AS Percent_visit
FROM events e1
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE event_name = 'Purchase'
GROUP BY event_name;
````

![image](https://user-images.githubusercontent.com/101379141/197101880-4746d94b-8766-4126-9bd3-d3042f858156.png)

**6. What is the percentage of visits which view the checkout page but do not have a purchase event?**
The strategy to answer this question is to breakdown the question into 2 parts.

Part 1: Create a `CTE` and using `CASE statements`, find the `SUM()` of:
- `page_name` = 'Checkout' (Checkout), and assign "1" to these events. These events are when user viewed the checkout page.
- `event_name` ='Purchase' and assign "1" to these events. These events signifies users who made a purchase.


Part 2: Using the table we have created, find the percentage of visits which view checkout page.

````sql
WITH CTE AS  (  SELECT 
                        SUM( CASE WHEN page_name = 'Checkout' then 1 else 0 end ) AS checkout_visit,
                        SUM( CASE WHEN event_name = 'Purchase' then 1 else 0 end ) as purchase_visit
                FROM events e1
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                JOIN page_hierarchy p ON e1.page_id = p.page_id
                WHERE page_name = 'Checkout' or  event_name = 'Purchase'
                )

SELECT 100*(checkout_visit - purchase_visit)/ cast(checkout_visit as float) as percent_not_purchase
FROM CTE 

````

![image](https://user-images.githubusercontent.com/101379141/197102260-32a165a1-34a5-48fe-9538-8f4d7fb82e98.png)

**7. What are the top 3 pages by number of views?**

````sql
SELECT  TOP 3 page_name, 
        COUNT (e1.page_id) AS total_view
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
GROUP BY page_name
ORDER BY total_view DESC
````
![image](https://user-images.githubusercontent.com/101379141/197102364-c76ca704-b923-4724-a55f-96a5274acb30.png)


**8. What is the number of views and cart adds for each product category?**

````sql
SELECT  product_category, 
       SUM (CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS total_view, 
       SUM (CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_cart
FROM events e1 
JOIN page_hierarchy p ON e1.page_id = p.page_id
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE product_category IS NOT NULL 
GROUP BY product_category;

````

![image](https://user-images.githubusercontent.com/101379141/197102414-7da76616-e197-41d6-9626-58a577f2c1b9.png)

**9. What are the top 3 products by purchases?**

````sql
WITH CTE AS (SELECT visit_id
FROM events e1 
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE event_name = 'Purchase')

SELECT page_name, COUNT(e1.visit_id) as purchase_item
FROM events e1
RIGHT JOIN CTE C on e1.visit_id = C.visit_id
JOIN page_hierarchy p ON e1.page_id = p.page_id
JOIN event_identifier e2 ON e1.event_type = e2.event_type
WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
GROUP BY page_name
ORDER BY purchase_item DESC ;
````
![image](https://user-images.githubusercontent.com/101379141/197102489-d6fd6643-5535-4302-90a7-67801abc6b33.png)

***
### B. Product Funnel Analysis
Using a single SQL query - create a new output table which has the following details:

1. How many times was each product viewed?
2. How many times was each product added to cart?
3. How many times was each product added to a cart but not purchased (abandoned)?
4. How many times was each product purchased?

## Planning Our Strategy

Let us visualize the output table.

| Column | Description | 
| ------- | ----------- |
| product | Name of the product |
| views | Number of views for each product |
| cart_adds | Number of cart adds for each product |
| abandoned | Number of times product was added to a cart, but not purchased |
| purchased | Number of times product was purchased |

These information would come from these 2 tables.
- `events` table - visit_id, page_id, event_type
- `page_hierarchy` table - page_id, product_category

**Solution**
- Note 1 - In first CTE, find all customer have done event 'Page View'
- Note 2 - In `VIEW_CTE` CTE, count all customer with event 'Page View'
- Note 3 - In `ADD_CART_CTE` CTE, count all customer with event 'Add to Cart'
- Note 4 - In `PURCHASE_CTE` and 'PURCHASE_CTE_2' CTE, count all customer with event 'Purchase'
- merge all CTE above using `LEFT JOIN`. 
```sql

WITH CTE AS (   SELECT distinct visit_id
                FROM events e1 
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                WHERE event_name = 'Page View'),

VIEW_CTE AS (   SELECT page_name,
                        product_category,
                        count(page_name) AS total_view
                        FROM events e1 
                        LEFT JOIN CTE c ON e1.visit_id = c.visit_id 
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Page View' 
                        GROUP BY page_name,product_category),

ADD_CART_CTE AS (SELECT page_name,
                        product_category,
                        count(page_name) AS total_add
                        FROM events e1 
                        LEFT JOIN CTE c ON e1.visit_id = c.visit_id 
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Add to Cart' 
                        GROUP BY page_name,product_category),

PURCHASE_CTE AS (SELECT visit_id
                FROM events e1 
                JOIN event_identifier e2 ON e1.event_type = e2.event_type
                WHERE event_name = 'Purchase'),
PURCHASE_CTE_2 AS (     SELECT  page_name,
                                product_category,
                                COUNT(e1.visit_id) as purchase_item
                        FROM events e1
                        RIGHT JOIN PURCHASE_CTE C on e1.visit_id = C.visit_id
                        JOIN page_hierarchy p ON e1.page_id = p.page_id
                        JOIN event_identifier e2 ON e1.event_type = e2.event_type
                        WHERE product_category IS NOT NULL AND event_name = 'Add to Cart'
                        GROUP BY page_name,product_category
                        )


SELECT v.page_name,
        v.product_category,
        total_view,
        total_add,
        purchase_item, 
        (total_add - purchase_item) as abadoned_item
INTO    product_stats
FROM VIEW_CTE V
LEFT JOIN ADD_CART_CTE A ON V.page_name = A.page_name
LEFT JOIN PURCHASE_CTE_2 P ON V.page_name = P.page_name
ORDER BY v.page_name;

SELECT * 
FROM product_stats;
```

The logic behind `abadoned_item` column is result of total_add minus purchase_item

![image](https://user-images.githubusercontent.com/101379141/197104295-cf473b09-6ec4-4b22-bced-d9df4fdc4b2b.png)


***

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

**Solution**

```sql
SELECT product_category,
        SUM (total_view) AS total_view,
        SUM(total_add) as total_add,
        SUM(purchase_item) as total_purchase, 
        SUM(abadoned_item) as abadoned_item
FROM product_stats
GROUP BY product_category;

```

![image](https://user-images.githubusercontent.com/101379141/197104412-ece0bd1d-e0b4-41b2-acff-583f6d9ec5af.png)

***

Use your 2 new output tables - answer the following questions:

**1. Which product had the most views, cart adds and purchases?**
```sql
WITH RANK_CTE AS (SELECT *, 
                        RANK() OVER(ORDER BY total_view DESC) AS RANK_VIEW,
                        RANK() OVER(ORDER BY Total_add DESC) as RANK_ADD,
                        RANK() OVER(ORDER BY purchase_item DESC) as RANK_PURCHASE
                FROM product_stats)

SELECT *
FROM RANK_CTE
WHERE RANK_VIEW =1 
        OR RANK_ADD = 1
        OR RANK_PURCHASE = 1
```

![image](https://user-images.githubusercontent.com/101379141/197104522-e41223fd-a88a-4f1f-a270-7ffeb6ab1487.png)

**2. Which product was most likely to be abandoned?**

```sql
SELECT top 1 page_name,
        product_category,
        abadoned_item 
FROM product_stats 
ORDER BY abadoned_item DESC;
```
![image](https://user-images.githubusercontent.com/101379141/197104601-f8b73e04-e300-4741-881d-29118948536e.png)


**3. Which product had the highest view to purchase percentage?**

```sql
SELECT  top 1 page_name,
        product_category,
        total_view,
        purchase_item,
        100*( cast(purchase_item as float)/ total_view) as percent_purchase
FROM product_stats 
ORDER BY percent_purchase DESC ;
```

![image](https://user-images.githubusercontent.com/101379141/197104660-8a03ba1f-d44b-49c0-8e13-267b6a9103b2.png)

- Lobster has the highest view to purchase percentage 

**4. What is the average conversion rate from view to cart add?**

**5. What is the average conversion rate from cart add to purchase?**

```sql
SELECT  ROUND(avg(100*( cast(total_add as float)/ total_view)),2) as rate_view_add,
        ROUND(avg(100*( cast(purchase_item as float)/ total_add)),2) as rate_add_purchase
FROM product_stats 
```

![image](https://user-images.githubusercontent.com/101379141/197104726-07276b44-5db2-475b-8ae4-2613adf89cdf.png)

- Average views to cart adds rate is 60.95% and average cart adds to purchases rate is 75.93%.

***
### C. Campaigns Analysis

Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- `user_id`
- `visit_id`
- `visit_start_time`: the earliest event_time for each visit
- `page_views`: count of page views for each visit
- `cart_adds`: count of product cart add events for each visit
- `purchase`: 1/0 flag if a purchase event exists for each visit
- `campaign_name`: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- `impression`: count of ad impressions for each visit
- `click`: count of ad clicks for each visit
- (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
  
**Solution**

Steps:
- We will merge multiple tables:
  - Using JOIN for `users` and `events` table
  - joining `event_identifier` table using LEFT JOIN to filter the event_name in SELECT
  - Joining `campaign_identifier` table using LEFT JOIN as we want all lines that have `event_time` between `start_date` and `end_date`. 
  - Joining `page_hierachy` table using LEFT JOIN as we want all the rows in the `page_hierachy` table
- To generate earliest `visit_start_time` for each unique `visit_id`, use `MIN()` to find the 1st `visit_time`. 
- Wrap `SUM()` with CASE statement in order to find the total number of counts for `page_views`, `cart_adds`, `purchase`, ad `impression` and ad `click`.
- To get a list of products added into cart sorted by sequence, 
-   Firstly, use a CASE statement to only get cart add events. 
-   Then, use `STRING_AGG()` to separate products by comma `,` and sort the sequence using `sequence_number WITHIN GROUP 

```sql
SELECT  user_id,
        visit_id,
        MIN(event_time) AS visit_start_time,
        SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
        SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
        SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
        c.campaign_name,
        SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
        SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
        STRING_AGG(CASE WHEN event_name = 'Add to Cart' AND p.product_id IS NOT NULL THEN page_name ELSE NULL END, ',' ) WITHIN GROUP (ORDER BY e.sequence_number)
FROM events e 
LEFT JOIN users u ON e.cookie_id = u.cookie_id
LEFT JOIN event_identifier e2 ON e.event_type = e2.event_type
LEFT JOIN campaign_identifier c ON e.event_time BETWEEN c.start_date and c.end_date
LEFT JOIN page_hierarchy p ON e.page_id = p.page_id
GROUP BY user_id,visit_id,c.campaign_name;
```  

![image](https://user-images.githubusercontent.com/101379141/197105542-33dd43ac-7a30-4f7e-a0bb-2f9febea3bbd.png)


*** 
  


