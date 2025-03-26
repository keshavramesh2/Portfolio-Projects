/*
[] Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Calculate total company acquisition cash deals made in the USA from 2011 to 2013. 
SELECT SUM(price_amount)
FROM acquisition
WHERE 
    term_code = 'cash'
    AND EXTRACT(YEAR FROM acquired_at::date) IN (2011, 2012, 2013);

-- For each country, calculate the total amount of money raised by companies registered in that country.
SELECT country_code, SUM(funding_total) as country_funding_total
FROM company
GROUP BY country_code
ORDER BY country_funding_total DESC;

-- Generate a table that has the highest and lowest amount of money raised for each date in the funding round.
SELECT MAX(raised_amount), MIN(raised_amount), funded_at::date
FROM funding_round
GROUP BY funded_at::date
HAVING MIN(raised_amount) <> 0 AND MIN(raised_amount) <> MAX(raised_amount);

-- Create a new field categorizing funds based on their investment activity.
SELECT *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >= 20 THEN 'middle_activity'
        ELSE 'low_activity'
    END AS activity_category
FROM fund;

-- For each category, calculate the average number of funding rounds the fund participated in. 
SELECT
    CASE
        WHEN invested_companies>=100 THEN 'high_activity'
        WHEN invested_companies>=20 THEN 'middle_activity'
        ELSE 'low_activity'
    END AS activity,
    ROUND(AVG(investment_rounds)) as avg_funding_rounds
FROM fund
GROUP BY activity
ORDER BY avg_funding_rounds

-- Generate a table with the ten countries that have the most active venture funds. 
SELECT
    country_code,
    MIN(invested_companies) AS min,
    MAX(invested_companies) AS max,
    AVG(invested_companies) AS avg
FROM fund
WHERE EXTRACT(YEAR FROM founded_at::date) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY avg DESC, country_code
LIMIT 10;

-- Identify the five companies whose employees have the most number of degree types.
SELECT
    company.name,
    COUNT(DISTINCT education.degree_type) AS unique_degree_types
FROM
    company
    LEFT JOIN people ON people.company_id = company.id
    LEFT JOIN education ON education.person_id = people.id
GROUP BY company.name
ORDER BY unique_degree_types DESC
LIMIT 5;

-- List all companies that closed down and had only one funding round while they existed.
SELECT name
FROM company
WHERE id IN (
    SELECT company_id
    FROM funding_round
    WHERE is_first_round = 1 AND is_last_round = 1
) AND status = 'closed'

-- List all employees who worked at the above companies.
SELECT people.id
FROM people
WHERE company_id IN (
    SELECT id
    
    FROM company
    WHERE id IN (
        SELECT company_id
        FROM funding_round
        WHERE is_first_round = 1 AND is_last_round = 1
    ) AND status = 'closed'
)

-- For the above employees, generate a table that includes unique pairs, made up of the employee ID and educational institution.
SELECT DISTINCT
    people.id,
    education.degree_type
FROM
    people JOIN education ON education.person_id = people.id
WHERE
    people.id IN (
        SELECT id
        FROM people
        WHERE company_id IN (
            SELECT id
            FROM company
            WHERE id IN (
                SELECT company_id
                FROM funding_round
                WHERE is_first_round = 1 AND is_last_round = 1
            ) AND status = 'closed'
        )
        
    )

-- Calculate the number of educational institutions for each employee above.
SELECT
    people.id,
    COUNT(education.degree_type)
FROM
    people JOIN education ON education.person_id = people.id
WHERE
    people.id IN (
        SELECT id
        FROM people
        WHERE company_id IN (
            SELECT id
            FROM company
            WHERE id IN (
                SELECT company_id
                FROM funding_round
                WHERE is_first_round = 1 AND is_last_round = 1
            ) AND status = 'closed'
        )
    )
GROUP BY people.id

-- Calculate the average number of degree types that employee of Facebook graduated with.
SELECT AVG(subq.total)
FROM (
    SELECT
        people.id,
        COUNT(education.degree_type) AS total
    FROM people JOIN education ON education.person_id = people.id
    WHERE company_id IN (
        SELECT id
        FROM company
        WHERE name = 'Facebook'
    )
    GROUP BY people.id
) AS subq

-- Create a new table for funds that invested in companies that reached more than 6 milestones and whose funding rounds took place between 2012 and 2013.
SELECT
    fund.name,
    company.name,
    funding_round.raised_amount
FROM investment
    LEFT JOIN company ON company.id = investment.company_id
    LEFT JOIN fund ON fund.id = investment.fund_id
    INNER JOIN (
        SELECT *
        FROM funding_round
        WHERE EXTRACT(YEAR FROM funding_round.funded_at) BETWEEN 2012 AND 2013
    ) AS funding_round ON funding_round.id = investment.funding_round_id
WHERE company.milestones > 6

-- Generate a table that showcases the following: buying company, transaction amount, acquired company, amount invested in the acquired, and the amount the acuisition exceeded the amount invested into the company displayed as a percentage.
SELECT
    c_2.name AS buying_company,
    a.price_amount AS transaction_amount,
    c_1.name AS acquired_company,
    c_1.funding_total AS amount_invested,
    ROUND(a.price_amount / c_1.funding_total) AS percent_exceeded
FROM
    acquisition AS a
    LEFT JOIN company AS c_1 ON c_1.id = a.acquired_company_id
    LEFT JOIN company AS c_2 ON c_2.id = a.acquiring_company_id
WHERE
    c_1.funding_total <> 0
    AND a.price_amount <> 0
ORDER BY
    a.price_amount DESC,
    acquired_company
LIMIT 10

-- Export a table of 'social' companies that raised money between 2012 and 2013.
SELECT 
    company.name AS company_name,
    EXTRACT(MONTH FROM funding_round.funded_at) AS funding_month
FROM 
    company
    JOIN funding_round ON funding_round.company_id = company.id
WHERE 
    company.category_code = 'social'
    AND EXTRACT(YEAR FROM funding_round.funded_at) BETWEEN 2010 AND 2013
    AND funding_round.raised_amount <> 0

-- Generate a new table that displays month-to-month funding round data from 2010 to 2013.
WITH month_fund AS (SELECT EXTRACT(MONTH FROM fr.funded_at) AS month,
                           COUNT(DISTINCT f.name) AS count_of_fund
                    FROM funding_round AS fr 
                    LEFT JOIN investment AS i ON i.fund_id = fr.id
                    LEFT JOIN fund AS f ON i.fund_id = f.id
                    WHERE EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2010 AND 2013 
                     AND f.country_code = 'USA'
                    GROUP BY month),
    month_acquired AS (SELECT EXTRACT(MONTH FROM acquired_at) AS month,
                              COUNT(acquired_company_id) AS count_of_acquired,
	                            SUM(price_amount) AS sum_of_acquired
                       FROM acquisition
                       WHERE EXTRACT(YEAR FROM acquired_at) BETWEEN 2010 AND 2013 
                       GROUP BY month)
SELECT month_fund.month,
       month_fund.count_of_fund,
	     month_acquired.count_of_acquired,
	     month_acquired.sum_of_acquired
FROM month_fund JOIN month_acquired ON month_fund.month = month_acquired.month;
