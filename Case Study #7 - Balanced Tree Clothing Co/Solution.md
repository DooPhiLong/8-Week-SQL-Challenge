## Solution
### A. High Level Sales Analysis

**1. What was the total quantity sold for all products?**

````sql
SELECT SUM(qty) AS total_sold_product
FROM sales
````
![image](https://user-images.githubusercontent.com/101379141/199990351-26ec3035-bf36-4955-8a1e-781fc641e625.png)

**2. What is the total generated revenue for all products before discounts?**

````sql
SELECT SUM(qty * price) as total_revenue
FROM sales
````

![image](https://user-images.githubusercontent.com/101379141/199990537-41a3cdd9-728b-40e0-b752-48652be206cf.png)

**3.What was the total discount amount for all products?**


````sql
SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) as total_discount
FROM sales
````

![image](https://user-images.githubusercontent.com/101379141/199990766-c98eb556-73f2-4586-a87b-3f48bb72b4b6.png)

### B. Transaction Analysis

**1. How many unique transactions were there?**
```sql
SELECT COUNT(DISTINCT txn_id) as Unique_trans
FROM sales;
```

![image](https://user-images.githubusercontent.com/101379141/199992545-1172ae4e-770a-4699-907e-b9eb4cdb5fc3.png)


**2. What is the average unique products purchased in each transaction?**

```sql
SELECT COUNT(qty) / COUNT(DISTINCT txn_id) as average_unique_product 
FROM sales ;
```
![image](https://user-images.githubusercontent.com/101379141/199993180-068f7d85-fe22-4e7d-a575-c4ba96ace3d1.png)

**3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**

```sql
WITH CTE AS ( 
            SELECT  DISTINCT txn_id,
                    SUM(qty * price) as total_revenue
            FROM sales
            GROUP BY txn_id
            )

SELECT  distinct PERCENTILE_CONT(0.25)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_25 , 
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_50,
        PERCENTILE_CONT(0.75)  WITHIN GROUP (ORDER BY total_revenue ) 
                            OVER () AS percentile_75                      
FROM CTE ;
```

![image](https://user-images.githubusercontent.com/101379141/199993935-16f19ee0-2a00-4d98-8de9-61f66e736a74.png)


**4. what is the average discount value per transaction?**

```sql
SELECT SUM(qty * price * (cast(discount as decimal(10,2)) /100) ) / COUNT (distinct txn_id) AS average_discount 
FROM sales ;

```
![image](https://user-images.githubusercontent.com/101379141/199994672-1ae40440-f3e2-41f3-86b0-a49ae4f2d6d6.png)



**5. What is the percentage split of all transactions for members vs non-members?**

```sql
WITH CTE_member AS (SELECT distinct txn_id, 
                            member, 
                            CASE WHEN member = 1 then 1 
                                ELSE 0 END AS member_int
                    FROM sales)

SELECT CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) AS perc_trans_mems,
        100 - CAST( 100* SUM(member_int) AS FLOAT)/COUNT (txn_id) as perc_trans_non_mems
FROM CTE_member ;
```

![image](https://user-images.githubusercontent.com/101379141/199995120-a6f2d803-abc3-45bf-ae08-a93627d44ad7.png)


- The percentage of member's transactions is 60.2
- The percentage of non-member transactions is 39.8

**6. What is the average revenue for member transactions and non-member transactions?**

```sql
WITH CTE_revenue AS (SELECT DISTINCT txn_id,
                            member,
                            SUM(qty * price) as revenue
                    FROM sales
                    GROUP BY txn_id,member )

SELECT  DISTINCT member ,  
        AVG(revenue) OVER (PARTITION BY member) as average_revenue
FROM CTE_revenue
```
![image](https://user-images.githubusercontent.com/101379141/199995404-8c36491d-a99a-40e1-893f-5a6bfcc252dc.png)

- The average revenue for member transactions is 516
- The average revenue for non-member transactions is 515
***

### C. Product Analysis
**1. What are the top 3 products by total revenue before discount?**

We can calculate the total revenue by product and rank the results using the Top 3.
````sql
SELECT  TOP 3 prod_id, 
        product_name,
        SUM(qty * s.price) as total_revenue
FROM    sales s
JOIN product_details p ON s.prod_id = p.product_id
GROUP BY prod_id,product_name
ORDER BY total_revenue DESC
````
![image](https://user-images.githubusercontent.com/101379141/199997527-f4f9158d-bac5-4ea1-9879-8701fd81812b.png)

**2. What is the total quantity, revenue and discount for each segment?**

````sql
SELECT segment_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY segment_name;
````

![image](https://user-images.githubusercontent.com/101379141/199997824-0aaa5df6-1823-4867-bb46-72bcfeb094f9.png)

**3.What is the top selling product for each segment?**

We can calculate the total revenue by product and rank the quantity of product by segment by using Rank() Window function In CTE and use WHERE condition to filter rank_selling = 1

````sql
WITH CTE_SEGMENT AS (   SELECT  product_name,
                                segment_name,
                                SUM(qty) as total_selling,
                                SUM(qty * s.price) as total_revenue,        
                                RANK() OVER (PARTITION BY segment_name ORDER BY SUM(QTY) DESC) AS rank_selling
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY segment_name,product_name)

SELECT  segment_name,
        product_name,
        total_selling,
        total_revenue
FROM CTE_SEGMENT
WHERE rank_selling = 1;
````

![image](https://user-images.githubusercontent.com/101379141/199998580-3ef03075-41ce-4e64-bbd9-d3fb93f3877e.png)

**4.What is the total quantity, revenue and discount for each category?**

````sql
SELECT category_name, 
        SUM(qty) AS total_quantity, 
        SUM(qty * s.price) as total_revenue,
        SUM(qty * s.price * (CAST(discount AS decimal(10,2)) / 100)) as total_discount
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY category_name;
````

![image](https://user-images.githubusercontent.com/101379141/199998844-61b6961c-f161-4942-b40f-275549fd911f.png)

**5.What is the top selling product for each category?**

We can calculate the total revenue by product and rank the quantity of product by category by using Rank() Window function In CTE and use WHERE condition to filter rank_selling = 1

````sql
WITH CTE_CATEGORY AS (  SELECT  product_name,
                                category_name,
                                SUM(qty) as total_selling,
                                SUM(qty * s.price) as total_revenue,
                                RANK() OVER (PARTITION BY category_name ORDER BY SUM(QTY) DESC) AS rank_selling
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name,product_name)

SELECT  product_name,
        category_name,
        total_selling,
        total_revenue
FROM CTE_CATEGORY
WHERE rank_selling = 1;
````

![image](https://user-images.githubusercontent.com/101379141/199999062-f2eba757-7e5b-4fe5-8c18-0b4070f587ae.png)

**6.What is the percentage split of revenue by product for each segment?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including segment, product and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_SEGMENT AS (   SELECT  segment_name,
                                product_name,
                                sum(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY segment_name,product_name)

SELECT  segment_name,
        product_name,
        ROUND (100 *  CAST (total_revenue AS FLOAT)  / SUM(total_revenue) over (partition by segment_name  ORDER BY segment_name  ),2) as percent_revenue
FROM CTE_SEGMENT
ORDER BY segment_name, percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200000677-a47c6afb-6e5c-47ac-ab86-735f3a1eb004.png)

**7.What is the percentage split of revenue by segment for each category?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including segment, category and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_CATEGORY AS (  SELECT  category_name, 
                                segment_name,
                                SUM(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name,segment_name)

SELECT  category_name,
        segment_name,
        ROUND (100 *  CAST (total_revenue AS FLOAT)  / SUM(total_revenue) over (partition by category_name  ORDER BY category_name  ),2) as percent_revenue
FROM CTE_CATEGORY
ORDER BY segment_name, percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200000777-22b17a83-1edd-4773-815f-b5072fbd705f.png)

**8.What is the percentage split of total revenue by category?**
  - In this case we make 2 Steps:
      - Firstly, we create cte including category and total revenue of each 
      - Secondly, We use window function to calculate the percent each
  
````sql
WITH CTE_CATEGORY AS (  SELECT  category_name, 
                                SUM(qty * s.price) as total_revenue
                        FROM sales s 
                        LEFT JOIN product_details  p ON s.prod_id = p.product_id
                        GROUP BY category_name)

SELECT  category_name, 
        total_revenue,
        ROUND (100 *  CAST (total_revenue as float) / sum(total_revenue) over(),2) as percent_revenue       
FROM CTE_CATEGORY
ORDER BY percent_revenue DESC ;
````

![image](https://user-images.githubusercontent.com/101379141/200001088-a21c3461-f55a-4bdc-883b-5259fa49ba58.png)

**9.What is the total transaction “penetration” for each product?**
**(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**

- In this question, Penetration is computed by total transaction of each product divided by total of transactions, so we need to compute 2 things:
    - total_transaction for each product
    - total distinct transactions

```sql
SELECT  product_name,
        COUNT(txn_id) AS total_transaction,
        ROUND (100 *  CAST (COUNT(txn_id) as float) / ( SELECT COUNT(DISTINCT txn_id) 
                                                        FROM sales)
                                                           ,2)  as penetration       
FROM sales s 
LEFT JOIN product_details  p ON s.prod_id = p.product_id
GROUP BY product_name;
```

![image](https://user-images.githubusercontent.com/101379141/200001991-9096daba-b550-471d-a029-1d3f76d8aaf8.png)

**10.What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**

This is a combinatorics question. We need to find all possible combinations of 3 different items from all the items in the list. The total number of items is 12, so we have 220 possible combinatations of 3 different items. 

The formula to count the number of combinations is:

![index](https://user-images.githubusercontent.com/98699089/154108351-75600543-8c50-4efb-bff3-bddc07b12fe1.png)

`12! / 3! * (12 - 9)! = 12! / 3! * 9! = 4 * 5 * 11 = 220`

- Firstly, CTE to list all transaction and their product
- Secondly, We use JOIN and condition to filter combination (hint: using '<' condition to remove the duplicate product name combinations)
```sql
WITH CTE AS (   SELECT  txn_id, 
                        p1.product_name
                FROM sales s 
                LEFT JOIN product_details  p1 ON s.prod_id = p1.product_id)

SELECT top 1
        C1.product_name AS PRODUCT_1,
        C2.product_name AS PRODUCT_2,
        C3.product_name AS PRODUCT_3,
        COUNT (*) AS time_trans
FROM CTE c1 
LEFT JOIN CTE C2 ON C1.txn_id =C2.txn_id  AND C1.product_name < c2.product_name
LEFT JOIN CTE C3 ON C1.txn_id = C3.txn_id AND C1.product_name < c3.product_name AND C2.product_name < c3.product_name
WHERE C1.product_name IS NOT NULL and C2.product_name IS NOT NULL AND C3.product_name IS NOT NULL
GROUP BY C1.product_name, C2.product_name,C3.product_name
ORDER BY time_trans DESC ;
```
![image](https://user-images.githubusercontent.com/101379141/200003583-4cf8b1f9-16f3-4cf4-9f03-dd469669e294.png)

***

### D. Bonus Challenge

Use a single SQL query to transform the `product_hierarchy` and `product_prices` datasets to the `product_details` table.

Hint: you may want to consider using a recursive CTE to solve this problem!

I did not use CTEs here, just consequent self joins on `parent_id` and `id` columns. The `product_name` column is generated by the `concat()` function.

```sql
SELECT  product_id,
        price,
        CONCAT(p.level_text, ' ', p1.level_text, ' - ', p2.level_text) AS product_name,
        p2.id AS category_id,
        p1.id AS segment_id,
        p.id AS style_id,
        p2.level_text AS category_name,
        p1.level_text AS segment_name,
        p.level_text AS style_name
FROM product_hierarchy AS p
JOIN product_hierarchy AS p1 on p.parent_id = p1.id
JOIN product_hierarchy AS p2 on p1.parent_id = p2.id
JOIN product_prices AS pp on p.id = pp.id
```
- In the First join - it filtered itself between parent_id and id to show the parent_id showing 2 types of category
![image](https://user-images.githubusercontent.com/101379141/200005340-e2237d0b-4640-4383-8040-9ecb059301dc.png)

- In the second join - to show the Category types and Segment types
![image](https://user-images.githubusercontent.com/101379141/200005889-93b8ab35-06c1-4d6f-b04b-af1760665328.png)

- In the final join - to filter the product_id and price and selected relevant column

![image](https://user-images.githubusercontent.com/101379141/200004368-8f284c2c-7754-48f7-8f97-c4a714b742b6.png)
