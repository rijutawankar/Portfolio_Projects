select* 
from Covid_Project..Covid_Deaths$

select location, date, total_cases, new_cases, total_deaths,new_deaths, population
from Covid_Project..Covid_Deaths$
order by location,date

--- total cases vs Total deaths

-- likelihood of dying if you contract covid in your country
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
-- DeathPercentage around the globe

select date,sum(new_cases) as total_cases, 
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

select* 
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date



-- Looking at total population vs Vaccination (totla number of perople in the world being vaccinated)

select dea.continent, dea.date, dea.population, vac.new_vaccinations
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
order by 2,3


-- rolling count of the new vaccinations count per day of the above question
select dea.continent, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccination as int)) over (partition by dea.location)
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
order by 2,3



-- Windows Function
-- The LAG function is used to show data from the preceding row or the table. 
-- When lining up rows the data is partitioned by country name and ordered by the data whn. 
-- That means that only data from Italy is considered. 

-- no of population total vaccinated against fully vaccinated for previous day
select dea.continent, dea.location, dea.date, dea.population,vac.total_vaccinations,
	lag(vac.people_fully_vaccinated,1,-1) over(partition by dea.location order by dea.date) as prev_day_fully_vaccinated
from Covid_Project..Covid_Deaths$ dea
join Covid_Project..Covid_Vaccination$ vac
	on dea.location = vac.location
	and dea.date =  vac.date
where dea.continent is not null
order by 2,3


--Weekly Data
--Show the number of new cases in India for each week - show Monday only.
select location, date, population, new_cases
from Covid_Project..Covid_Deaths$
where location = 'India' and
YEAR(date) = 2020 and DATEPART(WEEKDAY, date) = 2
order by 1,2


-- Ranking by the total number of deaths

select location, max(cast(total_deaths as int)) as death_count,
dense_rank() over(order by max(cast(total_deaths as int)) desc) as highest_rank 
from Covid_Project..Covid_Deaths$
where year(date) = 2020 and continent is not null
group by location
order by death_count desc


--For each country that has had at last 1000 new cases in a single day, show the date of the peak number of new cases.
select location, date, new_cases
from Covid_Project..Covid_Deaths$
where new_cases > 1000 and continent is not null
order by location, date



--Show date of the latest death count for each country:

WITH latest_deaths_data AS
   ( SELECT location,
            date,
            total_deaths,
            total_cases,
            ROW_NUMBER() OVER (PARTITION BY location ORDER BY date DESC) as rn
     FROM Covid_Project..Covid_Deaths$)
SELECT location,
            date,
            total_deaths,
            total_cases,
       rn
FROM latest_deaths_data
WHERE rn=1




-- rollup is used for the combinations of  group by clauses

SELECT continent,location, total_cases
FROM Covid_Project..Covid_Deaths$
--GROUP BY ROLLUP(continent, location);


-- How many confire covid cases on specific day
select continent,location,date,total_cases,
sum(total_cases) over(partition by location order by date desc) as running_total 
from Covid_Project..Covid_Deaths$
where continent is not null
--group by continent,location
--order by total_cases desc


-- use of CTE and case statements
--Calculate the daily percentage change in daily cases 
-- for country "India"

WITH new_cases_lag AS (
  SELECT
    continent,location, date, total_cases, new_cases,
    LAG(new_cases) OVER(
      PARTITION BY continent, location
      ORDER BY date
    ) AS new_cases_previous_day
  FROM Covid_Project..Covid_Deaths$
),
new_cases_precent_change AS (
  SELECT
    *,
    ROUND((new_cases - new_cases_previous_day) /  NULLIF(new_cases_previous_day, 0) * 100,0) AS percent_change
  FROM new_cases_lag
)
 
SELECT
  *,
  CASE
    WHEN percent_change > 0 THEN 'increase'
    WHEN percent_change = 0 THEN 'no change'
    ELSE 'decrease'
  END AS trend
FROM new_cases_precent_change
WHERE location = 'India';