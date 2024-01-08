/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--Select the data that we are going to be staring with

Select location, date, total_cases, new_cases, total_deaths, population 
From PortfolioProject..CovidDeaths
Where continent is not null 
Order by 1,2


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

Select location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is Not Null and location like '%states%'
Order by 1,2


--Total Cases vs Population
--Shows what percentage of population infected with Covid

Select Location, Date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is Not Null
Order by 1,2


--Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is Not Null
Group by Location, Population
Order by PercentPopulationInfected desc


--Countries with Highest Death Count

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is Not Null
Group by Location 
Order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT


--Showing Continents with the Highest Death count

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is Not Null
Group by continent
Order by TotalDeathCount desc



--GLOBAL NUMBERS

Select SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, (Sum(cast(new_deaths as int))/Sum(new_cases))*100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is Not Null
Order by 1,2


--Total Population vs Vaccinations
--Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location= vac.location and dea.date=vac.date
Where dea.continent is Not Null
Order by 2,3


--Using CTE to perform Calculation on Partition By in previous query
--Finding the Percentage Of Rolling Vaccinations per Country

WITH PopvsVac (Continent, Location,Date, Population,new_vaccinations, RollingPeopleVaccinated) 
as
(
Select dea.continent, dea.location, dea.date, population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location= vac.location and dea.date=vac.date
Where dea.continent is Not Null
	)
Select *, (RollingPeopleVaccinated/Population)*100  as PercentageOfRollingVaccinatedPerCountry
From PopvsVac


--Using the previous CTE PopvsVac with MAX() function

Select Location, Max(RollingPeopleVaccinated)
From PopvsVac
Group by Location


--TEMP TABLE
--Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(250),
Location nvarchar(250),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location= vac.location and dea.date=vac.date
Where dea.continent is Not Null
Order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100  as PercentageOfRollingVaccinatedPerCountry 
From #PercentPopulationVaccinated




--Creating View to store data for later Visualizations

Create view PercentPopulationVaccinated as

Select dea.continent, dea.location, dea.date, population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location= vac.location 
	and dea.date=vac.date
Where dea.continent is Not Null
