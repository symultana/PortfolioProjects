/*
SQL - data cleaning and preparation: solving the basic issues with the database.
*/


-----------------------------------------
-- Creating a copy of the table


CREATE TABLE tv_series_copy AS SELECT * FROM top_100;



-----------------------------------------
-- Breaking the Aired_Date column into two columns: with start and finish date


ALTER TABLE tv_series_copy
ADD Start_date varchar (40) NOT NULL
AFTER Aired_Date;

UPDATE tv_series_copy
SET Start_date= SUBSTRING_INDEX(Aired_Date, "-", 1);

ALTER TABLE tv_series_copy
ADD Finish_date varchar (50)
AFTER Start_date;

UPDATE tv_series_copy
SET Finish_date= SUBSTRING_INDEX(Aired_Date, "-", -1);

ALTER TABLE tv_series_copy
DROP COLUMN Aired_date;



-- Setting the Date Format


UPDATE tv_series_copy
SET Start_date= STR_TO_DATE(Start_date,'%b %e,%Y');

UPDATE tv_series_copy
SET Finish_date= STR_TO_DATE(Finish_date,'%b %e,%Y');



-- Deleting duplicates


Update tv_series_copy
SET Finish_date=NULL
WHERE Start_date=Finish_date;



-----------------------------------------
-- Ordering data by Ranking


SELECT *
FROM tv_series_copy
ORDER BY Ranking ASC;



-- Ordering by Ranking doesn't work. The column is set as a primary key and as a string column. Solving the problem


ALTER TABLE tv_series_copy
ADD Ranking_copy INTEGER UNIQUE;

UPDATE tv_series_copy
SET Ranking_copy=Ranking;

SELECT *
FROM tv_series_copy
order by Ranking_copy ASC;
ALTER TABLE k_drama_copy
DROP COLUMN Ranking;

ALTER TABLE tv_series_copy
RENAME COLUMN Ranking_copy TO Ranking;



-- Setting a Primary KEY


ALTER TABLE tv_series_copy
ADD PRIMARY KEY (Ranking);
  
SELECT *
FROM tv_series_copy
ORDER BY Ranking ASC;



-----------------------------------------
-- Each row in the Genre column contains several decimal values. Breaking the column into a table for later calculations
-- Creating table due to MySQL issue - that you cannot refer to a TEMPORARY table more than once in the same query


CREATE TABLE Genre_list
SELECT 
SUBSTRING_INDEX(Genre, ',', 1)
AS g_1,
SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 2), ',', -1)
AS g_2,
SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 3), ',', -1)
AS g_3,
(SELECT
SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 4), ',', -1)
WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 3), ',', -1)<>SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 4), ',', -1)
)
AS g_4,
(SELECT
SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 5), ',', -1)
WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 4), ',', -1)<>SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 5), ',', -1)
)
AS g_5,
(SELECT
SUBSTRING_INDEX(Genre,",",-1)
WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(Genre, ',', 5), ',', -1)<>SUBSTRING_INDEX(Genre,",",-1)
)
AS g_6,
Ranking
FROM tv_series_copy;

SELECT *
FROM Genre_list
ORDER BY Ranking;



-- Trimming Genre_list


 UPDATE Genre_list 
 SET g_1= LTRIM(RTRIM(g_1)),
 g_2= LTRIM(RTRIM(g_2)),
 g_3= LTRIM(RTRIM(g_3)),
 g_4= LTRIM(RTRIM(g_4)),
 g_5= LTRIM(RTRIM(g_5)),
 g_6= LTRIM(RTRIM(g_6));



-----------------------------------------
-- Counting which genres are the most popular


