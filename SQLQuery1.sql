

-- the data is a bit old, from 24.2.2020-30.4.2021




-- checking the vaccinations data

select *
from sqlTutorial..CovidVaccinations
where continent is not null
order by 3,4



-- both of the below have the same result except the second only selects specific columns


select *
from sqlTutorial..CovidDeaths
where continent is not null
order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from sqlTutorial..CovidDeaths
where continent is not null
order by 1,2


-- very rough estimate of your chances of dying if you got covid during different times

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathsPercent
from sqlTutorial..CovidDeaths
where location = 'Finland'
and continent is not null
order by 1,2

-- percentage of population with covid

select location, date, total_cases, population, (total_cases/population)*100 as popInfectedPercent
from sqlTutorial..CovidDeaths
order by 1,2

-- Andorra seems to have the most infected people compared to its population size at ~17%
-- maxInfected tells you the maximum amount of infected on some day

select location, population, MAX(total_cases) as maxInfected, max((total_cases/population))*100 as popInfectedPercent
from sqlTutorial..CovidDeaths
group by location, population
order by popInfectedPercent desc

-- countries ordered by most deaths 

select location, max(cast(Total_deaths as int)) as totalDeaths
from sqlTutorial..CovidDeaths
where continent is not null
group by location
order by totalDeaths desc


-- continents ordered by most deaths 

select location, max(cast(Total_deaths as int)) as totalDeaths
from sqlTutorial..CovidDeaths
where continent is null
group by location
order by totalDeaths desc

-- other ways to calculate the same variables as previously except now we get the global values

select sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totalDeaths,
       sum(cast(new_deaths as int))/sum(new_cases)*100 as deathPercent
from sqlTutorial..CovidDeaths
where continent is not null
order by 1,2

-- rollingVaccinated keeps track of all the covid vaccines that have been given up until that point in time in a specific location by adding them up
-- partition tells the query when to reset the rollingVaccinated

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.Date) as rollingVaccinated
from sqlTutorial..CovidDeaths dea
join sqlTutorial..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- doing additional calculation on previous query by using common table expression (CTE)
-- cte is a temporary named result set that you can reference later

with PopVac (continent, location, date, population, new_vaccinations, rollingVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.Date) as rollingVaccinated
from sqlTutorial..CovidDeaths dea
join sqlTutorial..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingVaccinated/population)*100 as vaccinatedPopPercent
from PopVac

-- utilizing temporary table to make calculations from the previous partition by query

drop table if exists #vaccinatedPopPercent
create table #vaccinatedPopPercent
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingVaccinated numeric
)

insert into #vaccinatedPopPercent
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.Date) as rollingVaccinated
from sqlTutorial..CovidDeaths dea
join sqlTutorial..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null

select *, (rollingVaccinated/population)*100
from #vaccinatedPopPercent


-- making a view, so we can use the data later for visualization

go
create view vaccinatedPopPercent
as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.Date) as rollingVaccinated
from sqlTutorial..CovidDeaths dea
join sqlTutorial..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null