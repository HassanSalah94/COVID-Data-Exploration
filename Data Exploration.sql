--Selecting the needed data to be used from the covid deaths table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

--Showing death percentage of total infected cases in EGYPT per day

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location LIKE ('%egypt%')
ORDER BY location, date

--Showing the percentage of population that got infected

SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_population_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

--Showing countries with highest infection rate compared to population

SELECT location, MAX(total_cases) AS highest_cases, population, (MAX(total_cases)/population)*100 AS highest_cases_population_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_cases_population_percentage DESC

--Showing countries with most deaths

SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_deaths DESC

--Showing continents with the highest deaths

SELECT continent, MAX(CAST(total_deaths AS INT)) AS highest_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_deaths DESC

--GLobal numbers per day

SELECT date, SUM(new_cases) AS total_cases_per_day, SUM(CAST(new_deaths AS INT)) AS total_deaths_per_day, (SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100) AS total_deaths_percentage_per_day
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--Total numbers across the world
SELECT SUM(new_cases) AS total_world_cases, SUM(CAST(new_deaths AS INT)) AS total_world_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100) AS total_deaths_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--joining covid deaths table with covid vaccinations table

SELECT *
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date

--Showing  new vaccinated people compared to population in each country per day

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.continent, d.location, d.date

--Rolling adding for vaccinated people (USING SUM OVER PARTITION BY)

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_vaccinated
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.continent, d.location, d.date

--Counting total vaccinated people in each country (USING GROUP BY)

SELECT d.location, SUM(CONVERT(INT, v.new_vaccinations)) AS total_vaccinated_per_location
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location
ORDER BY d.location

--Counting total vaccinated people arround the world per day (USING GROUP BY)

SELECT d.date, SUM(CONVERT(INT, v.new_vaccinations)) AS total_vaccinated_per_day
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.date
ORDER BY d.date

--using CTE 

WITH vaccinatedPeople (continent, location, date, population, new_vaccinations, rolling_sum_vaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_vaccinated
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (rolling_sum_vaccinated/population) *100 AS sum_vaccinated_percentage
FROM vaccinatedPeople
ORDER BY location, date 

--using TEMP Tables

DROP TABLE IF EXISTS #TotalVaccinatedPercentage
CREATE TABLE #TotalVaccinatedPercentage
(
continent VARCHAR(50),
location VARCHAR(50),
date DATETIME,
population FLOAT,
new_vaccinations FLOAT,
rolling_sum_vaccinated FLOAT
)
INSERT INTO #TotalVaccinatedPercentage
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_vaccinated
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (rolling_sum_vaccinated/population) *100 AS sum_vaccinated_percentage
FROM #TotalVaccinatedPercentage
ORDER BY location, date

--Creating view to store data for later visualizations

USE PortfolioProject
GO
CREATE VIEW SumVaccinatedPercentage AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_vaccinated
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL


