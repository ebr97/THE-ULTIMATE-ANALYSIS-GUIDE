USE AnalysisProjects -- specifying what Database to use

--========================	Data Cleaning	==============================

-- making sure that common columns has the same format
EXEC sp_help disney_movies_total_gross;
EXEC sp_help disney_revenue_1991_2016;
EXEC sp_help disney_characters;
EXEC sp_help disney_director;
EXEC sp_help disney_voice_actors;

--changing name index into id to avoid any errors in sql

EXEC sp_rename 'disney_movies_total_gross.index', 'id'

ALTER TABLE disney_voice_actors
ADD PRIMARY KEY (id)


--let's see the data
SELECT * FROM disney_movies_total_gross

--populating the null values from genre with value 'other'
UPDATE disney_movies_total_gross
SET genre = 'Other'
WHERE genre IS NULL

--populating the null values from MPAA_rating with value 'other'
UPDATE disney_movies_total_gross
SET MPAA_rating = 'N/A'
WHERE MPAA_rating IS NULL

ALTER TABLE disney_movies_total_gross
ALTER COLUMN release_date date -- changing release date to a date format because we won't run any analysis that involves time


SELECT * FROM disney_movies_total_gross
ORDER BY release_date DESC -- it seems like the movies with id 0-4 have the wrong release date instead of 1937 for Snow White we have 2037 let's change that

UPDATE disney_movies_total_gross
SET release_date = REPLACE(release_date, '20', '19')
WHERE release_date IN ('2037-12-21', '2040-02-09', '2040-11-13', '2046-11-12')

SELECT * FROM disney_movies_total_gross  --total_gross and inflation_adjusted_gross are strings we'll transform them into int to use further in our analysis

-- let's get rid off $ sign

UPDATE disney_movies_total_gross
SET total_gross = REPLACE(total_gross, '$', '')

UPDATE disney_movies_total_gross
SET total_gross = REPLACE(total_gross, ',', '')

UPDATE disney_movies_total_gross
SET inflation_adjusted_gross = REPLACE(inflation_adjusted_gross, '$', '')

UPDATE disney_movies_total_gross
SET inflation_adjusted_gross = REPLACE(inflation_adjusted_gross, ',', '')

UPDATE disney_movies_total_gross
SET inflation_adjusted_gross = TRIM(inflation_adjusted_gross)

--let's change the format of those two columns in integer

ALTER TABLE disney_movies_total_gross
ALTER COLUMN total_gross int

ALTER TABLE disney_movies_total_gross
ALTER COLUMN inflation_adjusted_gross bigint

--verifing if there are any movies with zero gross

SELECT * FROM disney_movies_total_gross
WHERE inflation_adjusted_gross = 0

--it seems like we have four movies, in this case I will delete them (in a real case scenario I will lookup after info over the internet)

DELETE FROM disney_movies_total_gross
WHERE inflation_adjusted_gross = 0

SELECT * FROM disney_movies_total_gross
--The disney_movies_total_gross is now cleaned
----------------------------------------------------------------

SELECT * FROM disney_revenue_1991_2016

--Let's change the columns format (Studio_Entertainment_NI_1, Disney_Consumer_Products_NI_2, Disney_Interactive_NI_3_Rev_1, Walt_DIsney_Parks_and_Resorts, Disney_Media_Networks, Total)

ALTER TABLE disney_revenue_1991_2016
ALTER COLUMN Disney_Media_Networks float --here it seems for the row no 5 we have a comma instead of a period and we won't be able to convert from varchar to float
										 --simply I will get rid of it because 4.412 doesn't make any sense

UPDATE disney_revenue_1991_2016
SET Disney_Media_Networks = '4142'
WHERE DIsney_Media_Networks = '4,142'

ALTER TABLE disney_revenue_1991_2016
ALTER COLUMN Total int

--The disney_revenue_1991_2016 is now cleaned
----------------------------------------------------------------

SELECT * FROM disney_characters
EXEC sp_help disney_characters;

--let's change the format for release date in date

ALTER TABLE disney_characters
ALTER COLUMN release_date date

--The disney_revenue_1991_2016 is now cleaned
----------------------------------------------------------------

SELECT * FROM disney_director

SELECT * FROM disney_voice_actors



--========================	Data Exploratory	==============================

SELECT * FROM disney_movies_total_gross

--Let's see what genres are with the most total gross earnings

SELECT *
FROM disney_movies_total_gross
ORDER BY genre, inflation_adjusted_gross DESC

SELECT genre, COUNT(id) no_of_movies_per_genre, SUM(inflation_adjusted_gross) total_earnings --from here we can see that a lot of movies are in these three genres (adventure, comedy, drama)
FROM disney_movies_total_gross																 --the fact that Musical genre made more money than the Drama genre even if the difference between them
GROUP BY genre																				 --is nearly 100 movies make me to further investigate if there is any relationship between no of movies
ORDER BY 3 DESC																				 --genre and earnings
--Let's see, on average, how much gross earning can produce a movie, split on genres 

WITH avg_movie_gross_per_genre																		--we can see that the movies from Musical genre, on average produce more gross earnings
AS
(
	SELECT genre, COUNT(id) no_of_movies_per_genre, SUM(inflation_adjusted_gross) total_earnings 
	FROM disney_movies_total_gross																 
	GROUP BY genre																				 
)SELECT genre, total_earnings/no_of_movies_per_genre AS avg_gross
FROM avg_movie_gross_per_genre
ORDER BY 2 DESC

--Let's see what is the time frame for each genre

SELECT genre, 
       COUNT(id) no_of_movies_made, 
	   MIN(release_date) first_year,
	   MAX(release_date) last_year, 
	   CASE WHEN DATEDIFF(year,MIN(release_date),MAX(release_date)) > 1 THEN CONCAT(DATEDIFF(year,MIN(release_date),MAX(release_date)),' years')
	   ELSE CONCAT(DATEDIFF(year,MIN(release_date),MAX(release_date)),' year')
	   END timeframe 
INTO disney_genre_timeframe
FROM disney_movies_total_gross
GROUP BY genre
ORDER BY 2 DESC

SELECT * FROM disney_genre_timeframe

--Let's see the minimum and maximum earnings for each genre and the titles of those movies

SELECT d1.* FROM disney_movies_total_gross d1
JOIN (
		SELECT genre, 
			   MIN(inflation_adjusted_gross) minimum_gross, 
			   MAX(inflation_adjusted_gross) maximum_gross
		FROM disney_movies_total_gross
		GROUP BY genre
	 ) d2
	ON d1.genre = d2.genre
	AND (d1.inflation_adjusted_gross = d2.minimum_gross OR d1.inflation_adjusted_gross = d2.maximum_gross)

--In this list we can find movie names that made history like Snow White, Pinocchio, 101 Dalmatians, Lady and the Tramp, Pretty Woman and The Avengers and are top earners for their genre
--Also we can see that the majority of the names (4) are Animations and two are actual movies with actors. This need a little more investigations especially if we want to make predictions.

--Let's print the top 3 earners for each category

WITH top_three_per_genre
AS
(
SELECT d1.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Action'
	ORDER BY inflation_adjusted_gross DESC
	) d1

UNION ALL

SELECT d2.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Adventure'
	ORDER BY inflation_adjusted_gross DESC
	) d2

UNION ALL

SELECT d3.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Black Comedy'
	ORDER BY inflation_adjusted_gross DESC
	) d3

UNION ALL

SELECT d4.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Comedy'
	ORDER BY inflation_adjusted_gross DESC
	) d4

UNION ALL

SELECT d5.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Concert/Performance'
	ORDER BY inflation_adjusted_gross DESC
	) d5

UNION ALL

SELECT d6.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Documentary'
	ORDER BY inflation_adjusted_gross DESC
	) d6

UNION ALL

SELECT d7.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Drama'
	ORDER BY inflation_adjusted_gross DESC
	) d7

UNION ALL

SELECT d8.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Horror'
	ORDER BY inflation_adjusted_gross DESC
	) d8

UNION ALL

SELECT d9.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Musical'
	ORDER BY inflation_adjusted_gross DESC
	) d9

UNION ALL

SELECT d10.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Other'
	ORDER BY inflation_adjusted_gross DESC
	) d10

