CREATE SCHEMA world_happiness;

USE world_happiness;

#For the sake of each question - unless specifically referring to every year - I have opted to
#use only the 2019 Happiness Index. However, the Table CountryStats is developed with 
#data from all years for both brevity and to simplify Q14 later.

#Please note that different csv files have missing countries and differing 
#list of countries. Some of them are missing the region field alltogether.
#I DID NOT ADD REGIONS TO COUNTRIES THAT HAVE NO EXPLICIT MENTION IN 
#THE HAPPINESS INDEXES BETWEEN 2015 AND 2017. There are NULL regions associated with
# WITH 26 DIFFERENT COUNTRIES. This may cause some skew to calculated aggregate functions.

#Pre-requisite: Adding primary key identifiers to happy_rank for all happiness_index csv.

#Question 1: Create a new table CountryStats. 
CREATE TABLE CountryStats (
countryID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
#CountryID exists only as a contingency (e.g. country could change names).
country_name VARCHAR(30),
region VARCHAR(30),
#2019 contains the complete list of countries, without missing a single value. 
happy_rank_2019 INT,
happy_rank_2015 INT,
happy_rank_2016 INT,
happy_rank_2017 INT,
happy_rank_2018 INT
);

#Question 2
INSERT INTO CountryStats (
country_name, region, happy_rank_2019, happy_rank_2015, happy_rank_2016, happy_rank_2017, happy_rank_2018
)
#Left join is used to make sure every entry in the 2019 index is placed inside CountryStats.
SELECT a.country_name, b.region, a.happy_rank, b.happy_rank, c.happy_rank, d.happy_rank, e.happy_rank
FROM happiness_2019 AS a
LEFT JOIN happiness_2015 AS b USING (country_name)
LEFT JOIN happiness_2016 AS c USING (country_name)
LEFT JOIN happiness_2017 AS d USING (country_name)
LEFT JOIN happiness_2018 AS e USING (country_name);

#Check
SELECT * FROM countrystats
ORDER BY happy_rank_2019;

#Question 3
#Defined top 10 using the LIMIT command - CREATE VIEW ... AS for making a VIEW.
CREATE VIEW TopHappiness AS 
	SELECT countryID, country_name, happy_rank_2019
    FROM CountryStats
    ORDER BY happy_rank_2019 #For ranking based on Top Happiness on year 2019.
    LIMIT 10; #Allows just 10 results.

#Check
SELECT * FROM TopHappiness;

#Question 4
SELECT a.country_name, a.region, b.happy_rank as happy_rank_2019
FROM CountryStats AS a
JOIN happiness_2019 AS b #JOIN = INNER JOIN... but anyways, doesn't really matter what JOIN we use,
						 # as we already populated CountryStats with every country within 2019 csv file.
ON a.country_name = b.country_name
WHERE b.happy_score > 7;

#Question 5:
#Alter and add column to table.
ALTER TABLE CountryStats
ADD COLUMN EconomyScore FLOAT;

#Change NULL values to economy scores (the subquery only returns values where the country_name exists in both tables), 
#i.e. no new data entries
UPDATE CountryStats
SET EconomyScore = (SELECT economy FROM happiness_2019 WHERE CountryStats.country_name = happiness_2019.country_name);

#Check
SELECT * FROM CountryStats;

#Question 6: Creating index of happy_rank_N on CountryStats table
CREATE INDEX happy_index
ON CountryStats (happy_rank_2015, happy_rank_2016, happy_rank_2017, happy_rank_2018, happy_rank_2019);

# No need to explicitly specify - uses index automatically to enhance searching speeds 
#by saving the locations of each record.

#Question 7: The 2019 csv does not seperate into regions. 
# Regions for each country was extracted earlier via 2015-2017 region table when inserting data
# in Question 2.
#Using the windows function RANK(), which ranks rows in the set based on a field.
SELECT country_name, region, happy_rank,
RANK() OVER(PARTITION BY region ORDER BY happy_score DESC) AS Regional_Rank #PARTITION BY can be thought of simply as the analogue
#OVER() defines the set of which to use the window function					#to GROUP BY, but for window functions instead of aggregate.
FROM CountryStats AS a		
JOIN happiness_2019 AS b #Simple INNER JOIN works fine - needed so we can access the region field.
USING(country_name);

