-- Let's do this, goooooo...
-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
SELECT	*	FROM schools;
SELECT	*	FROM school_details; 
-- TASK 2: In each decade, how many schools were there that produced players? [Numeric Functions]
SELECT 	FLOOR(yearID / 10) * 10 AS decade, COUNT(DISTINCT schoolID) AS num_schools
FROM	schools
GROUP BY decade
ORDER BY decade;
-- 3. What are the names of the top 5 schools that produced the most players?
WITH SSD AS (SELECT sd.name_full, s.playerID
			 FROM	schools s
			 LEFT JOIN school_details sd
					 USING(schoolID))
SELECT	name_full, COUNT(DISTINCT playerID) AS player_counts
FROM	SSD
GROUP BY name_full
ORDER BY player_counts DESC
LIMIT	5;
-- HERE is another approach
SELECT	 sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
FROM	 schools s LEFT JOIN school_details sd
		 ON s.schoolID = sd.schoolID
GROUP BY s.schoolID
ORDER BY num_players DESC
LIMIT 	 5;

-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
WITH ds AS (SELECT	 FLOOR(s.yearID / 10) * 10 AS decade, sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
			FROM	 schools s LEFT JOIN school_details sd
					 ON s.schoolID = sd.schoolID
			GROUP BY decade, s.schoolID),
            
	 rn AS (SELECT	decade, name_full, num_players,
					ROW_NUMBER() OVER (PARTITION BY decade ORDER BY num_players DESC) AS row_num
                    /* ALTERNATIVE SOLUTION UPDATE: ROW_NUMBER will return exactly 3 schools for each decade. To account for ties,
                       use DENSE_RANK instead to return the top 3 player counts, which could potentially include more than 3 schools */
			FROM	ds)
            
SELECT	decade, name_full, num_players
FROM	rn
WHERE	row_num <= 3
ORDER BY decade DESC, row_num;

-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
SELECT	* FROM salaries;
-- 2. Return the top 20% of teams in terms of average annual spending
WITH ts AS (SELECT 	teamID, yearID, SUM(salary) AS total_spend
			FROM	salaries
			GROUP BY teamID, yearID
			ORDER BY teamID, yearID), -- ORDER BY in CTE is not needed and can be omitted
            
	 sp AS (SELECT	teamID, AVG(total_spend) AS avg_spend,
					NTILE(5) OVER (ORDER BY AVG(total_spend) DESC) AS spend_pct
			FROM	ts
			GROUP BY teamID)
SELECT	teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions
FROM	sp
WHERE	spend_pct = 1;
-- 3. For each team, show the cumulative sum of spending over the years
WITH team_yr_spent AS (SELECT	teamID, yearID, SUM(salary) AS total_salary
					   FROM		salaries
					   GROUP BY teamID, yearID
					   ORDER BY teamID),
	 cum_sum AS (SELECT	*,
						ROW_NUMBER() OVER(PARTITION BY teamID ORDER BY yearID) AS row_num,
						ROUND(SUM(total_salary) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000, 1)
			            AS cumulative_sum_millions
			     FROM	team_yr_spent)

SELECT	teamID, yearID, row_num, cumulative_sum_millions
FROM	cum_sum
;
-- better solution
WITH ts AS (SELECT	 teamID, yearID, SUM(salary) AS total_spend
			FROM	 salaries
			GROUP BY teamID, yearID
			ORDER BY teamID, yearID) -- ORDER BY in CTE is not needed and can be omitted
            
SELECT	teamID, yearID,
		ROUND(SUM(total_spend) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000, 1)
			AS cumulative_sum_millions
FROM	ts;
					
