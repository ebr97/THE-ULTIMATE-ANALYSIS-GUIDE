use BellaBeat

-----------------
--Prepare phase--

--Are there issues with bias or credibility in this data?
SELECT * FROM weightLogInfo_merged$;
/*
there is no data that can tells us if users are male or females
we want onlly data for females for this analysis
so using weightLogInfo_merged i will only include in this analysis the id with a weight under 75 kg
because all other records with over 75 kg and a BMI between 18.5 and 25 are more higlhy to be men
*/

WITH WeightCTE AS(
SELECT * FROM weightLogInfo_merged$
)
DELETE FROM WeightCTE
WHERE WeightKg > 75
--I have the original data stored in .CSV file

--Are there any problems with the data?

SELECT * FROM minuteCaloriesNarrow_merged --on this table data begin with 12 April 2016
SELECT * FROM minuteCaloriesWide_merged   --on this table data begin with 13 April 2016
SELECT * FROM dailyActivity_merged$     
SELECT * FROM dailyCalories_merged$       
--because only in the Wide tables data begin with 13 April this tables won't be included in this analyze

SELECT DISTINCT id,
	   COUNT(ActivityDate) 
FROM dailyActivity_merged$  
GROUP BY id
HAVING COUNT(ActivityDate) = 31 --there are 21 users that record data on the entire period out of 33
							   --we will work only with this 21 users

WITH ActivityCTE AS(
	SELECT *,
		   COUNT(*) OVER( PARTITION BY id) ctn
	FROM dailyActivity_merged$
)
DELETE ActivityCTE
WHERE ctn <> 31 -- i get rid of the users that doesn't track progress on the entire period


-----------------
--Process Phase--Data Cleaning--


--checking for null values in all tables, although i will put the code only for those who have null values
SELECT * FROM weightLogInfo_merged$

ALTER TABLE weightLogInfo_merged$
DROP COLUMN Fat

--checking daily activities table to see any iregularities
SELECT * FROM dailyActivity_merged$

SELECT TotalDistance, TrackerDistance, LoggedActivitiesDistance, VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance total_per_cat
FROM dailyActivity_merged$
WHERE LoggedActivitiesDistance <> 0 --logged distance don't make any sense


ALTER TABLE dailyActivity_merged$
DROP COLUMN LoggedActivitiesDistance

UPDATE dailyActivity_merged$
SET TotalDistance = ROUND(TotalDistance, 2), TrackerDistance = ROUND(TrackerDistance, 2) --there are to many digit after "," so i round to only 2 digit after ","

UPDATE dailyActivity_merged$
SET VeryActiveDistance = ROUND(VeryActiveDistance, 2), ModeratelyActiveDistance = ROUND(ModeratelyActiveDistance, 2), LightActiveDistance = ROUND(LightActiveDistance,2)

SELECT TotalDistance, TrackerDistance,  VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance 
FROM dailyActivity_merged$
WHERE TotalDistance <> VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance --checking to see if there are irregularities in the distance
                                                                                           -- total distance should be equal with the sum of all three types of activity
																						   --that should be apply to tracker distance too

UPDATE dailyActivity_merged$
SET TotalDistance = VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance
WHERE TotalDistance <> VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance

UPDATE dailyActivity_merged$
SET TrackerDistance = VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance
WHERE TrackerDistance <> VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance


ALTER TABLE dailyActivity_merged$
ADD ActivityDay Date --we don't need a column datetime type, so I will replace with a column that is only date type

UPDATE dailyActivity_merged$
SET ActivityDay =  CAST(ActivityDate AS Date) -

ALTER TABLE dailyActivity_merged$
DROP COLUMN ActivityDate

SELECT VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes+SedentaryMinutes as total_daily_minutes 
FROM dailyActivity_merged$
WHERE VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes+SedentaryMinutes <> 1440 --there should be 1440 minutes in a day

UPDATE dailyActivity_merged$
SET SedentaryMinutes = 1440 - (VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes)

ALTER TABLE dailyActivity_merged$
DROP COLUMN SedentaryActiveDistance --this column don't make any sense and has values like 0 or 0,09.. and shouldn't impact our analysis that much

--checking for any irregularities in daily calories table

SELECT * FROM dailyCalories_merged$

ALTER TABLE dailyCalories_merged$
ADD ActivityDate date   --modifing datetime type to date only

UPDATE dailyCalories_merged$
SET ActivityDate = CAST(ActivityDay AS Date)

ALTER TABLE dailyCalories_merged$
DROP COLUMN ActivityDay

SELECT a.id,
	   a.ActivityDay, 
	   c.ActivityDate,
	   c.Calories,
	   a.Calories
FROM dailyActivity_merged$ a
JOIN dailyCalories_merged$ c
	ON a.id=c.id
WHERE a.Calories <> c.Calories AND a.ActivityDay = c.ActivityDate --there should be the same amount of calories burnt in both tables

--checking for any irregularities in daily intensities table
SELECT * FROM dailyIntensities_merged$

ALTER TABLE dailyIntensities_merged$
ADD ActivityDate Date  --changing from datetime type to date format

