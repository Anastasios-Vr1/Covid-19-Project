/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Select the data that we are going to be staring with
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 1,2 



--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT  location, 
		ROUND(AVG(total_deaths/total_cases) *100,2) AS Likelihood_of_dying_from_covid19_per_country
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY location


--Total Cases vs Population
--Shows what percentage of population infected with Covid

SELECT location, 
		ROUND(MAX(total_cases/population) *100,2) AS Percentage_of_population_infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY location


--Countries with Highest Infection Rate compared to Population

SELECT Location, 
		Population, 
		MAX(total_cases) AS HighestInfectionCount, 
		ROUND(MAX(total_cases/population)*100,2) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Countries with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS int)) AS MaxDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MaxDeaths DESC


-- BREAKING THINGS DOWN BY CONTINENT


--Showing Continents with the Highest Death count

SELECT location, MAX(CAST(total_deaths AS int)) AS MaxDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MaxDeaths DESC



--GLOBAL NUMBERS

SELECT SUM(new_cases) AS Total_cases, 
	   SUM(cast(new_deaths AS int)) AS Total_deaths, 
	   ROUND((Sum(cast(new_deaths AS int))/SUM(new_cases))*100,2) AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Total Population vs Vaccinations
--Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT  dea.continent, 
		dea.location, 
		dea.date, 
		population, 
		vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Using CTE to perform Calculation on Partition By in previous query
--Finding the Percentage Of Rolling Vaccinations per Country

WITH PopvsVac (Continent, Location,Date, Population,new_vaccinations, RollingPeopleVaccinated) 
AS (
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		population, 
		vac.new_vaccinations, 
		SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT location, 
	  (RollingPeopleVaccinated/population)*100 AS Percentage_Of_Rolling_Vaccinations_per_Country
FROM PopvsVac


--Using the previous CTE PopvsVac with MAX() function
--Shows us the Max Percentage Of Vaccinations Each Country Performed so far

SELECT location, 
	   MAX(RollingPeopleVaccinated/population)*100 AS Max_Percentage_Of_Vaccinations_Conducted
FROM PopvsVac
GROUP BY location


--TEMP TABLE
--Using Temp Table to perform Calculation on Partition By in previous query


DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(250),
Location NVARCHAR(250),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		population, 
		vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


Select  Location, 
		ROUND((RollingPeopleVaccinated/Population)*100,2)  as PercentageOfRollingVaccinatedPerCountry 
From #PercentPopulationVaccinated

--Creating View to store data for later Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		population, 
		vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated
