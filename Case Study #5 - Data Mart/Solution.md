## Solution
### A. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:
- Convert the `week_date` to a `DATE` format
- Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a `month_number` with the calendar month for each `week_date` value as the 3rd column
- Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called `age_band` after the original segment column using the following mapping on the number inside the segment value
  
<img width="166" alt="image" src="https://user-images.githubusercontent.com/81607668/131438667-3b7f3da5-cabc-436d-a352-2022841fc6a2.png">
  
- Add a new `demographic` column using the following mapping for the first letter in the `segment` values:  

| segment | demographic | 
| ------- | ----------- |
| C | Couples |
| F | Families |

- Ensure all `null` string values with an "unknown" string value in the original `segment` column as well as the new `age_band` and `demographic` columns
- Generate a new `avg_transaction` column as the sales value divided by transactions rounded to 2 decimal places for each record

**Answer:**

## Create New Table `clean_weekly_sales`

Let's construct the structure of `clean_weekly_sales` table and lay out the actions to be taken.

_`*` represent new columns_

| Columns | Actions to take |
| ------- | --------------- |
| week_date | Convert to `DATE` using `TO_DATE`
| week_number* | Extract number of week using `DATE_PART` 
| month_number* | Extract number of month using `DATE_PART` 
| calendar_year* | Extract year using `DATE_PART`
| region | No changes
| platform | No changes
| segment | No changes
| age_band* | Use `CASE WHEN` and based on `segment`, 1 = `Young Adults`, 2 = `Middle Aged`, 3/4 = `Retirees` and null = `Unknown`
| demographic* | Use `CASE WHEN` and based on `segment`, C = `Couples` and F = `Families` and null = `Unknown`
| transactions | No changes
| avg_transaction* | Divide `sales` with `transactions` and round up to 2 decimal places
| sales | No changes

**Answer:**

````sql
DROP TABLE IF EXISTS clean_weekly_sales;


SELECT CONVERT(date,week_date,3) as week_date,
        DATEPART(week,CONVERT(date,week_date,3)) as week_number, 
        DATEPART(month,CONVERT(date,week_date,3)) as month_number,
        DATEPART(year,CONVERT(date,week_date,3)) as calendar_year,
        CASE WHEN SUBSTRING(segment,2,1) = '1' THEN 'Young Adults'
            WHEN SUBSTRING(segment,2,1) = '2' THEN  'Middle Aged'
            WHEN SUBSTRING(segment,2,1) = '3' or SUBSTRING(segment,1,1) = '4' THEN 'Retirees'
            ELSE 'unknown' 
            END AS age_band ,
        CASE WHEN SUBSTRING(segment,1,1) = 'C' THEN 'Couples'
            WHEN SUBSTRING(segment,1,1) = 'F' THEN 'Families'
            ELSE 'unknown'
            END AS demographic,
        region,
        platform,
        customer_type,
        transactions,
        sales,
        cast (cast(sales as float)/transactions as decimal(10,2)) as avg_transaction 
INTO clean_weekly_sales
FROM weekly_sales;

````

