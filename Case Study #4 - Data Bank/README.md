# Case Study #4: Data Bank
<img src="https://user-images.githubusercontent.com/81607668/130343294-a8dcceb7-b6c3-4006-8ad2-fab2f6905258.png" alt="Image" width="500" height="520">

## Introduction
Danny launched a new initiative, Data Bank which runs **banking activities** and also acts as the world’s most secure distributed **data storage platform**!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. 

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Data
### Relationship diagram
![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/32e27039-68da-47da-9006-abb738f0f504)

### Source data
[Click here](https://8weeksqlchallenge.com/case-study-4/)

#### Table 1: Regions
This regions table contains the region_id and their respective region_name values.

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/0cd95f52-bdd8-4d31-a30f-5c80935367f5)

#### Table 2: Customer
This table just show the unique customer's id 

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/9f53b9b7-ef81-421e-b777-8c0c47b6efc0)

#### Table 3 : Customer Nodes
Customers are randomly distributed across the nodes according to their region. This random distribution changes frequently to reduce the risk of hackers getting into Data Bank’s system and stealing customer’s money and data!

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/0ea5df7f-f19c-4930-a35c-c2ba06cf9cb1)

#### Table 4 : Customer Transactions
This table stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/c5a8f89b-eb70-4a15-9503-a788a39aeee1)

##  Task Questions

### A. Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

### B. Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?
 
## Solution
[Click here](https://github.com/DooPhiLong/8-Week-SQL-Challenge/blob/main/Case%20Study%20%234%20-%20Data%20Bank/Solution.md)
## Method applied
- Creating Tables
- JOINS
- CTE's
- Window Functions Such as LEAD() LAG() and RANK()  SLIDING WINDOWS
- CASE Statements
- As well as other functions, operators and clauses, especially PERCENTILE_DISC() 
