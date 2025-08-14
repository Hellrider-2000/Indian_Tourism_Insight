# Indian Tourism Insights – SQL Analysis

## 📌 Project Overview
This project uses SQL to analyze a dataset of **Top Indian Places to Visit**.  
It provides deep insights into attraction ratings, visitor convenience, state-level tourism density, and travel planning recommendations.

**Dataset Size:** 325 records × 15 columns  
**Tools Used:** MySQL (queries written in standard SQL syntax)  

---

## 🎯 Objectives
- Identify the **best-rated** attractions across India.
- Understand the **geographic distribution** and density of tourist sites.
- Categorize attractions by **type, popularity, and accessibility**.
- Offer **travel convenience** insights for better trip planning.

---

## 📂 Dataset Columns
| Column Name              | Data Type |
|--------------------------|-------------|
| ID                     | INT |
| Name                     | TEXT |
| State                    | TEXT |
| Zone                     | TEXT |
| City                     | TEXT |
| Type                     | TEXT |
| Time_needed_to_visit_in_hrs                   | DOUBLE |
| Google_review_rating                | DOUBLE |
| Entrance_Fee_in_INR       | INT |
| Airport_with_50km_Radius      | TEXT |
| Weekly_Off             | TEXT |
| Significance              | TEXT |
| DSLR_Allowed            | TEXT|
| Number_of_google_review_in_lakhs      | DOUBLE |
| Best_Time_to_visit           | TEXT |

---

## 📊 Analysis & Insights

### **A. Popularity & Ratings**
1. **Top 10 Rated Attractions**
```SQL
SELECT name, state, google_review_rating
FROM top_indian_places_to_visit
ORDER BY google_review_rating DESC, Number_of_google_review_in_lakhs DESC
LIMIT 10;
```

2. **Top 5 Attractions Per State by Rating**
```SQL
WITH ranked_places_state AS (
    SELECT 
        zone,state, name, google_review_rating, Significance, Best_time_to_visit,
        ROW_NUMBER() OVER(PARTITION BY state ORDER BY Google_review_rating DESC) AS ranking
    FROM   top_indian_places_to_visit
)
SELECT * FROM ranked_places_state
WHERE ranking <=5; 
```

3. **Top 5 Attractions Per Zone by Rating**
```SQL
WITH ranked_places_zone AS (
  SELECT 
        zone,state, name, google_review_rating, Significance, Best_time_to_visit,
        ROW_NUMBER() OVER(PARTITION BY zone ORDER BY Google_review_rating DESC) AS ranking
    FROM   top_indian_places_to_visit
)
SELECT * FROM ranked_places_zone
WHERE ranking <=5;
```

4. **Top 5 Attractions Per Type by Rating**
```SQL
WITH ranked_attractions_type AS (
    SELECT 
        type, name, state,
        google_review_rating,
        ROW_NUMBER() OVER (PARTITION BY type ORDER BY Google_review_rating DESC) AS Ranking
	FROM top_indian_places_to_visit
)
SELECT * FROM ranked_attractions_type
WHERE ranking <=5;
```

5. **Categorized Attractions by Popularity** 
```SQL
SELECT name, state, Number_of_google_review_in_lakhs,
       CASE 
           WHEN Number_of_google_review_in_lakhs >= 2 THEN 'Highly Popular'
           WHEN Number_of_google_review_in_lakhs BETWEEN 1 AND 2 THEN 'Moderately Popular'
           ELSE 'Less Popular'
       END AS popularity_category
FROM top_indian_places_to_visit
ORDER BY Number_of_google_review_in_lakhs DESC;
```

---

### **B. Geographic & Distribution Insights**
6. **State with the Most Attractions**
```SQL
WITH count_of_places_state AS(
SELECT DISTINCT
	STATE,
    COUNT(*) OVER(PARTITION BY State) AS Number_of_Sites
FROM top_indian_places_to_visit
)
SELECT *,
	RANK() OVER(ORDER BY Number_of_sites DESC) AS RANKING
FROM count_of_places_state;  
```

7. **Attraction Density Per State vs National Average**
```SQL
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
```

8. **Most Reviewed Attraction in Each Zone**
```SQL
SELECT zone, name, state,  Number_of_google_review_in_lakhs
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY zone ORDER BY Number_of_google_review_in_lakhs DESC) AS ranking
    FROM top_indian_places_to_visit
) t
WHERE ranking = 1;
```

