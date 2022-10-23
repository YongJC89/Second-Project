-- Covid 19 Data Exploration 
-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


-- Preview data to ensure data is correct
SELECT * 
FROM Project..CovidDeaths2021
ORDER BY 3, 4

SELECT * 
FROM Project..CovidVaccinations2021
ORDER BY 3, 4

-- Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM Project..CovidDeaths2021
ORDER BY 1, 2

-- Look at total cases vs total deaths (can infer as probability of death if down with Covid-19)
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS percent_death
FROM Project..CovidDeaths2021
ORDER BY 1, 2

-- Look at total cases vs population (shows percentage of population contracted Covid-19)
SELECT location, date, total_cases, population, ((total_cases/population)*100) AS percent_infected
FROM Project..CovidDeaths2021
ORDER BY 1, 2

-- Look at countries with highest infection rate
SELECT location, MAX(total_cases) AS highest_infection, MAX((total_cases/population)*100) AS percent_infected_population
FROM Project..CovidDeaths2021	
GROUP BY location, population
ORDER BY percent_infected_population DESC

-- Look at countries with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_death
FROM Project..CovidDeaths2021	
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death DESC

-- Looking at continent with highest death count (selecting those data where location = continent name and continent is NULL)
SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_death
FROM Project..CovidDeaths2021	
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death DESC

-- Total Global Numbers To Date (Total cases, death & death percentage)
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
(SUM(CAST(new_deaths AS INT))/SUM(New_Cases))*100 as death_percentage
FROM Project..CovidDeaths2021	
WHERE continent IS NOT NULL

-- Global Numbers Per Day (Total cases, death & death percentage)
SELECT date, SUM(new_cases) AS daily_total, SUM(CAST(new_deaths AS int)) AS daily_deaths, 
(SUM(CAST(new_deaths AS INT))/SUM(New_Cases))*100 as daily_death_percentage
FROM Project..CovidDeaths2021	
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Total Population, Daily New Vaccinated Numbers, Rolling Total Vaccinated Population 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_rolling
FROM Project..CovidDeaths2021 AS dea
JOIN Project..CovidVaccinations2021 AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform calculation on 'PARTITION BY' in previous query (extend table with Percentage Total Vaccinated Population)
WITH TVP (continent, location, date, population, new_vaccinations, vaccinated_rolling)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_rolling
From Project..CovidDeaths2021 AS dea
JOIN Project..CovidVaccinations2021 AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (vaccinated_rolling/population)*100 AS percent_vaccinated_rolling
FROM TVP

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PercentVaccinatedPopulation
CREATE TABLE PercentVaccinatedPopulation
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
percent_vaccinated_rolling NUMERIC
)

INSERT INTO PercentVaccinatedPopulation
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinated_rolling
FROM Project..CovidDeaths2021 AS dea
JOIN Project..CovidVaccinations2021 AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (percent_vaccinated_rolling/population)*100 AS percent_vaccinated_rolling
FROM PercentVaccinatedPopulation

-- Creating View to store data for later visualizations
CREATE VIEW view_PercentVaccinatedRolling AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS percent_vaccinated_rolling
FROM Project..CovidDeaths2021 AS dea
JOIN Project..CovidVaccinations2021 AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
