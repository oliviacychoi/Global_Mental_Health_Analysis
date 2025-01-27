/*
World Mental Health (2002-2021) Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views

*/
-- PART 1 
-- Create and merge 4 files gathered from IHME, Check for duplicates
-- File 1
CREATE TABLE p1(
	measure_id INT,
	location_id INT,
	gender_id INT,
	age_id INT,
	cause_id INT,
	metric_id INT,
	year YEAR,
	val DOUBLE,
	upper DOUBLE,
	lower DOUBLE
    );
-- * imported file 1 using import wizard *
-- Check if all rows are imported from file 1
SELECT COUNT(*)
FROM p1; -- 500,000 rows

-- File 2 CTE
CREATE TABLE p2(
	measure_id INT,
	location_id INT,
	gender_id INT,
	age_id INT,
	cause_id INT,
	metric_id INT,
	year YEAR,
	val DOUBLE,
	upper DOUBLE,
	lower DOUBLE
    );
-- * imported file 2 using import wizard *
-- Check if all rows are imported from file 2
SELECT COUNT(*)
FROM p2; -- 500,000 rows

-- File 3
CREATE TABLE p3(
	measure_id INT,
	location_id INT,
	gender_id INT,
	age_id INT,
	cause_id INT,
	metric_id INT,
	year YEAR,
	val DOUBLE,
	upper DOUBLE,
	lower DOUBLE
    );
-- * imported file 3 using import wizard *
-- Check if all rows are imported from file 3
SELECT COUNT(*)
FROM p3; -- 500,000 rows

-- File 4
CREATE TABLE p4(
	measure_id INT,
	location_id INT,
	gender_id INT,
	age_id INT,
	cause_id INT,
	metric_id INT,
	year YEAR,
	val DOUBLE,
	upper DOUBLE,
	lower DOUBLE
    );
-- * imported file 4 using import wizard *
-- Check if all rows are imported from file 4
SELECT COUNT(*)
FROM p4; -- 132,000 rows


-- Create table to merge all 4 tables
CREATE TABLE prevalenceworld
SELECT * FROM p1
	UNION ALL
SELECT * FROM p2
	UNION ALL
SELECT * FROM p3
	UNION ALL
SELECT * FROM p4;

SELECT COUNT(*)
FROM prevalenceworld; -- 1,632,000 rows 


SELECT * FROM prevalenceworld;


-- Check if there are duplicated values in the merged table
SELECT location_id, gender_id, age_id, cause_id, year, COUNT(*)
FROM prevalenceworld
GROUP BY location_id, gender_id, age_id, cause_id, year
HAVING COUNT(*) > 1; 


-- Create Temp Table all data related to Canada
DROP TEMPORARY TABLE IF EXISTS prevalenceca;
CREATE TEMPORARY TABLE prevalenceca(	
    location_id INT,
    location VARCHAR(255),
    gender_id INT,
    gender VARCHAR(10),
    age_id INT,
    age_group VARCHAR(255),
    cause_id INT,
    cause VARCHAR(255),
    year YEAR,
    num DOUBLE,
    pop DOUBLE
);
INSERT INTO prevalenceca
SELECT p.location_id,
	l.location_name,
	p.gender_id,
    g.gender_name,
    p.age_id,
    a.age_name,
    p.cause_id,
    c.cause_name,
    p.year,
    p.val,
    pop.val
FROM prevalenceworld p
LEFT JOIN location l
	ON p.location_id = l.location_id
LEFT JOIN gender g
	ON p.gender_id = g.gender_id
LEFT JOIN age a
	ON p.age_id = a.age_id
LEFT JOIN cause c
	ON p.cause_id = c.cause_id
LEFT JOIN population pop
	ON p.location_id = pop.location_id 
   AND p.gender_id = pop.gender_id
   AND p.age_id = pop.age_id
   AND p.year = pop.year
WHERE p.location_id = 101
ORDER BY p.year, p.cause_id, p.age_id, p.gender_id;
    
SELECT *
FROM prevalenceca;



