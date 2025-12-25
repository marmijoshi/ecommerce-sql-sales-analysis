# Database created to store e-commerce sales and customer data
CREATE DATABASE ecommerce_sql_project;
USE ecommerce_sql_project;

# ----------------------------------------------------------------------------------------------

# TABLE CREATION
# Concepts used: Primary Key, NOT NULL, UNIQUE
CREATE TABLE customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
	customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    city VARCHAR(50),
    signup_date DATE
);

# Concepts used: Data Types, Primary Key
CREATE TABLE products (
	product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2) NOT NULL
);

# Which customer ordered when
CREATE TABLE orders (
	order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

# Bridge neyween Orders and Products (many-to-many)
CREATE TABLE order_details (
	order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

# -------------------------------------------------------------------------------------------
# INSERTING RAW DATA
# Customers Data
INSERT INTO customers (customer_name, email, city, signup_date) VALUES
('Amit Sharma', 'amit@gmail.com', 'Delhi', '2024-01-10'),
('Neha Verma', 'neha@gmail.com', 'Mumbai', '2024-01-15'),
('Rahul Mehta', 'rahul@gmail.com', 'Bangalore', '2024-02-01'),
('Priya Singh', 'priya@gmail.com', 'Pune', '2024-02-10'),
('Ankit Jain', 'ankit@gmail.com', 'Jaipur', '2024-03-05');

# Products Data
INSERT INTO products (product_name, category, price) VALUES
('Wireless Mouse', 'Electronics', 799.00),
('Laptop Stand', 'Electronics', 1299.00),
('Bluetooth Headphones', 'Electronics', 2499.00),
('Notebook', 'Stationery', 199.00),
('Water Bottle', 'Accessories', 499.00);

# Orders Data
INSERT INTO orders (customer_id, order_date, order_status) VALUES
(1, '2024-03-10', 'Completed'),
(2, '2024-03-12', 'Completed'),
(1, '2024-03-20', 'Completed'),
(3, '2024-03-22', 'Cancelled'),
(4, '2024-03-25', 'Completed');

# Order Details Data
INSERT INTO order_details (order_id, product_id, quantity) VALUES
(1, 1, 2),
(1, 4, 3),
(2, 2, 1),
(2, 5, 2),
(3, 3, 1),
(3, 1, 1),
(4, 4, 2),
(5, 5, 1);

# -------------------------------------------------------------------------------------------
# QUERIES
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_details;

# --------------------------------------------------------------------------------------------
# JOIN: Order & Customer Names
SELECT
	o.order_id,
    c.customer_name,
    o.order_date,
    o.order_status
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id;

# JOIN: Order Details with Product Names
SELECT
	od.order_id,
    p.product_name,
    od.quantity
FROM order_details od
JOIN products p
ON od.product_id = p.product_id;

# Complete Order Summary: Multiple JOINs + Calculated column + Real billing logic
/*
Used multi-table joins to generate complete order summaries including customer details, 
product information, and total price calculation.
*/ 
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    od.quantity,
    p.price,
    (od.quantity * p.price) AS total_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE o.order_status = 'Completed';

# -------------------------------------------------------------------------------------------
# BUSINESS ANALYSIS QUERIES

# 1. MONTHLY REVENUE TREND : Analyzed monthly revenue trends using aggregate functions and GROUP BY.
SELECT
	MONTH(o.order_date) AS month,
    SUM(p.price * od.quantity) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY MONTH(o.order_date)
ORDER BY month;

# Top 5 Best Selling Products: Identified top-selling products based on total quantity sold.
SELECT
	p.product_name,
    SUM(od.quantity) AS total_quantity_sold
FROM order_details od
JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

# Repeated Customers: Used HAVING clause to identify repeated customers based on order frequency.
SELECT
	c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 1;

# AVERAGE ORDER VALUE: Calculated average order value using subqueries and aggregation.
SELECT
	AVG(order_total) AS average_order_value
FROM
	(SELECT
		o.order_id,
        SUM(p.price * od.quantity) AS order_total
	FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id
) t;

# Advance
# Order summary as a view: Created SQL views to simplify complex queries and improve readability.
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    c.customer_name,
    o.order_date,
    p.product_name,
    od.quantity,
    p.price,
    (od.quantity * p.price) AS total_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE o.order_status = 'Completed';

# USED AS:
SELECT * FROM order_summary;

# Implemented indexes to improve query performance on frequently filtered columns.
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_customer_id ON orders(customer_id);

# REVENUE BY CATEGORY
SELECT 
    p.category,
    SUM(od.quantity * p.price) AS category_revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN orders o ON od.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.category;

# CUSTOMER WISE TOTAL SPEND
SELECT 
    c.customer_name,
    SUM(od.quantity * p.price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_name
ORDER BY total_spent DESC;