UPDATE dailyIntensities_merged$
SET ActivityDate = CAST(ActivityDay AS date)

ALTER TABLE dailyIntensities_merged$
DROP COLUMN ActivityDay

SELECT LightlyActiveMinutes+FairlyActiveMinutes+VeryActiveMinutes+SedentaryMinutes FROM dailyIntensities_merged$
WHERE LightlyActiveMinutes+FairlyActiveMinutes+VeryActiveMinutes+SedentaryMinutes <> 1440 --there should be 1440 minute in a day

UPDATE dailyIntensities_merged$
SET SedentaryMinutes = 1440 - (LightlyActiveMinutes+FairlyActiveMinutes+VeryActiveMinutes)

ALTER TABLE dailyIntensities_merged$
DROP COLUMN SedentaryActiveDistance

UPDATE dailyIntensities_merged$
SET VeryActiveDistance = ROUND(VeryActiveDistance, 2), ModeratelyActiveDistance = ROUND(ModeratelyActiveDistance, 2), LightActiveDistance = ROUND(LightActiveDistance,2) --too many digit after comma

--checking for any irregularities in daily Steps table

SELECT * FROM dailySteps_merged$

ALTER TABLE dailySteps_merged$
ADD ActivityDate Date  --changing from datetime type to date format

UPDATE dailySteps_merged$
SET ActivityDate = CAST(ActivityDay AS date)

ALTER TABLE dailySteps_merged$
DROP COLUMN ActivityDay

SELECT a.id, 
	   a.TotalSteps,
	   s.StepTotal
FROM dailyActivity_merged$ a
JOIN dailySteps_merged$ s
	ON a.id=s.id
WHERE a.TotalSteps <> s.StepTotal AND a.ActivityDay = s.ActivityDate --there should be the same amount of steps

--checking any irregularities in heart rate second table
SELECT * FROM heartrate_seconds_merged$

SELECT DISTINCT id FROM heartrate_seconds_merged$ --only 7 id

--checking any irregularities in sleep day nd weight info tables
SELECT * FROM sleepDay_merged$

ALTER TABLE sleepDay_merged$
ADD SleepDate  Date

UPDATE sleepDay_merged$
SET SleepDate = CAST(SleepDay AS Date)

ALTER TABLE sleepDay_merged$
DROP COLUMN SleepDay

SELECT DISTINCT id,COUNT(SleepDate) FROM sleepDay_merged$
GROUP BY id
HAVING COUNT(SleepDate) <> 31 

---weight table
SELECT * FROM weightLogInfo_merged$

ALTER TABLE weightLogInfo_merged$
ADD Day  Date

UPDATE weightLogInfo_merged$
SET Day = CAST(Date AS Date)

ALTER TABLE weightLogInfo_merged$
DROP COLUMN Date

UPDATE weightLogInfo_merged$
SET WeightKg=ROUND(WeightKg,2), WeightPounds=ROUND(WeightPounds,2), BMI=ROUND(BMI,1)

-------------------------------
--Analysing Data--

SELECT * FROM dailyActivity_merged$


---(1) Calories Burnt and hours of activity & (2) Calories Burnt and Km Travelled
--here we are looking to generate any corelation between calories, minutes and travelled distance
SELECT id, 
	   AVG(Calories) avg_daily_calories_burnt,
	   AVG(VeryActiveDistance+LightActiveDistance+ModeratelyActiveDistance) avg_km_travelled,
	   AVG(VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes) avg_minutes_activity,
	   AVG(VeryActiveMinutes+FairlyActiveMinutes+LightlyActiveMinutes)/60 avg_hours_activity
FROM dailyActivity_merged$ 
GROUP BY id --to see any corelation between amount of calories burnt, istance travelled, and minutes of activity
-----------------------------------------------------------------------------------------------------------------

---(3) Distance walked and Minutes per category (very, fairly, lightly, sedentary)
SELECT id,
	   AVG(VeryActiveMinutes) avg_very_active_minutes,
	   AVG(VeryActiveDistance) avg_very_active_km,
	   AVG(FairlyActiveMinutes) avg_fairly_active_minutes,
	   AVG(ModeratelyActiveDistance) avg_moderatly_active_km,
	   AVG(LightlyActiveMinutes) avg_lightly_active_minutes,
	   AVG(LightActiveDistance) avg_light_active_km
FROM dailyActivity_merged$
GROUP BY id--to see corelation between diiferent kinds of activity types and km travelled
------------------------------------------------------------------------------------------------------------------

---(4) corelation between Distance and Intensity
SELECT 
	id,
	AVG(LightlyActiveMinutes) avg_lightly_minutes,
	AVG(FairlyActiveMinutes) avg_fairly_minutes,
	AVG(VeryActiveMinutes) avg_very_minutes,
	AVG(LightActiveDistance) avg_lightly_distance,
	AVG(ModeratelyActiveDistance) avg_moderatly_distance,
	AVG(VeryActiveDistance) avg_very_distance
FROM dailyIntensities_merged$
GROUP BY id
-----------------------------------------------------------------------------------------------