---

### **C. Attraction Types & Characteristics**
9. **Number of Sites by Attraction Type**
```SQL
WITH count_of_places_type AS(
SELECT DISTINCT
    type,
    COUNT(*) OVER(PARTITION BY Type) AS total_type_Sites
FROM top_indian_places_to_visit
)
SELECT * 
FROM count_of_places_type
ORDER BY total_type_Sites DESC;

```
10. **Attractions by Significance**
```SQL
SELECT DISTINCT 
       significance,
       COUNT(*) OVER (PARTITION BY significance) AS total_places
FROM top_indian_places_to_visit
ORDER BY total_places DESC;
```
11. **Average Visit Time by Site Type**
```SQL
SELECT DISTINCT
       type,
       ROUND(AVG(time_needed_to_visit_in_hrs) OVER (PARTITION BY type), 1) AS avg_time
FROM top_indian_places_to_visit
ORDER BY avg_time DESC;
```

12. **Quick Visit** – Sites that take less than 1 hours
```SQL
SELECT name, state, type,time_needed_to_visit_in_hrs
FROM top_indian_places_to_visit
WHERE time_needed_to_visit_in_hrs < 1
ORDER BY time_needed_to_visit_in_hrs;
```
13. **Best Cities for One-Day Trips** (< 8 hours total visit time for top attractions)
```SQL
SELECT city, state, SUM(time_needed_to_visit_in_hrs) AS total_time
FROM top_indian_places_to_visit
GROUP BY city, state
HAVING total_time <= 8
ORDER BY total_time DESC;
```

---

### **D. Travel & Visitor Convenience**
14. **Free Entry Attractions**
```SQL
SELECT state,
	city,
    name,
    significance
FROM  top_indian_places_to_visit
WHERE Entrance_fee_in_INR = 0
ORDER BY state;  
```
15. **Average Entry Fee by Type**
```SQL
SELECT 
	Type,
    ROUND(AVG(Entrance_fee_in_INR),0) AS avg_Entry_Fee
FROM  top_indian_places_to_visit
Group by type
ORDER BY avg_Entry_Fee DESC;
```

16. **Air Travel Convenience** – Attractions within 50 km of an airport
```SQL
SELECT 
	COUNT(*) AS Total_Places, 
	SUM(CASE WHEN Airport_with_50km_Radius = 'Yes' THEN 1 ELSE 0 END) AS With_Airport,
	ROUND(100.0 * SUM(CASE WHEN Airport_with_50km_Radius = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS percentage_with_airport
FROM top_indian_places_to_visit;
```

17. **Best Time to Visit Distribution**
```SQL
SELECT best_time_to_visit, COUNT(*) AS total_places
FROM top_indian_places_to_visit
GROUP BY best_time_to_visit
ORDER BY total_places DESC;
```

18. **DSLR Allowed** – Photography-friendly places
```SQL
SELECT 
	COUNT(*) AS Total_Places,
    SUM(CASE WHEN DSLR_Allowed = 'Yes' THEN 1 ELSE 0 END) AS Total_DSLR_Allowed,
	ROUND(100.0 * SUM(CASE WHEN DSLR_Allowed = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS dslr_allowed_percentage
FROM top_indian_places_to_visit;
```

19. **Weekly Closure Patterns**
```SQL
SELECT weekly_off, COUNT(*) AS total_places
FROM top_indian_places_to_visit
GROUP BY weekly_off
ORDER BY total_places DESC;
```

---

## 📈 Key Findings
- Delhi and Mumbai dominate most reviewed categories.
- Uttar Pradesh, Maharashtra & West Bengal have the most tourist sites.
- Religious and historical sites are the most common types.
- Around 70% of attractions are within 50 km of an airport.
- Almost all places (294) are open on all days of the week.
- Almost 82% places allowed photography.


### 📂Download full SQL Query 
[Here](https://github.com/Hellrider-2000/Indian_Tourism_Insight/blob/main/SQL%20PROJECT.sql)

### 📂Download Dataset
[Here](https://github.com/Hellrider-2000/Indian_Tourism_Insight/blob/main/Top%20Indian%20Places%20to%20Visit.csv)

## 👨‍💻 Author
- Abhranil Das
- 📧 Gmail: 9abhranil@gmail.com
