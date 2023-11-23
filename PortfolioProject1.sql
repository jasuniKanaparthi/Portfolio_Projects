Select * from PortfolioProject..CovidDeaths
order by 3,4


Select * from PortfolioProject..CovidVaccinations
order by 3,4

Select Location, Date, total_cases, new_cases, total_deaths, population 
From PortfolioProject ..CovidDeaths
order by 1,2

DECLARE @TableName NVARCHAR(255) = 'CovidDeaths'; 

DECLARE @SqlStatement NVARCHAR(MAX) = N'';

SELECT @SqlStatement = @SqlStatement + 
    'UPDATE ' + @TableName + ' SET ' + QUOTENAME(name) + ' = NULLIF(' + QUOTENAME(name) + ', '''');' + CHAR(13)
FROM sys.columns
WHERE object_id = OBJECT_ID(@TableName);


PRINT @SqlStatement;

EXEC sp_executesql @SqlStatement;


Select Location, Date, total_cases, total_deaths, CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0) * 100 as DeathPercentage 
From PortfolioProject ..CovidDeaths
where location like '%India%'
order by 1,2

Select Location, Date, total_cases, population, CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0) * 100 as PercentPopulationInfected 
From PortfolioProject ..CovidDeaths
--where location like '%India%'
order by 1,2

Select Location, population, MAX(total_cases) as HighestInfectionCount, Max(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 as PercentPopulationInfected 
From PortfolioProject ..CovidDeaths
--where location like '%United Kingdom%'
Group by location, population
order by PercentPopulationInfected desc

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject ..CovidDeaths
--where location like '%India%'
Where continent is not null
Group by location
order by TotalDeathCount desc

--1.
Select  Sum(cast(new_cases as int)) as total_cases, 
		Sum(cast(new_deaths as int)) as total_deaths,
		sum(cast(new_deaths as int))/SUM(cast(new_cases as float))*100 as DeathPercentage
From PortfolioProject ..CovidDeaths
where continent is not NULL
order by 1, 2


Select dea.continent, dea.location, dea.date, dea.population, Nullif(vac.new_vaccinations,0) as new_vaccinations,
 SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
	From PortfolioProject ..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
		on dea.location= vac.location
		and dea.date=vac.date
	where dea.continent is not NULL
	Order by 2,3 asc

--CTE 
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, Nullif(vac.new_vaccinations,0) as New_vaccinations,
 SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
	From PortfolioProject ..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
		on dea.location= vac.location
		and dea.date=vac.date
	where dea.continent is not NULL
)
Select * ,CAST(RollingPeopleVaccinated as Float)/Population*100 as Percentage
From PopvsVac;


--TEMP TABLE

DROP Table if exists PerecentPopulationVaccinated
Create Table #PerecentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric,
Percentage numeric
)
Insert into #PerecentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, Nullif(vac.new_vaccinations,0) as New_vaccinations,
 SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
	From PortfolioProject ..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
		on dea.location= vac.location
		and dea.date=vac.date
	where dea.continent is not NULL

Select * ,CAST(RollingPeopleVaccinated as Float)/Population*100 as Percentage
From #PerecentPopulationVaccinated;

-- Creating View to store data for later visualizations

USE PortfolioProject
GO
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