![image](https://user-images.githubusercontent.com/101379141/197109159-5ddb0a4d-2829-4ef1-be4e-2ac906966b17.png)

***

### B. Data Exploration
#### 1. What day of the week is used for each week_date value?**

````sql
SELECT DISTINCT DATENAME(WEEKDAY,week_date) AS week_day
FROM clean_weekly_sales;
````
![image](https://user-images.githubusercontent.com/101379141/197109445-4a468c99-a609-4d7a-ad74-14676c240729.png)

- Monday is used for each `week_date` value.

#### 2. What range of week numbers are missing from the dataset?**

- First, generate the full range of week numbers for the entire year from 1st week to 52nd week.
- Secondly, select week include in data mart.
- Then, do a LEFT  JOIN of `numbers_week` with `WEEK_data` 

````sql
WITH numbers_week AS (
      SELECT 52 as week_number_year
      UNION all
      SELECT week_number_year - 1
      FROM numbers_week
      WHERE week_number_year > 1
     ),

WEEK_data as (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales)

SELECT COUNT(*) AS missing_weeks
FROM numbers_week w1 
LEFT JOIN WEEK_data w2 ON w1.week_number_year = w2.week_number
WHERE week_number is NULL;

````
![image](https://user-images.githubusercontent.com/101379141/197109844-466eac62-4263-4c3c-ba92-cd9c01716e31.png)

- 28 `week_number`s are missing from the dataset.

#### 3. How many total transactions were there for each year in the dataset?**

````sql
SELECT DISTINCT calendar_year, 
        SUM(transactions) AS total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year;
````
![image](https://user-images.githubusercontent.com/101379141/197109933-506ec541-7698-4a66-9728-08d25b9b13c2.png)

#### 4. What is the total sales for each region for each month?**

 - ALTER COLUMN type to Bigint 

````sql
ALTER TABLE clean_weekly_sales
ALTER COLUMN sales BIGINT 

SELECT  region,
        month_number,
        SUM (sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region,month_number
ORDER BY region,month_number

````
![image](https://user-images.githubusercontent.com/101379141/197110422-54263c7a-09c7-45b6-a6cb-d01f26c6a34e.png)

#### 5. What is the total count of transactions for each platform?**

````sql
SELECT platform,
        COUNT(transactions) as total_transaction
FROM clean_weekly_sales
GROUP BY platform
````
![image](https://user-images.githubusercontent.com/101379141/197110509-1979ca8f-d0bc-4477-b7b0-ec82b6aa2123.png)

#### 6. What is the percentage of sales for Retail vs Shopify for each month?**
````sql
SELECT DISTINCT platform,  
        calendar_year,
        month_number,
        SUM(sales) OVER (PARTITION BY month_number,calendar_year,platform order by platform  ) as sale_monthly,
        100 * CAST(SUM(sales) OVER (PARTITION BY month_number,calendar_year,platform order by platform  ) AS FLOAT)  
            /  (SUM(sales) OVER (PARTITION BY calendar_year,platform order by platform  )) AS Percent_sales_monthly
FROM clean_weekly_sales
order by platform,calendar_year,month_number;

````
_The results came up to 40 rows, so I'm only showing 20 of them. 

![image](https://user-images.githubusercontent.com/101379141/197110627-2a43c46c-e030-48ab-9c90-b1fd351af276.png)

#### 7. What is the percentage of sales by demographic for each year in the dataset?**

````sql
SELECT DISTINCT demographic,
        calendar_year,
        SUM(sales) OVER (PARTITION BY calendar_year, demographic order by demographic) AS total_sale,
        100 * CAST(SUM(sales) OVER (PARTITION BY calendar_year, demographic order by demographic) AS FLOAT)
        /  SUM(sales) OVER (PARTITION BY calendar_year) AS percent_sale
FROM clean_weekly_sales
ORDER BY demographic, calendar_year;
````
![image](https://user-images.githubusercontent.com/101379141/197110857-edbd9e6e-768a-4859-9197-dc3e9046a562.png)

#### 8. Which age_band and demographic values contribute the most to Retail sales?**

````sql
SELECT DISTINCT age_band, 
        demographic,
        SUM(sales) OVER (PARTITION BY age_band,demographic) as total_sale,
        100 * CAST(SUM(sales) OVER (PARTITION BY age_band,demographic) AS FLOAT)
        / (SELECT SUM(sales) from clean_weekly_sales) AS percent_sale
FROM clean_weekly_sales
ORDER BY percent_sale DESC;
````
![image](https://user-images.githubusercontent.com/101379141/197110942-fc65b9b7-b60b-43f5-8b0f-c3764884be22.png)


#### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?**

````sql
SELECT platform, 
        calendar_year, 
        AVG(avg_transaction) as avg_transaction_row,
        SUM(sales) / sum(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY platform, calendar_year
ORDER BY platform,calendar_year;
````
![image](https://user-images.githubusercontent.com/101379141/197111827-4380dfbf-f765-4846-bdb8-b12660888569.png)

What's the difference between `avg_transaction_row` and `avg_transaction_group`?
- `avg_transaction_row` is the average transaction in dollars by taking each row's sales divided by the row's number of transactions.
- `avg_transaction_group` is the average transaction in dollars by taking total sales divided by total number of transactions for the entire data set.

The more accurate answer to find average transaction size for each year by platform would be `avg_transaction_group`.
***

### C. Before & After Analysis

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect. We would include all `week_date` values for `2020-06-15` as the start of the period after the change and the previous week_date values would be before.

Using this analysis approach - answer the following questions:

#### 1. What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?**

Before we start, we find out the week_number of `'2020-06-15'` so that we can use it for filtering. 

````sql
SELECT  DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15';
````

![image](https://user-images.githubusercontent.com/101379141/197123478-4f7eed7d-dd62-4cb1-831c-91553aa81500.png)

The week_number is 25. Then, I created  CTEs
- SUM sales CASE-WHEN 4 weeks before and after  25th week

````sql
WITH CTE AS (
        SELECT 
                SUM (CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_change,
                SUM (CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_change
        FROM clean_weekly_sales
        WHERE calendar_year = '2020' 
                AND week_number BETWEEN 21 AND 28
                )

SELECT *, 
        (after_change - before_change ) AS sale_change,
        100 * (cast(after_change as float) - before_change) / before_change as rate_change
FROM CTE ;
````
![image](https://user-images.githubusercontent.com/101379141/197123731-ff9e0c71-f43d-48e8-a763-4b48fefef38f.png)

Since the new sustainable packaging came into effect, the sales has dropped by $26,884,188 at a negative 1.146%. 
A new packaging isn't the best idea - as customers may not recognise your product's new packaging on the shelves!

***

#### 2. What about the entire 12 weeks before and after?**

We can apply the same logic and solution to this question. 

````sql
WITH CTE AS (
        SELECT 
                SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change,
                SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change
        FROM clean_weekly_sales
        WHERE calendar_year = '2020' 
                AND week_number BETWEEN 13 AND 36
                )

SELECT *, 
        (after_change - before_change ) AS sale_change,
        100 * (cast(after_change as float) - before_change) / before_change as rate_change
FROM CTE ;
````
![image](https://user-images.githubusercontent.com/101379141/197124094-cbd2ff2a-1c2e-44db-8d6c-6581e817ec14.png)

The sales has gone down even more with a negative 2.138%! 

***

#### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?**

I'm breaking down this question to 2 parts.

##### Part 1: How do the sale metrics for 4 weeks before and after compare with the previous years in 2018 and 2019?**
- Basically, the question is asking us to find the sales variance between 4 weeks before and after `'2020-06-15'` for years 2018, 2019 and 2020. Perhaps we can find a pattern here.
- We can apply the same solution as above and add `calendar_year` into the syntax. 

````sql
WITH CTE_4w AS (SELECT calendar_year,
                      SUM (CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_change_4_week,
                      SUM (CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_change_4_week,
                      SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change_12_week,
                      SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change_12_week
                FROM clean_weekly_sales
                GROUP BY calendar_year)

SELECT calendar_year,
        before_change_4_week,
        after_change_4_week,
        (after_change_4_week - before_change_4_week ) AS sale_change_4w,
        round(100 * (cast(after_change_4_week as float) - before_change_4_week) / before_change_4_week,2) as rate_change_4w
FROM CTE_4w
order by calendar_year;
````

![image](https://user-images.githubusercontent.com/101379141/197124302-70c7617c-77b1-41d8-ab63-7c0719ebeb00.png)


We can see that in 2018 and 2019, there's a sort of consistent increase in sales in week 25 to 28 is 0.19 and 0.1 respectively 

However, after the new packaging was implemented in 2020's week 25, there was a significant drop in sales at 1.15% and compared to the previous years.

##### Part 2: How do the sale metrics for 12 weeks before and after compare with the previous years in 2018 and 2019?**
- Use the same solution above and change to week 13 to 24 for before and week 25 to 36 for after.

````sql
WITH CTE_12w AS (SELECT calendar_year,
                        SUM (CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_change_12_week,
                        SUM (CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_change_12_week
                FROM clean_weekly_sales
                GROUP BY calendar_year)

SELECT calendar_year,
        before_change_12_week,
        after_change_12_week,
        (after_change_12_week - before_change_12_week ) AS sale_change_12w,
        round(100 * (cast(after_change_12_week as float) - before_change_12_week) / before_change_12_week,2) as rate_change_12w
FROM CTE_12w
order by calendar_year;
````
![image](https://user-images.githubusercontent.com/101379141/197124647-37406e33-f161-4c7f-a9a4-3bc2ec8d6bc6.png)



***


