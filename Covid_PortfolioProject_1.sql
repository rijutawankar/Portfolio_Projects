select* 
from Covid_Project..Covid_Deaths$

select location, date, total_cases, new_cases, total_deaths,new_deaths, population
from Covid_Project..Covid_Deaths$
order by location,date

--- total cases vs Total deaths

-- likelihood of dying if you cintratc covid in your contyr
select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as DeathPercent
from Covid_Project..Covid_Deaths$
where location = 'India'
order by 1,2

-- Total cases vs population
--shows what percentage of population got covid
select location, date, total_cases, population, (total_deaths/population)* 100 as PopulationPercent
from Covid_Project..Covid_Deaths$
where location = 'India'
order by 1,2


-- Countries with highest infected rate compared to Populatio
select location, population, 
	max(total_cases) as HigehstInfection_Count,
	max((total_cases/population))* 100 as PopulationPercent_Infected

from Covid_Project..Covid_Deaths$
group by location, population
order by PopulationPercent_Infected desc


-- Showing countries with higesht death count per population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid_Project..Covid_Deaths$
where continent is not null
group by location
order by TotalDeathCount desc

-- BREAK THIS DOUM BY CONTINENT
-- showing continents with highest desth count per population
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from Covid_Project..Covid_Deaths$
where continent is not null
group by continent
order by TotalDeathCount desc

-- locationa and null continents(this are the correct numbers and not the above ones)
select location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid_Project..Covid_Deaths$
where continent is null
group by location
order by TotalDeathCount desc



-- GLOBAL NUMBERS

select date, sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases)* 100 as DeathPercentage
from Covid_Project..Covid_Deaths$
--where location = 'India'
where continent is not null
group by date
order by 1,2

--Total Cases all over the world

select sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases)* 100 as DeathPercentage
from Covid_Project..Covid_Deaths$
--where location = 'India'
where continent is not null
--group by date
order by 1,2


-- VACCINATION DATA

select* 
from Covid_Project..Covid_Vaccination$

-- Join the covidDeath and covidVaccination Data

select * 
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date



-- Looking at total population vs Vaccination (total number of perople in the world being vaccinated)

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
order by 1,2,3


-- rolling count of the new vaccinations count per day of the above question
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(convert(bigint, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as rolling_count_vac   -- sum(convert(int, vac.new_vaccination)) 
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
order by 2,3



-- USE CTE
-- vaccination over population

with PopvsVac (Continent, Location, Date, population, New_Vaccinations, Rolling_count_vac)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(convert(bigint, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as rolling_count_vac   
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
)
select *, (Rolling_count_vac / population)*100 as PercentVaccinated
from PopvsVac

-- use Temporary Table

Drop Table if exists #PercentPopVaccinated
create table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_Count_vac numeric,
)

Insert into #PercentPopVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(convert(bigint, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as rolling_count_vac   
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null

select *, (Rolling_count_vac / population)*100 as PercentVaccinated
from #PercentPopVaccinated



-- Creating view to store data for later visualization

Create View PercentPopVac as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(convert(bigint, vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as rolling_count_vac   
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null


select *
from PercentPopVac