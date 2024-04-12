CREATE SCHEMA retail_mart;

USE retail_mart;

CREATE TABLE customer_table(
customer_id INT,
customer_name VARCHAR(30),
customer_location VARCHAR(30),
phone_number INT
);

CREATE TABLE product_table(
product_id INT,
product_name VARCHAR(50),
price FLOAT,
stock INT,
category VARCHAR(50)
);

CREATE TABLE sales_table(
order_number VARCHAR(30),
customer_id INT,
customer_name VARCHAR(30),
product_code INT,
product_name VARCHAR(30),
quantity INT,
price FLOAT
);

SELECT * FROM customer_table;
SELECT * FROM product_table;
SELECT * FROM sales_table;

DESC sales_table;

INSERT INTO product_table
VALUES (27, "panel", 313, 6, "perfume");

SELECT * FROM product_table;

ALTER TABLE sales_table
ADD COLUMN S_no INT;

ALTER TABLE sales_table
ADD COLUMN categories VARCHAR(30);

SELECT * FROM sales_table;

ALTER TABLE product_table
MODIFY COLUMN stock VARCHAR(30);

SELECT * FROM product_table;
DESC product_table;

ALTER TABLE customer_table
RENAME TO customer_details;

ALTER TABLE sales_table
DROP COLUMN S_no, DROP COLUMN categories;

SELECT * FROM sales_table;

# Write a query to display the product name and price from sales_table
SELECT product_name, price 
FROM sales_table;

SELECT COUNT(order_number) FROM sales_table;

# Write a query to display all details in table if the category is "stationary"
SELECT * FROM product_table
WHERE category = "stationary";

# SELECT column, count column
# FROM product_table
# GROUP BY column
# Find the amount of products per category

SELECT category, COUNT(category)
FROM product_table
GROUP BY category;

SELECT category, COUNT(product_id)
FROM product_table
GROUP BY category;

# Display sales details where quantity is greater than 2 
# and price is less than 500

SELECT *
FROM sales_table
WHERE quantity > 2
AND price < 500;

SELECT * FROM product_table;

# Write a select statement that finds the categories whose 2nd letter is a vowel
# Vowel = a, e, i, o, u

# a _ = can be any letter in this position
# a % = can be any number of any letters after this
# a [] = list of characters it could be

SELECT * FROM product_table
WHERE category LIKE '_a%'
OR category LIKE '_e%'
OR category LIKE '_i%'
OR category LIKE '_o%'
OR category LIKE '_u%';

SELECT * FROM product_table;

SELECT * FROM product_table
ORDER BY price DESC;

# How many rows in the sales table?
SELECT COUNT(order_number) FROM sales_table;