CREATE SCHEMA country_data;

USE country_data;

CREATE TABLE cities (
city_name VARCHAR(20),
country_code VARCHAR(3),
city_proper_pop INT,
metro_area_pop INT,
urban_area_pop INT
);

CREATE TABLE countries (
country_code VARCHAR(3),
country_name VARCHAR(30),
continent VARCHAR(30),
region VARCHAR(30),
surface_area INT,
independence_year INT,
local_name VARCHAR(50),
government_type VARCHAR(50),
capital_city VARCHAR(30),
capital_longitude FLOAT,
capital_latitude FLOAT
);

CREATE TABLE economies
(
	econ_id INT PRIMARY KEY,
    country_code VARCHAR(3),
    eco_year INT,
    income_group VARCHAR(30),
    gdp_percapita FLOAT,
    gross_savings FLOAT,
    inflation_rate FLOAT,
    total_investment FLOAT,
    unemployment_rate FLOAT,
    exports FLOAT,
    imports FLOAT
);

CREATE TABLE populations(
population_id INT PRIMARY KEY,
country_code VARCHAR(30),
population_year INT,
fertility_rate FLOAT,
life_expectancy FLOAT,
size INT
);

SELECT * FROM cities;
SELECT * FROM countries;
SELECT * FROM economies;
SELECT * FROM populations;

SELECT cities.city_name AS City, countries.country_name AS Country, countries.region
FROM cities
INNER JOIN countries
ON cities.country_code = countries.country_code;

SELECT cities.city_name AS City, countries.country_name AS Country,
countries.continent AS Continent, cities.city_proper_pop AS City_Population
FROM cities
INNER JOIN countries
ON cities.country_code = countries.country_code
WHERE cities.city_proper_pop > 10000000;


SELECT economies.gdp_percapita, countries.country_name, economies.eco_year
FROM countries
INNER JOIN economies
USING(country_code)
WHERE economies.eco_year = 2015
ORDER BY economies.gdp_percapita DESC;



SELECT c.country_code, p.population_year, p.fertility_rate, e.eco_year, e.unemployment_rate
FROM countries AS c
INNER JOIN populations AS p
USING(country_code)
INNER JOIN economies as e
USING(country_code);

SELECT c.region, AVG(e.gdp_percapita)
FROM countries AS c
LEFT JOIN economies as e
USING(country_code)
WHERE e.eco_year = 2010
GROUP BY c.region;