-- Selecting all fields
SELECT
	*, 
    row_number() OVER(PARTITION BY publisheddate ORDER BY title ASC, publishedtime ASC) AS rownum FROM movieclips;

SELECT AVG(view_count), MIN(view_count), MAX(view_count) FROM movieclips;

SELECT title, view_count
	FROM movieclips
		WHERE view_count > 400000000;
        
-- MovieClips uploads movies in separate parts. Find the total view count for every movie
-- ----------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------
SELECT title, sum(view_count)
	FROM movieclips
		GROUP BY SUBSTRING(title, 1,25)
		ORDER BY sum(view_count) DESC;
-- ----------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------

-- What are the top movies watched each year
-- Creating CTE to view top ten clips for each year ranked by view count
WITH order_views AS(
	SELECT title,
		description, 
		publisheddate,
        publishedtime,
        view_count,
        like_count,
        comment_count,
        RANK() OVER(
        PARTITION BY YEAR(publisheddate)
        ORDER BY view_count DESC
        ) order_view_rank
	FROM movieclips
    )
SELECT * FROM order_views;


CREATE VIEW with_rnk AS 
(
WITH order_views AS(
	SELECT title,
		description, 
		publisheddate,
        publishedtime,
        HOUR(publishedtime) AS hour_block,
        view_count,
        like_count,
        comment_count,
        RANK() OVER(
        PARTITION BY YEAR(publisheddate)
        ORDER BY view_count DESC
        ) order_view_rank
	FROM movieclips
    )
SELECT * FROM order_views
);

SELECT * FROM with_rnk;
    
-- What is the average monthly view count for each year
-- Creating CTE to view total monthly view per year
WITH monthly_views AS(
	SELECT title,
		description, 
		publisheddate,
        YEAR(publisheddate) AS years,
        MONTHNAME(publisheddate) AS months,
        publishedtime,
        SUM(view_count) as monthly_view,
        like_count,
        comment_count
	FROM movieclips
		GROUP BY 4,5 
        ORDER BY 5,5
)
SELECT years, months, monthly_view FROM monthly_views
	ORDER BY 1,2;
    
 -- USING ROLLUP FUNCTIONS
WITH CTE AS (
SELECT
	title,
    description,
    publisheddate,
    YEAR(publisheddate) as years,
    MONTHNAME(publisheddate) as months,
    DAYNAME(publisheddate) as days,
    publishedtime,
    view_count,
    like_count,
    comment_count
FROM movieclips
)
SELECT 
	years, months, days,
	IF(GROUPING(years), 'Every year', years) AS gp_year,
    IF(GROUPING(months), 'Every months', months) AS gp_month,
    IF(GROUPING(days), 'Every days', days) AS gp_day,
	SUM(view_count), SUM(like_count), SUM(comment_count)
FROM CTE
	GROUP BY years, months, days WITH ROLLUP
    ORDER BY years, months, days;   
    
-- When is the best day for MovieClips to upload a movie?
-- Selecting list of days of the week ordered by total view count for each day
SELECT 
	DAYNAME(publisheddate) as days,
	SUM(view_count)
FROM movieclips
GROUP BY 1
ORDER BY 2 DESC;

SELECT 
	DAYNAME(publisheddate) as days,
	AVG(view_count)
FROM movieclips
GROUP BY 1
ORDER BY 2 DESC;

-- On Friday, when is the best hour block for MovieClips to upload a movie?
-- Creating CTE to view total view count ranked per hour on Saturday
WITH friday AS (
	SELECT 
			DAYOFWEEK(publisheddate) as days,
			HOUR(publishedtime) as hourblock,
			view_count
	FROM movieclips
		WHERE DAYOFWEEK(publisheddate) = 6
)
SELECT hourblock, AVG(view_count)
	FROM friday
		GROUP BY hourblock
        ORDER BY AVG(view_count) DESC;
        
 -- When is the best hour block for MovieClips to upload a movie all week?
-- Creating CTE to view total view count ranked per hour on average per the whole week
SELECT 
	HOUR(publishedtime) as hourblock,
    AVG(view_count) as views
		FROM movieclips
			GROUP BY 1
            ORDER BY 2 DESC;

SELECT 
	HOUR(publishedtime) as hourblock,
    SUM(view_count) as views
		FROM movieclips
			GROUP BY 1
            ORDER BY 2 DESC;

-- Which video has the greatest like to view count?
-- Creating CTE to view top ten greatest Like/View ratio
WITH lv_table AS(
	SELECT title,
		description, 
		publisheddate,
        publishedtime,
		(like_count/view_count) * 100 AS LV_ratio,
        RANK() OVER(
        ORDER BY (like_count/view_count) * 100 DESC
        ) LV_rank,
        comment_count
	FROM movieclips
)
SELECT * FROM lv_table
	WHERE LV_rank <= 10
    ORDER BY LV_rank ASC;
    