CREATE TEMPORARY TABLE sum_genre_occurrences
SELECT g_1, COALESCE(sum(count1),0) as count1, COALESCE(sum(count2),0) as count2, COALESCE(sum(count3),0) as count3, COALESCE(sum(count4),0) as count4, COALESCE(sum(count5),0) as count5, COALESCE(sum(count6),0) as count6
FROM 
(
   select g_1, count(*) as count1, null as count2, null as count3, null as count4, null as count5, null as count6 from Genre_list group by g_1
   union  
   select g_2, null, count(*), null, null, null, null from Genre_list group by g_2
   union 
   select g_3, null, null, count(*), null, null, null from Genre_list group by g_3
   union  
   select g_4, null, null, null, count(*), null, null from Genre_list group by g_4
   union  
   select g_5, null, null, null, null, count(*), null from Genre_list group by g_5
   union  
   select g_6, null, null, null, null, null, count(*) from Genre_list group by g_6
) tmp
GROUP BY g_1
ORDER BY g_1 ASC;


SELECT g_1, SUM(count1+count2+count3+count4+count5+count6) AS occurrences
FROM sum_genre_occurrences
WHERE g_1 IS NOT NULL
GROUP BY g_1
ORDER BY occurrences DESC;



-----------------------------------------
-- Counting which genres are the most popular among the top 15 tv series


CREATE TEMPORARY TABLE top_genre_occurrences
SELECT g_1, COALESCE(sum(count1),0) as count1, COALESCE(sum(count2),0) as count2, COALESCE(sum(count3),0) as count3, COALESCE(sum(count4),0) as count4, COALESCE(sum(count5),0) as count5, COALESCE(sum(count6),0) as count6
FROM 
(
   select g_1, count(*) as count1, null as count2, null as count3, null as count4, null as count5, null as count6 from Genre_list where Ranking <15 group by g_1
   union  
   select g_2, null, count(*), null, null, null, null from Genre_list where Ranking <15 group by g_2
   union 
   select g_3, null, null, count(*), null, null, null from Genre_list where Ranking <15 group by g_3
   union  
   select g_4, null, null, null, count(*), null, null from Genre_list where Ranking <15 group by g_4
   union  
   select g_5, null, null, null, null, count(*), null from Genre_list where Ranking <15 group by g_5
   union  
   select g_6, null, null, null, null, null, count(*) from Genre_list where Ranking <15 group by g_6
) tmp
GROUP BY g_1
ORDER BY g_1 ASC;


SELECT g_1, SUM(count1+count2+count3+count4+count5+count6) AS occurrences
FROM top_genre_occurrences
WHERE g_1 IS NOT NULL
GROUP BY g_1
ORDER BY occurrences DESC;



-----------------------------------------
-- Counting which genres are the most popular among the lowest rated tv series


SELECT Rating, Ranking FROM tv_series_copy
ORDER BY Ranking DESC;


CREATE TEMPORARY TABLE least_genre_occurrences
SELECT g_1, COALESCE(sum(count1),0) as count1, COALESCE(sum(count2),0) as count2, COALESCE(sum(count3),0) as count3, COALESCE(sum(count4),0) as count4, COALESCE(sum(count5),0) as count5, COALESCE(sum(count6),0) as count6
FROM 
(
   select g_1, count(*) as count1, null as count2, null as count3, null as count4, null as count5, null as count6 from Genre_list where Ranking >=80 group by g_1
   union  
   select g_2, null, count(*), null, null, null, null from Genre_list where Ranking >=80 group by g_2
   union 
   select g_3, null, null, count(*), null, null, null from Genre_list where Ranking >=80 group by g_3
   union  
   select g_4, null, null, null, count(*), null, null from Genre_list where Ranking >=80 group by g_4
   union  
   select g_5, null, null, null, null, count(*), null from Genre_list where Ranking >=80 group by g_5
   union  
   select g_6, null, null, null, null, null, count(*) from Genre_list where Ranking >=80 group by g_6
) tmp
GROUP BY g_1
ORDER BY g_1 ASC;


SELECT g_1, SUM(count1+count2+count3+count4+count5+count6) AS occurences
FROM least_genre_occurrences
WHERE g_1 IS NOT NULL
GROUP BY g_1
ORDER BY occurrences DESC;