UNION ALL

SELECT d11.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Romantic Comedy'
	ORDER BY inflation_adjusted_gross DESC
	) d11

UNION ALL

SELECT d12.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Thriller/Suspense'
	ORDER BY inflation_adjusted_gross DESC
	) d12

UNION ALL

SELECT d13.* FROM
	(
	SELECT TOP 3 movie_title, release_date, genre, total_gross, inflation_adjusted_gross
	FROM disney_movies_total_gross
	WHERE genre = 'Western'
	ORDER BY inflation_adjusted_gross DESC
	) d13
)SELECT *
INTO disney_top_three_per_genre
FROM top_three_per_genre

SELECT * FROM disney_top_three_per_genre
--looking into this and taking into account the above results from thelast 3 querys, appears that for the genre with a bigger timeframe the top 3 movies per genre, with higher total_gross
--are preponderantly animations and for the ones with medium to small timeframe are movies with actual actors :)

--Let's summarise this data into one single table

SELECT thr.*,
	   d.timeframe_years
FROM disney_top_three_per_genre thr
JOIN (
		SELECT genre, 
			   COUNT(id) no_of_movies_made, 
			   MIN(release_date) first_year,
			   MAX(release_date) last_year, 
			   DATEDIFF(year,MIN(release_date),MAX(release_date)) timeframe_years
		FROM disney_movies_total_gross
		GROUP BY genre
	 ) d
	ON thr.genre = d.genre
ORDER BY 6 DESC

/* Some insights from the querys above: For the genre with a timeframe bigger or equal than 53 years the top three movies with high gross are animations
								        For the ones with a timeframe smaller or equal than 34 years the top movies with high gross are actual movies with actors
										Most movies are in these three genres: adventure, comedy and drama
										But the the top three total_gross genres are adventure, comedy and musical this means that is not necesary to have higher total_gross if the no of movies are high, per genre
*/

SELECT * FROM disney_revenue_1991_2016 --we know that the number represents gross splitted in different categories but we don't know what is the scale...(we talk about bilions, milions hundreds?)

--Let's see if we sum the gross of the movies from 1991 from tabel disney_movies_total_gross the result will be the same like in the column Studio_Entertainment_NI_1 from table disney_revenue_1991_2016

SELECT SUM(total_gross)
FROM disney_movies_total_gross
WHERE release_date LIKE '1991%'  --unfortunatley we didn't find any similaritise between those so we won't be able to use this table

SELECT * FROM disney_characters
SELECT * FROM disney_director
SELECT * FROM disney_voice_actors

--Let's analyse further, let's see how many directors were involved in making these movies

WITH movies_with_directors
AS
(
	SELECT dm.*, 	
		   dd.director director
	FROM disney_movies_total_gross dm
	JOIN disney_director dd
		ON dm.movie_title = dd.name
)SELECT movie_title, release_date, director, total_gross, inflation_adjusted_gross
FROM movies_with_directors
ORDER BY director, release_date --if we match these after name, than the newer movies with the same title will have the same directors even if the period between them are decades
                                --this will need some aditional data cleaning before jumping in vizualizations
								


SELECT COUNT(DISTINCT movie) FROM disney_voice_actors

SELECT COUNT(DISTINCT movie_title) FROM disney_movies_total_gross

SELECT * FROM disney_voice_actors

SELECT dv.*,
	   dd.director,
	   dm.release_date,
	   dm.total_gross,
	   dm.inflation_adjusted_gross,
FROM disney_movies_total_gross dm
JOIN disney_voice_actors dv
	ON dm.movie_title = dv.movie
JOIN disney_director dd
	ON dm.movie_title = dd.name
ORDER BY 4   --because the primary key from disney_movies_total_gross table isn't a foreign key in tables like disney_director, disney_voice_actors it's hard to match what actor was a voice
			 --for a character so these isn't leading us anywhere :)

-- Because of those deadends I would like to segment my timeframe to see how each genre performs