#Question 8: Include condition to average
SELECT a.region, AVG(b.happy_score) AS excl_low_generosity
FROM CountryStats AS a
JOIN happiness_2019 AS b USING (Country_name)
#Extra Join - this one Joins a table created by a subquery that takes 
# the grouped average generosity of each region. This allows a 
# relationship to be made between the regional average generosity and a specific
# country's generosity score based on the region field in CountryStats.
JOIN (
	SELECT region, AVG(generosity) AS avg_generosity 
	FROM CountryStats 
    JOIN happiness_2019 USING (country_name) GROUP BY region) #Nested JOIN to access both generosity from Index, and region from CountryStats.as
															   #Technically, if the 2019 csv had a region field, this would not be so complicated!
AS regional_avg USING(region) # This JOIN forms a relationship via CountryStats.region and regional_avg.region. 
							  # Thus, we can now compare the generosity score in Happiness Index with the average regional generosity calculated
                              # in the JOIN subquery, and group by region difference.
WHERE b.generosity > regional_avg.avg_generosity #Check if country's generosity is atleast higher than regional average.
GROUP BY a.Region;

#Question 8_extended: A purposefully WRONG implementation to show difference.
SELECT a.region, AVG(b.happy_score) AS excl_low_generosity, AVG(b.generosity) AS avg_generosity
FROM CountryStats AS a
JOIN happiness_2019 AS b USING (Country_name)
GROUP BY a.Region
HAVING AVG(b.generosity) > (SELECT AVG(generosity) FROM happiness_2019);
#This method DOES NOT exclude any low generosity countries, rather this method
# retuns regions with higher average generosity than the generosity of every region combined.
# This is because in order to make a comparative check of generosity between a country and it's regional average, you cannot do both at the same time.
# You must first declare the regional average in an executed subquery... this is the reason we join this in the earlier example.

#Question 8_extended_2: Using Window function instead to achieve the same result?
#This version is preferred as less JOIN functions, and less lines make this code more readable. 
#It also (atleast for a larger database) is probably more efficient.
SELECT a.region, AVG(b.happy_score) AS excl_low_generosity
FROM CountryStats AS a
JOIN ( #Here, I used PARTITION BY to remove the need for the extra JOIN in the first version of Q8. This does practically the same thing.
    SELECT *, AVG(generosity) OVER (PARTITION BY region) AS avg_generosity_per_region   
    FROM CountryStats
    JOIN happiness_2019 USING (country_name)
) AS b
USING(country_name)
WHERE b.generosity > b.avg_generosity_per_region
GROUP BY a.Region;

#To show what the partition function did:
SELECT *, AVG(generosity) OVER (PARTITION BY region) AS avg_generosity_per_region 
FROM CountryStats
JOIN happiness_2019 USING (country_name);


#Question 9: #Same main principle as in Q8. This time, we return both the trust of the country, alongside it's regional average trust.
SELECT a.country_name, b.trust, a.region, avg_trust_per_region.avgTrust 
FROM CountryStats AS a
JOIN happiness_2019 AS b #Same JOIN reasoning as all the times before - access to region.
USING (country_name)
JOIN (
	SELECT region, AVG(trust) AS avgTrust 
	FROM happiness_2019 
    JOIN CountryStats USING(country_name) GROUP BY region) #Same JOIN that allows me to access regional average to use for each country.
AS avg_trust_per_region
USING (region)
WHERE b.trust > avg_trust_per_region.avgTrust
ORDER BY a.region;

#Question 10: The Happy_rank field in happiness_N can act as a foreign key for the CountryStats table,
#in a one-one relationship. An example below:
ALTER TABLE happiness_2019
ADD CONSTRAINT PK_happiness PRIMARY KEY (happy_rank);

ALTER TABLE CountryStats
ADD CONSTRAINT FK_happiness FOREIGN KEY (happy_rank_2019) REFERENCES happiness_2019(happy_rank);