--(5) Categories of user based on their average daily step count
WITH TypeOfUserCTE AS(	
	SELECT id, SUM(TotalSteps)/31 AS TotalStepsAvg
	FROM dailyActivity_merged$
	GROUP BY id
)
SELECT
    id,
	CASE
		WHEN TotalStepsAvg < 5000 THEN 'Sedentary'
		WHEN TotalStepsAvg BETWEEN 5001 AND 7500 THEN 'Lightly Active'
		WHEN TotalStepsAvg BETWEEN 7501 AND 10000 THEN 'Fairly Active'
		WHEN TotalStepsAvg> 10001 THEN 'Very Active'
	END AS type_of_user
INTO #TypeOfUserTEMP
FROM TypeOfUserCTE --to see categories of users based on their steps.

SELECT a.id, a.TotalSteps, a.TotalDistance, a.TrackerDistance, a.VeryActiveDistance, a.ModeratelyActiveDistance, a.LightActiveDistance,
	   a.VeryActiveMinutes, a.FairlyActiveMinutes, a.LightlyActiveMinutes, a.SedentaryMinutes, a.Calories, a.ActivityDay, t.type_of_user
INTO #dailyActivity_merged$
FROM dailyActivity_merged$ a
JOIN #TypeOfUserTEMP t
	ON a.id=t.id

SELECT * FROM #dailyActivity_merged$ --final table with type of user for all id

SELECT COUNT(DISTINCT id), type_of_user FROM #dailyActivity_merged$
GROUP BY type_of_user


------------------------------------------------------------------------------------------

--(6) Calories burnt per type of user
SELECT  id, AVG(Calories) avg_calories, type_of_user 
INTO #CaloriesPerUserType
FROM #dailyActivity_merged$
GROUP BY id, type_of_user

SELECT AVG(avg_calories), type_of_user FROM #CaloriesPerUserType
GROUP BY type_of_user
--------------------------------------------------------------------------------------------

--(7) Sleep per type of user
SELECT * FROM sleepDay_merged$

SELECT  a.type_of_user, AVG(s.TotalMinutesAsleep)/60
FROM #dailyActivity_merged$ a
JOIN sleepDay_merged$ s
	ON a.id=s.id
GROUP BY type_of_user
---------------------------------------------------------------------------------------------

--(8) Activity per workday
SELECT 
	*,
	CASE
		WHEN ActivityDay IN ('2016-04-18', '2016-04-25', '2016-05-02', '2016-05-09') THEN 'Monday'
		WHEN ActivityDay IN ('2016-04-12', '2016-04-19', '2016-04-26', '2016-05-03', '2016-05-10') THEN 'Tuesday'
		WHEN ActivityDay IN ('2016-04-13', '2016-04-20', '2016-04-27', '2016-05-04', '2016-05-11') THEN 'Wednesday'
		WHEN ActivityDay IN ('2016-04-14', '2016-04-21', '2016-04-28', '2016-05-05', '2016-05-12') THEN 'Thursday'
		WHEN ActivityDay IN ('2016-04-15', '2016-04-22', '2016-04-29', '2016-05-06') THEN 'Friday'
		WHEN ActivityDay IN ('2016-04-16', '2016-04-23', '2016-04-30', '2016-05-07') THEN 'Saturday'
		WHEN ActivityDay IN ('2016-04-17', '2016-04-24', '2016-05-01', '2016-05-08') THEN 'Sunday'
	END workday
INTO #workday
FROM #dailyActivity_merged$

SELECT 
	AVG(VeryActiveMinutes)/60+AVG(FairlyActiveMinutes)/60+AVG(LightlyActiveMinutes)/60 avg_activity,
	workday
FROM #workday
GROUP BY workday
------------------------------------------------------------------------------------

--(9) Sleep per workday
SELECT w.workday, s.TotalMinutesAsleep/60 hours_of_sleep
INTO #sleepWorkday
FROM #workday w
JOIN sleepDay_merged$ s
	ON w.id=s.id AND w.ActivityDay=s.SleepDate

SELECT workday, AVG(hours_of_sleep) avg_hours_of_sleep FROM #sleepWorkday
GROUP BY workday
------------------------------------------------------------------------------------

--(10)To see corelation between minutes asleep and total time in bed
SELECT id, AVG(TotalMinutesAsleep)/60, AVG(TotalTimeInBed)/60, SleepDate FROM sleepDay_merged$ 
GROUP BY id, SleepDate

--(11)Relationship (if any) between sleep and activity time
SELECT a.id,
       a.type_of_user,
	   a.VeryActiveMinutes + a.FairlyActiveMinutes+a.LightlyActiveMinutes as activity,
	   s.TotalMinutesAsleep,
	   s.SleepDate
FROM #dailyActivity_merged$ a
JOIN sleepDay_merged$ s
	ON a.id = s.id AND a.ActivityDay = s.SleepDate

--(12)Steps Count
SELECT ROUND(AVG(TotalSteps),0) steps, type_of_user FROM #dailyActivity_merged$
GROUP BY type_of_user

SELECT ROUND(AVG(TotalSteps),0) steps FROM #dailyActivity_merged$

 --(13) Sedentary time
 SELECT AVG(SedentaryMinutes)/60 FROM #dailyActivity_merged$



