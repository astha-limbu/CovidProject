/* COVID-19 DATA EXPLORATION */

SELECT `location`, `date`, `population`, `total_Cases`, `new_Cases`, `total_deaths`
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
ORDER BY 1,2
;

-- how many out of the population had covid every day for each country?
-- Total cases vs Population
SELECT `location`, `date`, `population`, `total_Cases`, 
(`total_cases`/`population`)*100 AS `PercentageOfPopulationInfected`
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
ORDER BY 1,2
;

-- of those cases how many lead to death everyday in each country?
-- Total deaths vs Total cases
SELECT `location`, `date`, `total_Cases`, `total_deaths`, 
CAST((`total_deaths`/`total_Cases`)*100 AS DECIMAL (10, 3)) AS `deathPercentage` 
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
ORDER BY 1,2
;

-- What was the highest number of cases each country had and how much of the population was affected?
-- Highest rate of population infected per country
SELECT `location`, `population`, 
MAX(`total_Cases`) AS `highestNumberOfCases`,
(MAX(`total_cases`))/(`population`)*100 AS `PercentageOfPopulationInfected`
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
GROUP BY `location`, `population`
ORDER BY `PercentageOfPopulationInfected` DESC
;

-- What was the highest death count for each country?
-- Highest death count per country
SELECT `location`,
MAX(CONVERT(`total_deaths`, UNSIGNED)) AS `highestDeathCount`
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
GROUP BY `location`
ORDER BY `highestDeathCount` DESC
;

-- What was the highest death count for each continent?
-- Highest death count per continent 
SELECT `location`,
MAX(CONVERT(`total_deaths`, UNSIGNED)) AS `highestDeathCount`
FROM `covidDeaths`
WHERE `continent` IS NULL
GROUP BY `location`
ORDER BY `highestDeathCount` DESC
;

-- Global numbers
-- How many cases is there globally and how many deaths have there been as of that date?
-- Totals cases and deaths recorded globally as of the given date
SELECT -- `date`,
SUM(`total_Cases`) AS `totalCasesGlobal`, 
SUM(`total_Deaths`) AS `totalDeathsGlobal`,
CONVERT((SUM(`total_Deaths`)/SUM(`total_Cases`))*100, DECIMAL (10,3)) AS `deathPercentage` 
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
-- GROUP BY `date`
ORDER BY 1
;

-- how many new cases is there daily and how many of these cases are fatal?
-- Total New cases and total new Death
SELECT `date`, 
SUM(`new_cases`) AS `totalNewCasesGlobal`,
SUM(`new_deaths`) AS `totalNewDeathsGlobal`,
CONVERT((SUM(`new_deaths`)/SUM(`new_cases`))*100, DECIMAL (10,3)) AS `deathPercentage` 
FROM `covidDeaths`
WHERE NOT `continent` IS NULL
GROUP BY `date`
ORDER BY 1
;

--  How much of the population has atleast one vaccination?
-- Total population vs vaccinations
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`people_vaccinated`,
CAST((vac.`people_vaccinated`/dea.`population`)*100 AS DECIMAL (10, 3)) `percentageVaccinated`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE NOT dea.`continent` IS NULL
ORDER BY 2,3
;

-- How many new vacciantion was done each day?
-- total population vs new vaccinations
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`new_vaccinations`,
SUM(vac.`new_vaccinations`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountNewVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.`location` = vac.`location`
AND dea.`date` = vac.`date`
WHERE NOT dea.`continent` IS NULL
ORDER BY 2,3
;

-- rollingCountNewVacciantions is an unknown column in fields list 
-- Common Table Expressions (CTE)
With cte_PopVsVac (`continent`, `location`, `date`, `population`, `new_vaccinations`, `rollingCountNewVacciantions`)
AS (
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`new_vaccinations`,
SUM(vac.`new_vaccinations`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountNewVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.`location` = vac.`location`
AND dea.`date` = vac.`date`
WHERE NOT dea.`continent` IS NULL)

-- use the CTE in the main query
Select *, CAST((`rollingCountNewVacciantions`/`Population`)*100 AS DECIMAL (10, 3)) AS `percentageNewlyVaccinated`
From cte_PopvsVac
;

-- How many people are fully vaccinated
-- total population vs full vaccinations
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`people_fully_vaccinated`,
SUM(vac.`people_fully_vaccinated`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountFullVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE NOT dea.`continent` IS NULL
ORDER BY 2,3
;

-- Temp table
DROP TABLE IF EXISTS tmp_table;
CREATE TEMPORARY TABLE tmp_table (
   `continent` VARCHAR(50),
   `location` VARCHAR(100),
   `date` DATE,
   `population` numeric,
   `people_fully_vaccinated` numeric,
   `rollingCountFullVacciantions` numeric
);
INSERT INTO tmp_table
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`people_fully_vaccinated`,
SUM(vac.`people_fully_vaccinated`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountFullVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE NOT dea.`continent` IS NULL
ORDER BY 2,3
;

Select *, CAST((`rollingCountFullVacciantions`/`Population`)*100 AS DECIMAL (10, 3)) AS `percentageNewlyVaccinated`
From tmp_table
;

-- Creating view for later visualisation 
CREATE VIEW peoplefullyVaccinated AS
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`people_fully_vaccinated`,
SUM(vac.`people_fully_vaccinated`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountFullVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE NOT dea.`continent` IS NULL
;

CREATE VIEW `newVaccinations` AS
SELECT dea.`Continent`,dea.`location`, dea.`date`, dea.`population`, vac.`new_vaccinations`,
SUM(vac.`new_vaccinations`) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS `rollingCountNewVacciantions`
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.`location` = vac.`location`
AND dea.`date` = vac.`date`
WHERE NOT dea.`continent` IS NULL
;