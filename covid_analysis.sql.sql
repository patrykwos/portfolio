--Data analysis for Poland

-- Percentage chance of dying in case of contract covid in Poland
SELECT date, location, total_cases, total_deaths, (total_deaths / total_cases) * 100 as death_percentage
FROM Portfolio.dbo.CovidData
WHERE location = 'Poland'
ORDER BY location, date

-- Percentage covid infection rate in Poland
SELECT date, location, total_cases, population, (total_cases / population) * 100 AS case_percentage
FROM Portfolio.dbo.CovidData
WHERE location = 'Poland'
ORDER BY location, date

-- Percentage increase in cases with number of tests performed in Poland
SELECT date, location, total_cases, (new_cases / NULLIF(total_cases - new_cases, 0) * 100) AS percentage_increase_of_cases, new_tests_smoothed
FROM Portfolio.dbo.CovidData
WHERE location = 'Poland'
ORDER BY location, date

--Data analysis for Europe

-- Shows the European countries with the highest percentage of cases of covid compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases / population)) * 100 AS percent_population_cases
FROM Portfolio.dbo.CovidData
WHERE continent = 'Europe'
GROUP BY Location, Population
ORDER BY percent_population_cases DESC

-- Shows the European countries with the highest percentage of covid deaths compared to population
SELECT location, population, MAX(CAST(total_deaths AS INT)) AS total_death_count,  MAX((CAST(total_deaths AS INT) / population)) * 100 AS percent_population_deaths
FROM Portfolio.dbo.CovidData
WHERE continent = 'Europe'
GROUP BY location, population
ORDER BY percent_population_deaths DESC

--Global data analysis

-- Calculated number of vaccinated people in each country compared to population
SELECT continent, location, date, population, new_vaccinations
, SUM(ISNULL(CONVERT(BIGINT, new_vaccinations), 0)) OVER (PARTITION BY location ORDER BY location, date) AS sum_vaccinated_people
FROM Portfolio.dbo.CovidData
WHERE continent is not null 
ORDER BY location, date

-- Calculated percentage of vaccinated people in each country compared to population (Common Table Expresion)
WITH VaccinatedPopulation (continent, location, date, population, new_vaccinations, sum_vaccinated_people)
AS
(
SELECT continent, location, date, population, new_vaccinations
, SUM(ISNULL(CONVERT(BIGINT, new_vaccinations), 0)) OVER (PARTITION BY location ORDER BY location, date) AS sum_vaccinated_people
FROM Portfolio.dbo.CovidData
WHERE continent is not null
)
SELECT *, (sum_vaccinated_people / population) * 100 AS percent_vaccinated_people
FROM VaccinatedPopulation

-- Calculated percentage of vaccinated people in each country compared to population (Temp Table)
DROP TABLE IF exists #VaccinatedPopulation
CREATE TABLE #VaccinatedPopulation
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
sum_vaccinated_people numeric
)

INSERT INTO #VaccinatedPopulation
SELECT continent, location, date, population, new_vaccinations
, SUM(ISNULL(CONVERT(BIGINT, new_vaccinations), 0)) OVER (PARTITION BY location ORDER BY location, date) AS sum_vaccinated_people
FROM Portfolio.dbo.CovidData
WHERE continent is not null

SELECT *, (sum_vaccinated_people / population) * 100
From #VaccinatedPopulation

-- Exporting data for visualisation
CREATE VIEW DeathPercentage AS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100 AS death_percentage
FROM Portfolio.dbo.CovidData
WHERE continent is not null 

CREATE VIEW TotalDeathsOnTheContinents AS
SELECT location, SUM(CAST(new_deaths AS INT)) AS total_deaths
FROM Portfolio.dbo.CovidData
WHERE continent is null 
and location not in ('World', 'European Union', 'International', 'Low income', 'High income', 'Lower middle income', 'Upper middle income')
GROUP BY location

CREATE VIEW PercentPopulationCases AS
SELECT location, population, MAX(total_cases) AS total_infection_count,  MAX((total_cases / population)) * 100 AS percent_population_cases
FROM Portfolio.dbo.CovidData
WHERE location not in ('World', 'European Union', 'International', 'Low income', 'High income', 'Lower middle income', 'Upper middle income')
GROUP BY Location, Population

CREATE VIEW PercentPopulationCasesWithDate AS
SELECT Location, Population, date, MAX(total_cases) AS total_infection_count,  MAX((total_cases / population)) * 100 AS percent_population_cases
FROM Portfolio.dbo.CovidData
GROUP BY Location, Population, date