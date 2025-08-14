-- CREATING DATABSE
CREATE DATABASE Tourism_Insights;
USE tourism_insights;

-- DATA PROCESSING & DATA CLEANING
-- ALTER TABLE NAME

ALTER TABLE `tourism_insights`.`top indian places to visit` 
RENAME TO  `tourism_insights`.`top_indian_places_to_visit` ;

-- ALTERING COLUMNS 

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `ID` `ID` INT NOT NULL ,
ADD UNIQUE INDEX `ID_UNIQUE` (`ID` ASC);

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `DSLR Allowed` `DSL_ Allowed` TEXT NULL DEFAULT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `time needed to visit in hrs` `Time_needed_to_visit_in_hrs` DOUBLE NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Google review rating` `Google_review_rating` DOUBLE NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Entrance Fee in INR` `Entrance_Fee_in_INR` INT NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Airport with 50km Radius` `Airport_with_50km_Radius` TEXT NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Weekly Off` `Weekly_Off` TEXT NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Number of google review in lakhs` `Number_of_google_review_in_lakhs` DOUBLE NOT NULL ;

ALTER TABLE `tourism_insights`.`top indian places to visit` 
CHANGE COLUMN `Best Time to visit` `Best_Time_to_visit` TEXT NOT NULL;

-- Replace 'None' AND 'Yes' in Weekly_Off with 'Open All Days'

UPDATE tourism_insights.top_indian_places_to_visit
SET Weekly_Off = 'Open All Days'
WHERE Weekly_Off IS NULL OR Weekly_Off = 'None' OR WEEKLY_OFF= 'YES';

-- Standardize Airport column values (Yes/No)

UPDATE top_indian_places_to_visit
SET Airport_with_50km_Radius = CASE 
    WHEN LOWER(Airport_With_50km_Radius) LIKE 'y%' THEN 'Yes'
    ELSE 'No'
END;

-- Remove extra spaces in text fields
UPDATE top_indian_places_to_visit
SET Zone = TRIM(Zone), State = TRIM(State), City = TRIM(City), Type = TRIM(Type);

-- full table
SELECT * FROM top_indian_places_to_visit;


-- DATA ANALYSIS
-- Top 10 rated attraction
SELECT name, state, google_review_rating
FROM top_indian_places_to_visit
ORDER BY google_review_rating DESC, Number_of_google_review_in_lakhs DESC
LIMIT 10; 

-- Top 5 Attractions Per State by Rating
WITH ranked_places_state AS (
    SELECT 
        zone,state, name, google_review_rating, Significance, Best_time_to_visit,
        ROW_NUMBER() OVER(PARTITION BY state ORDER BY Google_review_rating DESC) AS ranking
    FROM   top_indian_places_to_visit
)
SELECT * FROM ranked_places_state
WHERE ranking <=5; 

-- Top 5 Attractions Per zone by Rating
  WITH ranked_places_zone AS (
  SELECT 
        zone,state, name, google_review_rating, Significance, Best_time_to_visit,
        ROW_NUMBER() OVER(PARTITION BY zone ORDER BY Google_review_rating DESC) AS ranking
    FROM   top_indian_places_to_visit
)
SELECT * FROM ranked_places_zone
WHERE ranking <=5;

-- Top 5 attraction per type by rating
WITH ranked_attractions_type AS (
    SELECT 
        type, name, state,
        google_review_rating,
        ROW_NUMBER() OVER (PARTITION BY type ORDER BY Google_review_rating DESC) AS Ranking
	FROM top_indian_places_to_visit
)
SELECT * FROM ranked_attractions_type
WHERE ranking <=5;

-- Categorize attractions by popularity
SELECT name, state, Number_of_google_review_in_lakhs,
       CASE 
           WHEN Number_of_google_review_in_lakhs >= 2 THEN 'Highly Popular'
           WHEN Number_of_google_review_in_lakhs BETWEEN 1 AND 2 THEN 'Moderately Popular'
           ELSE 'Less Popular'
       END AS popularity_category
FROM top_indian_places_to_visit
ORDER BY Number_of_google_review_in_lakhs DESC;



-- State with the most attractions
WITH count_of_places_state AS(
SELECT DISTINCT
	STATE,
    COUNT(*) OVER(PARTITION BY State) AS Number_of_Sites
FROM top_indian_places_to_visit
)
SELECT *,
	RANK() OVER(ORDER BY Number_of_sites DESC) AS RANKING
FROM count_of_places_state;  

-- Attraction density per state compared to national average
WITH state_counts AS (
    SELECT state, COUNT(*) AS total_places
    FROM top_indian_places_to_visit
    GROUP BY state
),
national_avg AS (
    SELECT AVG(total_places) AS avg_places FROM state_counts
)
SELECT s.state, s.total_places,
       CASE WHEN s.total_places > n.avg_places THEN 'Above Average'
            WHEN s.total_places = n.avg_places THEN 'Average'
            ELSE 'Below Average'
       END AS density_category
FROM state_counts s, national_avg n
ORDER BY s.total_places DESC;

-- Most Reviewed Attraction in Each Zone
SELECT zone, name, state,  Number_of_google_review_in_lakhs
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY zone ORDER BY Number_of_google_review_in_lakhs DESC) AS ranking
    FROM top_indian_places_to_visit
) t
WHERE ranking = 1;





-- Number of sites by attraction type
WITH count_of_places_type AS(
SELECT DISTINCT
    type,
    COUNT(*) OVER(PARTITION BY Type) AS total_type_Sites
FROM top_indian_places_to_visit
)
SELECT * 
FROM count_of_places_type
ORDER BY total_type_Sites DESC;

-- Attractions by significance
SELECT DISTINCT 
       significance,
       COUNT(*) OVER (PARTITION BY significance) AS total_places
FROM top_indian_places_to_visit
ORDER BY total_places DESC;

-- Average visit time by Sites type
SELECT DISTINCT
       type,
       ROUND(AVG(time_needed_to_visit_in_hrs) OVER (PARTITION BY type), 1) AS avg_time
FROM top_indian_places_to_visit
ORDER BY avg_time DESC;
    
-- Quick visit 
SELECT name, state, type,time_needed_to_visit_in_hrs
FROM top_indian_places_to_visit
WHERE time_needed_to_visit_in_hrs < 1
ORDER BY time_needed_to_visit_in_hrs;

-- Best cities for one-day trips (< 8 hours total)
SELECT city, state, SUM(time_needed_to_visit_in_hrs) AS total_time
FROM top_indian_places_to_visit
GROUP BY city, state
HAVING total_time <= 8
ORDER BY total_time DESC;

-- FREE ENTRY
SELECT state,
	city,
    name,
    significance
FROM  top_indian_places_to_visit
WHERE Entrance_fee_in_INR = 0
ORDER BY state;  

-- Average Entry Fee by type 
SELECT 
	Type,
    ROUND(AVG(Entrance_fee_in_INR),0) AS avg_Entry_Fee
FROM  top_indian_places_to_visit
Group by type
ORDER BY avg_Entry_Fee DESC;

-- Air Travel Convenience
SELECT 
	COUNT(*) AS Total_Places, 
	SUM(CASE WHEN Airport_with_50km_Radius = 'Yes' THEN 1 ELSE 0 END) AS With_Airport,
	ROUND(100.0 * SUM(CASE WHEN Airport_with_50km_Radius = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percentage_with_airport
FROM top_indian_places_to_visit;


-- Best time to visit distribution
SELECT best_time_to_visit, COUNT(*) AS total_places
FROM top_indian_places_to_visit
GROUP BY best_time_to_visit
ORDER BY total_places DESC;

-- DSLR Allowed
SELECT 
	COUNT(*) AS Total_Places,
    SUM(CASE WHEN DSLR_Allowed = 'Yes' THEN 1 ELSE 0 END) AS Total_DSLR_Allowed,
	ROUND(100.0 * SUM(CASE WHEN DSLR_Allowed = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS dslr_allowed_percentage
FROM top_indian_places_to_visit;

-- Weekly closure patterns
SELECT weekly_off, COUNT(*) AS total_places
FROM top_indian_places_to_visit
GROUP BY weekly_off
ORDER BY total_places DESC;





