WITH time_segmentation_1
AS
(
	SELECT *,
		   CASE WHEN release_date BETWEEN '1937-01-01' AND '1959-12-31' THEN '30`-50`'
				WHEN release_date BETWEEN '1960-01-01' AND '1979-12-31' THEN '60`-70`'
				WHEN release_date BETWEEN '1980-01-01' AND '1999-12-31' THEN '80`-90`'
		   ELSE 'now' END as time_period 
	FROM disney_movies_total_gross
)SELECT time_period, genre, COUNT(id) no_of_movies, SUM(inflation_adjusted_gross) total_earnings, SUM(inflation_adjusted_gross)/COUNT(id) avg_earning_per_movie
INTO time_seg_1
FROM time_segmentation_1
GROUP BY time_period, genre
ORDER BY total_earnings DESC  --this are some important stuff here

SELECT * FROM time_seg_1
ORDER BY 4 DESC

WITH time_segmentation_2
AS
(
	SELECT *,
		   CASE WHEN release_date BETWEEN '1937-01-01' AND '1959-12-31' THEN '30`-50`'
				WHEN release_date BETWEEN '1960-01-01' AND '1979-12-31' THEN '60`-70`'
				WHEN release_date BETWEEN '1980-01-01' AND '1999-12-31' THEN '80`-90`'
		   ELSE 'now' END as time_period 
	FROM disney_movies_total_gross
)SELECT time_period, COUNT(id) no_of_movies, SUM(inflation_adjusted_gross) total_earnings, SUM(inflation_adjusted_gross)/COUNT(id) avg_earning_per_movie
INTO time_seg_2
FROM time_segmentation_2
GROUP BY time_period
ORDER BY total_earnings DESC

SELECT * FROM time_seg_2

--Let's see how directors performed among time periods and in what genres they are good 
WITH movies_with_directors
AS
(
	SELECT dm.*, 
		   CASE WHEN dm.release_date BETWEEN '1937-01-01' AND '1959-12-31' THEN '30`-50`'
			    WHEN dm.release_date BETWEEN '1960-01-01' AND '1979-12-31' THEN '60`-70`'
			    WHEN dm.release_date BETWEEN '1980-01-01' AND '1999-12-31' THEN '80`-90`'
		   ELSE 'now' END as time_period ,
		   dd.director director
	FROM disney_movies_total_gross dm
	JOIN disney_director dd
		ON dm.movie_title = dd.name
)SELECT movie_title, release_date, director, genre, total_gross, inflation_adjusted_gross, time_period
FROM movies_with_directors
ORDER BY director, release_date



--========================	Conclusions	==============================
/*

	1. From what I see the genres (musical, adventure, drama, comedy) with a timeframe bigger than 53 years return a higher total_gross and this  is due to
	   the success of the animated movies like Snow White, Pinocchio, Fantasia, The Jungle Book, Lady and the Tramp, Cinderella, 101 Dalmatioans, Alladin etc.

	1.a. After the time segmentation I discovered that the adventure genre in our period (now), performed the best regarding earnings
	     Musical genre even if is in the top three earning genres is irrelevant for our period, because the earnings were made in period 30'-50'
		 Comedy genre has relevant results because is in top 5 earning genres twice (2nd period 80'-90', 5th period now )
		 Drama genre is relevant too because made it to the Top 10

	2. For the genres (action, horror, thriller, romantic, western, other, documentary, black comedy, concert performance) with a timeframe smaller than 34 years the success came from 
	   the movies with actors like Avengers, Pretty Woman etc.

	2.a After the segmentation the only mentionable genre will be Action (time period now) is the only one that made it to the top 10 
	    Genres like Horror, Black Comedy (time period now, 80'-90') are in the back of our list

	3. Majority of movies are part of the adventure, comedy, drama which is somehow normal because these genres have the longest time frame

	4. From what I see Action genre is a rising star because it was placed 5th ranking by the total_gross after the adventure, comedy, musical and drama genres
*/

--========================	Recommendations	==============================
/*

	1. Adventure and Comedy are registering great success (period now and 80'-90') so it's worth investing in creating movies in these areas (somehow in this manner we are playing safe) 	

	2. For the future I will recommend the focus to be on the Action genre (it's a rising star) 

	3. Musical genre was registering great succes in the 30'-50', now is in the middle of our classament, so in this case is an outlier in our analysis