/*
This is a sample from my invoice analysis project
*/

-- Identify in which summer the store's total revenue was the highest. Export a table with the following fields: country, total_invoice, total_customer. Order the table by total_invoice in descending order and then by country in lexicographical order.
SELECT i.country,
       total_invoice,
       total_customer
FROM
  (SELECT billing_country AS country,
          COUNT(invoice_id) AS total_invoice
   FROM invoice
   WHERE EXTRACT(YEAR FROM CAST(invoice_date AS date)) =
       (SELECT EXTRACT(YEAR FROM CAST(invoice_date AS date)) AS YEAR
        FROM invoice
        WHERE EXTRACT(MONTH FROM CAST(invoice_date AS date)) IN (6, 7, 8)
        GROUP BY YEAR
        ORDER BY SUM(total) DESC
        LIMIT 1)
   GROUP BY country) AS i
JOIN
  (SELECT country,
          COUNT(customer_id) AS total_customer
   FROM client
   GROUP BY country) AS c ON c.country = i.country
ORDER BY total_invoice DESC, i.country;

-- Select the last names of users who placed at least one order in Jan 2013 and also placed at least one more order during any month after Jan throughout 2013.
SELECT DISTINCT client_lastname.last_name
FROM
    (
        SELECT customer_id
        FROM invoice
        WHERE DATE_TRUNC('month', invoice_date::date) BETWEEN '2013-01-01' AND '2013-01-31'
    ) AS jan2013_customers 
    INNER JOIN (
        SELECT customer_id
        FROM invoice
        WHERE DATE_TRUNC('month', invoice_date::date) BETWEEN '2013-02-01' AND '2013-12-31'
    ) AS rest2013_customers ON rest2013_customers.customer_id = jan2013_customers.customer_id
    INNER JOIN (
        SELECT customer_id, last_name
        FROM client
    ) AS client_lastname ON client_lastname.customer_id = jan2013_customers.customer_id;

-- Count the orders placed from 2011 to 2013. Display the invoice month, year 2011, year 2012, and year 2013
WITH invoice_2011 AS (
    SELECT
        EXTRACT(MONTH FROM invoice_date::date) AS invoice_month,
        COUNT(DISTINCT invoice_id) AS year_2011
    FROM invoice
    WHERE EXTRACT(YEAR FROM invoice_date::date) = 2011
    GROUP BY invoice_month
),
invoice_2012 AS (
    SELECT
        EXTRACT(MONTH FROM invoice_date::date) AS invoice_month,
        COUNT(DISTINCT invoice_id) AS year_2012
    FROM invoice
    WHERE EXTRACT(YEAR FROM invoice_date::date) = 2012
    GROUP BY invoice_month   
),
invoice_2013 AS (
    SELECT
        EXTRACT(MONTH FROM invoice_date::date) AS invoice_month,
        COUNT(DISTINCT invoice_id) AS year_2013
    FROM invoice
    WHERE EXTRACT(YEAR FROM invoice_date::date) = 2013
    GROUP BY invoice_month   
)
SELECT 
    invoice_2011.invoice_month, 
    invoice_2011.year_2011, 
    invoice_2012.year_2012,
    invoice_2013.year_2013
FROM 
    invoice_2011 
    FULL JOIN invoice_2012 ON invoice_2012.invoice_month = invoice_2011.invoice_month
    FULL JOIN invoice_2013 ON invoice_2013.invoice_month = invoice_2011.invoice_month