-- The video must be viral, so lets filter out videos with views less than 1 million. Which video has the greatest like to view count?
-- Creating CTE to view top ten greatest Like/View ratio
WITH lv_table AS(
	SELECT title,
		description, 
		publisheddate,
        publishedtime,
		(like_count/view_count) * 100 AS LV_ratio,
        RANK() OVER(
        ORDER BY (like_count/view_count) * 100 DESC
        ) LV_rank,
        comment_count
	FROM movieclips
		WHERE view_count >= 1000000
)
SELECT * FROM lv_table
	WHERE LV_rank <= 10;
    
-- Are there any similar movieClips based on their view and like count?
-- Selecting list to view titles where view count and like count are the same when rounded to the nearest 1000 and 100 respectively
SELECT A.title, B.title, A.view_count, A.like_count
	FROM movieclips A, movieclips B
		WHERE (FLOOR(A.view_count/1000)*1000) = (FLOOR(B.view_count/1000)*1000)
        AND (FLOOR(A.like_count/100)*100) = (FLOOR(B.like_count/100)*100)
        AND A.title <> B.title;

-- Let viral videos be a movieClips video that has a view_count greater than movieClips' average view count. Find the most common day and time when these videos are uploaded.
-- Creating CTE to view the day of the week and count of when viral videos are uploaded
WITH day_of_week AS (
	SELECT
	title,
    DAYNAME(publisheddate) AS days,
    HOUR(publishedtime) AS hourblock,
    view_count,
	CASE
		WHEN view_count > (
        SELECT AVG(view_count)
        FROM movieclips
        ) THEN 'viral'
        ELSE 'not viral'
	END viral_video
	FROM movieclips
    )
SELECT days, COUNT(distinct title) FROM day_of_week
	WHERE viral_video = 'viral'
    GROUP BY 1
    ORDER BY 2 DESC;
    
-- Creating CTE to view the hour of the day and count of when viral videos are uploaded
WITH day_of_week AS (
	SELECT
	title,
    DAYNAME(publisheddate) AS days,
    HOUR(publishedtime) AS hourblock,
    view_count,
	CASE
		WHEN view_count > (
        SELECT AVG(view_count)
        FROM movieclips
        ) THEN 'viral'
        ELSE 'not viral'
	END viral_video
	FROM movieclips
    )
SELECT hourblock, COUNT(distinct title) FROM day_of_week
	WHERE viral_video = 'viral'
    GROUP BY 1
    ORDER BY 2 DESC;

DROP VIEW annual_views1;

CREATE VIEW annual_views AS(
WITH CTE AS(
SELECT
    publisheddate,
    YEAR(publisheddate) as years,
    MONTHNAME(publisheddate) as months,
    DAYNAME(publisheddate) as days,
    publishedtime,
    view_count,
    like_count,
    comment_count
FROM movieclips
)
SELECT 
	publisheddate, years, months, days,
	IF(GROUPING(years), 'Every year', years) AS gp_year,
    IF(GROUPING(months), 'Every months', months) AS gp_month,
    IF(GROUPING(days), 'Every days', days) AS gp_day,
	SUM(view_count), SUM(like_count), SUM(comment_count)
FROM CTE
	GROUP BY years, months, days WITH ROLLUP
    ORDER BY years, months, days
    );

CREATE VIEW annual_views1 AS (
SELECT * FROM annual_views
	WHERE days IS NOT NULL);
    
    
SELECT 'published_date','years', 'months', 'days', 'gp_year', 'gp_month', 'gp_day', 'SUM(view_count)', 'SUM(like_count)', 'SUM(comment_count)' 
	UNION ALL
		SELECT * 
			FROM annual_views1
				INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\movie_clips_annual_views_final.csv'
					FIELDS TERMINATED BY ','
					ENCLOSED BY ''
					LINES TERMINATED BY '\n';
-- SHOW variables LIKE "secure_file_priv";

SELECT * FROM with_rnk;

SELECT 'title', 'description', 'publisheddate', 'publishedtime', 'hour_block','view_count', 'like_count', 'comment_count', 'order_view_rank'
	UNION ALL
		SELECT * 
			FROM with_rnk
				INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\movie_clips_annual_views_with_rnk.csv'
					FIELDS TERMINATED BY ','
					ENCLOSED BY ''
					LINES TERMINATED BY '\n';

WITH CTE1 AS(
	SELECT 
		title, 
        description,
        publisheddate,
        publishedtime,
        view_count,
        like_count,
        comment_count,
        RANK() OVER(
			PARTITION BY YEAR(publisheddate)
            ORDER BY view_count DESC
        ) rnk
	FROM movieclips
)
SELECT * FROM CTE1
	WHERE YEAR(publisheddate) = 2016
    AND rnk <= 10;