-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
WITH team_yr_spent AS (SELECT	teamID, yearID, SUM(salary) AS total_salary
					   FROM		salaries
					   GROUP BY teamID, yearID
					   ORDER BY teamID),
	 cum_sum AS (SELECT	*,
						ROUND(SUM(total_salary) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000, 1)
			            AS cumulative_sum_billions
			     FROM	team_yr_spent),
     rn AS (SELECT	teamID, yearID, cumulative_sum_billions,
		    ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY cumulative_sum_billions) AS rn
			FROM	cum_sum
			WHERE cumulative_sum_billions > 1000)
            
SELECT	teamID, yearID, cumulative_sum_billions
FROM	rn
WHERE	rn = 1;
-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
SELECT	*	FROM players;
SELECT	COUNT(DISTINCT playerID)
FROM	players;
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
SELECT 	nameGiven,
        TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), debut)
			AS starting_age,
		TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), finalGame)
			AS ending_age,
		TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM	players
ORDER BY career_length DESC;
-- 3. What team did each player play on for their starting and ending years?
SELECT 	p.nameGiven,
		s.yearID AS starting_year, s.teamID AS starting_team,
        e.yearID AS ending_year, e.teamID AS ending_team
FROM	players p INNER JOIN salaries s
							ON p.playerID = s.playerID
							AND YEAR(p.debut) = s.yearID
				  INNER JOIN salaries e
							ON p.playerID = e.playerID
							AND YEAR(p.finalGame) = e.yearID;
-- 4. How many players started and ended on the same team and also played for over a decade?
WITH PTC AS (SELECT 	p.nameGiven,
					s.yearID AS starting_year, s.teamID AS starting_team,
					e.yearID AS ending_year, e.teamID AS ending_team
			 FROM	players p INNER JOIN salaries s
										ON p.playerID = s.playerID
										AND YEAR(p.debut) = s.yearID
							  INNER JOIN salaries e
										ON p.playerID = e.playerID
										AND YEAR(p.finalGame) = e.yearID),
	  final_result AS (SELECT  *
					   FROM PTC
					   WHERE starting_team = ending_team 
							  AND ending_year - starting_year > 10)
SELECT COUNT(*)
FROM final_result;

-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
SELECT * FROM players;
-- 2. Which players have the same birthday?
WITH birthday AS (SELECT	nameGiven, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birthDate
                  FROM	players)
SELECT b.nameGiven, b.birthDate,
	   bd.nameGiven, bd.birthDate
FROM birthday b
		INNER JOIN birthday bd ON b.birthDate = bd.birthDate
WHERE	b.nameGiven <> bd.nameGiven
ORDER BY b.nameGiven;
-- better solution
WITH birthday AS (SELECT nameGiven, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birthDate
                  FROM players)
SELECT 
  b.nameGiven, b.birthDate,
  bd.nameGiven, bd.birthDate
FROM birthday b
INNER JOIN birthday bd 
  ON b.birthDate = bd.birthDate
 AND b.nameGiven < bd.nameGiven   -- avoids duplicates
ORDER BY  b.nameGiven;


-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
SELECT  * -- DISTINCT bats 
FROM players;

WITH team_table AS (SELECT DISTINCT s.teamID, s.playerID, p.bats
				    FROM salaries s 
				    LEFT JOIN players p
				    ON s.playerID = p.playerID) 
SELECT teamID,
		ROUND(SUM(CASE WHEN bats = 'R' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_right,
        ROUND(SUM(CASE WHEN bats = 'L' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_left,
        ROUND(SUM(CASE WHEN bats = 'B' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_both
FROM	team_table
GROUP BY teamID;

-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
WITH hw AS (SELECT	FLOOR(YEAR(debut) / 10) * 10 AS decade,
					AVG(height) AS avg_height, AVG(weight) AS avg_weight
			FROM	players
			GROUP BY decade)
            
SELECT	decade,
		avg_height - LAG(avg_height) OVER(ORDER BY decade) AS height_diff,
        avg_weight - LAG(avg_weight) OVER(ORDER BY decade) AS weight_diff
FROM	hw
WHERE	decade IS NOT NULL;