#Question 11: Select all countries and their happy_score, alongside average happiness score of region 
#Used a window function instead of JOIN + GROUP BY, since it makes it more readable!
SELECT a.country_name, b.happy_score, a.region, avg(b.happy_score) OVER(PARTITION BY region) AS Regional_avg
FROM CountryStats AS a
JOIN happiness_2019 AS b USING (country_name); #Look familiar? Check my answer to Q8_Extended_2!

#Question 12:
#change default delimiter for the purpose of creating procedure.
DELIMITER //

CREATE PROCEDURE UpdateHappinessRank (check_name VARCHAR(30), new_rank INT, what_year INT)
BEGIN #The STORED PROCEDURE is set to only work on a TEST version of the CountryStats table - I don't want to actually update any false ranks!
	UPDATE CountryStats_TEST SET happy_rank_2015 = CASE WHEN what_year = 2015 THEN new_rank ELSE happy_rank_2015 END,
							     happy_rank_2016 = CASE WHEN what_year = 2016 THEN new_rank ELSE happy_rank_2016 END,
                                 happy_rank_2017 = CASE WHEN what_year = 2017 THEN new_rank ELSE happy_rank_2017 END,
                                 happy_rank_2018 = CASE WHEN what_year = 2018 THEN new_rank ELSE happy_rank_2018 END,
                                 happy_rank_2019 = CASE WHEN what_year = 2019 THEN new_rank ELSE happy_rank_2019 END
	WHERE country_name = check_name;
END //

#change back default delimiter.
DELIMITER ;

#Testing this works oncountrystatscountrystats a copy of CountryStats, i.e. CountryStats_TEST
CREATE TABLE CountryStats_TEST AS SELECT * FROM CountryStats;

#check current values for Zimbabwe on CountryStats original (so it is always there!)
SELECT * FROM CountryStats WHERE country_name = 'Zimbabwe';

#Changing happy_rank_2016 on CountryStats_TEST to rank 1.
CALL UpdateHappinessRank('Zimbabwe', 600, 2015);

#Check new values for Zimbabwe on CountryStats_TEST:
SELECT * FROM CountryStats_TEST WHERE country_name = 'Zimbabwe';


#Question 13: Query to find the top 5 regions with the highest generosity score.
#No need for any fancy work, in this case, a very simple JOIN + GROUP BY region is enough. We don't need to make any country - region comparisons.
SELECT region, AVG(generosity) AS Regional_generosity_avg 
FROM CountryStats AS a
JOIN happiness_2019 AS b USING (country_name) #Again, this is very familiar... look at my Q8 original implementation to see the parallel!
GROUP BY a.region
ORDER BY AVG(generosity) DESC
LIMIT 5; #Display only 5 results, from highest avg(generosity) descending.

#Question 14: We care about the difference in rank between 2015 and 2019. Means that we don't actually
#care about the rank at 2016, 2017, and 2018, just that they made atleast a 10 rank difference at the entry
#and terminus...
SELECT a.Country_name, b15.happy_rank as Rank_2015, b19.happy_rank as Rank_2019
FROM CountryStats as a
JOIN happiness_2015 as b15 USING(Country_name) 
JOIN happiness_2019 as b19 USING(Country_name)
WHERE b15.happy_rank - b19.happy_rank > 10; #Since we are looking for an INCREASE in rank (i.e. LOWER rank), we subtract 2019 from 2015.

#Question 15: For 2019, Would make a CTE that calculates the average life expectancy across all countries 
# within the happiness_2019 table.
WITH global_life_expectancy AS (
	SELECT AVG(health) AS global_avg
    FROM happiness_2019
)
SELECT a.Country_name, b.health, global_life_expectancy.global_avg AS global_avg
FROM CountryStats AS a
JOIN happiness_2019 AS b USING (Country_name)
#Filter results where life_expectancy is higher than that global average.
JOIN global_life_expectancy ON b.health > global_life_expectancy.global_avg;
#Much better for readability, especially if we are going to be using this very often!
#To return back to Q8, this is ANOTHER variation we could have used to do it.