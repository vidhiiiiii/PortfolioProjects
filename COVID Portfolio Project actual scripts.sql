Select *
From PortfolioProject..CovidDeaths
Order By 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--Order By 3,4

------Selecting the data we need-----
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is NOT NULL
Order By 1,2

------Looking at Total cases  v/s Total Deaths (how much percentage of toatal cases died)-------
------Shows Likelihood of dying if you contract covid in your country-----
Select Location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where Location like '%ndia'
where continent is NOT NULL
Order By 1,2

------Looking at Total cases vs Population)---------
------Shows What percentage of people got Covid------

Select Location, date, Population, total_cases, (total_cases/Population)*100 as InfectedPopulationPercent
From PortfolioProject..CovidDeaths
--Where Location like '%ndia'
where continent is NOT NULL
Order By 1,2

-----Looking at countries & their Highest Infection Rate(perecentage) compared to Population----

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 as InfectedPopulationPercent
From PortfolioProject..CovidDeaths
--Where Location like '%ndia'
where continent is NOT NULL
Group By Location, Population
Order By InfectedPopulationPercent Desc

-----Showing countries with Highest Death Count per Population-----
-----Using cast to change the datatype because it was originally nvarchar.And Aggregrate functions won't work on it.

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where Location like '%ndia'
where continent is NOT NULL
Group By Location
Order By TotalDeathCount Desc

------LET'S BREAK DOWN THINGS & SHOW BY CONTINENT------
------Showing contitents with the highest death count per population-------
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where Location like '%ndia'
where continent is NOT NULL --AND Location NOT LIKE '%Income%'
Group By continent
Order By TotalDeathCount Desc

---GLOBAL NUMBERA--- 
-----(THis is showing/returning total covid cases & total deaths with death percent in all world daywise-----

Select date,SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,
       SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is NOT NULL --AND location NOT LIKE '%Income%'
Group By date
Order by 1,2

-----(THis is showing/returning total covid cases & total deaths with death percent in all world-----

Select SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,
       SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is NOT NULL --AND location NOT LIKE '%Income%'
Order by 1,2

----LOOKING AT THE TOTAL POPULATION VS TOTAL PEOPLE VACCINATED IN THE WORLD----
---(RollingPeopleVaccinated is for total people getting vaccinated , updating continuously)---
---****The convert statement is also for changing datatype & CRUCIAL STEP HERE OR ELSE IT SHOWS ERROR****---

SELECT Death.continent,Death.location,Death.date,Death.population,Vac.new_vaccinations,
       SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location,CONVERT(date,Death.date))
	   as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Death JOIN PortfolioProject..CovidVaccinations Vac
ON Death.location = Vac.location AND Death.date = Vac.date
WHERE Death.continent is NOT NULL
ORDER BY 2,3

----USING CTE....(we can use either a temptable or cte)
---(Because we can't usePollingPeopleVaccinated column to find percentage of people vaccinated in the uper query)---

With PopltnVsVacc (Continent,Location,Date,Population,NewVaccinations,RollingPeopleVaccinated)
as 
(
SELECT Death.continent,Death.location,Death.date,Death.population,Vac.new_vaccinations,
       SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location,CONVERT(date,Death.date))
	   as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Death JOIN PortfolioProject..CovidVaccinations Vac
ON Death.location = Vac.location AND Death.date = Vac.date
WHERE Death.continent is NOT NULL
)

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM PopltnVsVacc

----TEMP TABLE----

DROP TABLE IF exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT Death.continent,Death.location,Death.date,Death.population,Vac.new_vaccinations,
       SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location,CONVERT(date,Death.date))
	   as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Death JOIN PortfolioProject..CovidVaccinations Vac
ON Death.location = Vac.location AND Death.date = Vac.date
WHERE Death.continent is NOT NULL


Select *,(RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

----------CREATE VIEW TO STORE DATA FOR LATER VISUALISATION-----------

CREATE VIEW PercentPopulationVaccinated as
SELECT Death.continent,Death.location,Death.date,Death.population,Vac.new_vaccinations,
       SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location,CONVERT(date,Death.date))
	   as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Death JOIN PortfolioProject..CovidVaccinations Vac
ON Death.location = Vac.location AND Death.date = Vac.date
WHERE Death.continent is NOT NULL

/****NOW IT'S PERMANENT OR STORED.YOU CAN QUERY OUT OF IT****/

Select *
From PercentPopulationVaccinated