-- PART 2
-- 2.1
-- Rank the prevalence rate for mental health disorder each year using CTE
WITH p_world AS(
	SELECT p.year AS year,
		c.cause_name AS cause,
        SUM(p.val) AS num,
        SUM(pop.val) AS population,
		SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
	FROM prevalenceworld p
	LEFT JOIN cause c 
		ON p.cause_id = c.cause_id
	LEFT JOIN population pop
	ON p.location_id = pop.location_id 
		AND p.gender_id = pop.gender_id
		AND p.age_id = pop.age_id
		AND p.year = pop.year
	GROUP BY p.year, c.cause_name
)
SELECT year, 
	cause, 
    num,
    population,
    `prevalence rate`,
	RANK() OVER(PARTITION BY year ORDER BY `prevalence rate` DESC) AS `rank`
FROM p_world;


-- Create View for data visualization
DROP VIEW IF EXISTS ranked_cause;
CREATE VIEW ranked_cause AS
	SELECT year, 
	cause, 
    num,
    population,
    `prevalence rate`,
	RANK() OVER(PARTITION BY year ORDER BY `prevalence rate` DESC) AS `rank`
FROM (
    SELECT p.year AS year,
		c.cause_name AS cause,
        SUM(p.val) AS num,
        SUM(pop.val) AS population,
		SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
	FROM prevalenceworld p
	LEFT JOIN cause c 
		ON p.cause_id = c.cause_id
	LEFT JOIN population pop
		ON p.location_id = pop.location_id 
		AND p.gender_id = pop.gender_id
		AND p.age_id = pop.age_id
		AND p.year = pop.year
	GROUP BY p.year, c.cause_name
	) AS p_world;



-- 2.2 
-- Prevalence rate of mental health disorder(group by gender) w/ ranking using CTE
WITH p_gender AS(
	SELECT 
		p.year AS year,
        c.cause_name AS cause, 
		g.gender_name AS gender, 
		SUM(p.val) AS num,
        SUM(pop.val) AS population,
        SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
	FROM prevalenceworld p
	LEFT JOIN cause c 
		ON p.cause_id = c.cause_id
	LEFT JOIN gender g
		ON p.gender_id = g.gender_id
	LEFT JOIN population pop
		ON p.location_id = pop.location_id 
		AND p.gender_id = pop.gender_id
		AND p.age_id = pop.age_id
		AND p.year = pop.year
	GROUP BY p.year, c.cause_name, g.gender_name
)
SELECT 
	year,
    cause, 
	gender, 
    num,
    population,
    `prevalence rate`,
    RANK() OVER(PARTITION BY year,gender ORDER BY `prevalence rate` DESC) AS rank_num
FROM p_gender;


-- Create View for data visualization
CREATE VIEW ranked_gender AS
	SELECT 
		year,
		cause, 
		gender, 
		num,
		population,
		`prevalence rate`,
		RANK() OVER(PARTITION BY year,gender ORDER BY `prevalence rate` DESC) AS rank_num
	FROM (
		SELECT 
			p.year AS year,
			c.cause_name AS cause, 
			g.gender_name AS gender, 
			SUM(p.val) AS num,
			SUM(pop.val) AS population,
			SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
		FROM prevalenceworld p
		LEFT JOIN cause c 
			ON p.cause_id = c.cause_id
		LEFT JOIN gender g
			ON p.gender_id = g.gender_id
		LEFT JOIN population pop
			ON p.location_id = pop.location_id 
			AND p.gender_id = pop.gender_id
			AND p.age_id = pop.age_id
			AND p.year = pop.year
		GROUP BY p.year, c.cause_name, g.gender_name
	) AS p_gender;
    


-- 2.3
-- Prevalence rate in each age group rank from highest to lowest using CTE
WITH p_age AS(
	SELECT 
		p.year AS year,
        c.cause_name AS cause, 
		a.age_name AS age, 
		SUM(p.val) AS num,
        SUM(pop.val) AS population,
        SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
	FROM prevalenceworld p
	LEFT JOIN cause c 
		ON p.cause_id = c.cause_id
	LEFT JOIN age a
		ON p.age_id = a.age_id
	LEFT JOIN population pop
		ON p.location_id = pop.location_id 
		AND p.gender_id = pop.gender_id
		AND p.age_id = pop.age_id
		AND p.year = pop.year
	GROUP BY p.year, c.cause_name, a.age_name
)
SELECT 
	year,
    cause, 
	age, 
    num,
    population,
    `prevalence rate`,
    RANK() OVER(PARTITION BY year,age ORDER BY `prevalence rate` DESC) AS rank_num
FROM p_age;


-- Create View for data visualization
CREATE VIEW ranked_age AS
	SELECT 
		year,
		cause, 
		age, 
		num,
		population,
		`prevalence rate`,
		RANK() OVER(PARTITION BY year,age ORDER BY `prevalence rate` DESC) AS rank_num
	FROM (	
		SELECT 
			p.year AS year,
			c.cause_name AS cause, 
			a.age_name AS age, 
			SUM(p.val) AS num,
			SUM(pop.val) AS population,
			SUM(p.val)/SUM(pop.val)*100000 AS `prevalence rate`
		FROM prevalenceworld p
		LEFT JOIN cause c 
			ON p.cause_id = c.cause_id
		LEFT JOIN age a
			ON p.age_id = a.age_id
		LEFT JOIN population pop
			ON p.location_id = pop.location_id 
			AND p.gender_id = pop.gender_id
			AND p.age_id = pop.age_id
			AND p.year = pop.year
		GROUP BY p.year, c.cause_name, a.age_name) AS p_age;



-- 2.4a
-- Overview of World Mental Health Disorder Prevalence by country and year
SELECT 
	p.year AS year,
	l.location_name AS country, 
	SUM(p.val) AS num,
	SUM(pop.val)/COUNT(DISTINCT p.cause_id) AS population,
	SUM(p.val)/(SUM(pop.val)/COUNT(DISTINCT p.cause_id)) * 100000 AS `prevalence rate`
FROM prevalenceworld p
LEFT JOIN location l
	ON p.location_id = l.location_id
LEFT JOIN population pop
	ON p.location_id = pop.location_id 
	AND p.gender_id = pop.gender_id
	AND p.age_id = pop.age_id
	AND p.year = pop.year
GROUP BY p.year, l.location_name
ORDER BY p.year, l.location_name;


-- 2.4b
-- Show prevalence rate of mental health disorders by country from 2002-2021
WITH p_country AS(
	SELECT 
		p.year AS year,
        c.cause_name AS cause, 
		l.location_name AS country, 
		SUM(p.val) AS num,
        SUM(pop.val)/COUNT(DISTINCT p.cause_id) AS population,
        SUM(p.val)/(SUM(pop.val)/COUNT(DISTINCT p.cause_id)) *100000 AS `prevalence rate`
	FROM prevalenceworld p
	LEFT JOIN cause c 
		ON p.cause_id = c.cause_id
	LEFT JOIN location l
		ON p.location_id = l.location_id
	LEFT JOIN population pop
		ON p.location_id = pop.location_id 
		AND p.gender_id = pop.gender_id
		AND p.age_id = pop.age_id
		AND p.year = pop.year
	GROUP BY p.year, c.cause_name, l.location_name
    )
SELECT 
	year,
    cause, 
	country, 
    num,
    population,
    `prevalence rate`,
    SUM(num) OVER(PARTITION BY year,country ORDER BY `prevalence rate` DESC) / population * 100000 AS accu_rate,
    RANK() OVER(PARTITION BY year,country ORDER BY `prevalence rate` DESC) AS rank_num
FROM p_country;


-- Create View for data visualization
CREATE VIEW ranked_country AS
	SELECT 
		year,
		cause, 
		country, 
		num,
		population,
		`prevalence rate`,
		SUM(num) OVER(PARTITION BY year,country ORDER BY `prevalence rate` DESC) / population * 100000 AS accu_rate,
		RANK() OVER(PARTITION BY year,country ORDER BY `prevalence rate` DESC) AS rank_num
	FROM (	
		SELECT 
			p.year AS year,
			c.cause_name AS cause, 
			l.location_name AS country, 
			SUM(p.val) AS num,
			SUM(pop.val)/COUNT(DISTINCT p.cause_id) AS population,
			SUM(p.val)/(SUM(pop.val)/COUNT(DISTINCT p.cause_id)) *100000 AS `prevalence rate`
		FROM prevalenceworld p
		LEFT JOIN cause c 
			ON p.cause_id = c.cause_id
		LEFT JOIN location l
			ON p.location_id = l.location_id
		LEFT JOIN population pop
			ON p.location_id = pop.location_id 
			AND p.gender_id = pop.gender_id
			AND p.age_id = pop.age_id
			AND p.year = pop.year
		GROUP BY p.year, c.cause_name, l.location_name
        ) AS p_country;





    
