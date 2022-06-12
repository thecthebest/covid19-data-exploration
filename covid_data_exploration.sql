/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select all data to explore
SELECT * FROM covid..['deaths']
WHERE continent is NOT NULL
ORDER BY 3,4;

-- select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM covid..['deaths']
WHERE continent is NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases VS Total Deaths
-- Shows likelihood of dying if you contracted covid in your country
SELECT location, date total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid..['deaths']
WHERE continent is NOT NULL
ORDER BY 1,2;

--Looking at Total Cases VS Population
--Show what percentage of population had covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM covid..['deaths']
WHERE continent is NOT NULL
ORDER BY 1,2;


--Looking at Countries with Highest Infection Rate compared to Population in decending order
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid..['deaths']
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


--Looking at Countries with Highest Death Count per Population in decending order
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM covid..['deaths']
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Looking at Continent with Highest Death Count per Population in decending order
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM covid..['deaths']
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


--Global Number
SELECT SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths AS int)) AS total_deaths, 
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM covid..['deaths']
WHERE continent is NOT NULL
ORDER BY 1,2;

-- Looking at deaths and vaccinations tables
-- Joining two tables deaths and vaccine
SELECT * 
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date;


-- Looking at Total Population Vs Vaccinations
-- Joining two tables deaths and vaccine
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(CONVERT(BIGINT, vaccinations.new_vaccinations)) 
OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3;


-- Looking at Number of vaccines given to people by date(every new vaccine is added)
-- Joining two tables deaths and vaccine
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(CONVERT(BIGINT, vaccinations.new_vaccinations)) 
OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3;


-- Looking at the percentage of the population vaccinated
-- Joining two tables deaths and vaccine and using CTE
WITH popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(CONVERT(BIGINT, vaccinations.new_vaccinations)) 
OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentangePopulationVaccinated FROM popvsvac;

-- Temp Table
-- Delete Table if availble in the database
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
-- Creating a new table
CREATE TABLE #PertangePopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
-- Inserting data into the table
INSERT INTO #PertangePopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(CONVERT(BIGINT, vaccinations.new_vaccinations))
OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
-- Looking at the data that was just inserted
SELECT *, (RollingPeopleVaccinated/population)*100 FROM #PertangePopulationVaccinated;


-- Creating View to store data for later visualizations
CREATE VIEW PertangePopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(CONVERT(BIGINT, vaccinations.new_vaccinations)) 
OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM covid..['deaths'] AS deaths
JOIN
covid..['vaccine'] AS vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL;