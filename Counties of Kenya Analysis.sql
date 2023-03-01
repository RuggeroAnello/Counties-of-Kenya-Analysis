/*  
This analysis aims to gain insight on the differences among counties in Kenya. 
Data is collected from Kenya National Bureau of Statistics.
The dataset consists of three tables: Gross_County_Product, Population and Education.
These contain social and economic informations on the 47 counties of Kenya. */


-- Returns all data collected in the abovementioned tables.

SELECT	*
FROM
		dbo.education e 
		INNER JOIN gross_county_product g 
		ON e.administrative_unit_regionId = g.administrative_unit_regionId
		INNER JOIN population p
		ON e.administrative_unit_regionId = p.administrative_unit_regionId;


-- Returns the total number of counties stored in the dataset.

SELECT 
		COUNT(DISTINCT g.administrative_unit_regionId) AS N_counties
FROM
		dbo.education e 
		INNER JOIN gross_county_product g 
		ON e.administrative_unit_regionId = g.administrative_unit_regionId
		INNER JOIN population p
		ON e.administrative_unit_regionId = p.administrative_unit_regionId
WHERE
		g.administrative_unit_regionId != 'KE';


-- Returns counties with the highest Gross County Product (GCP) in 2020 in constant prices. 

SELECT 
		administrative_unit_name AS County,
		administrative_unit_regionId AS County_Id,
		_2020 AS 'Income2020'
FROM 
		gross_county_product
WHERE
		table_name LIKE '%Constant%' AND
		administrative_unit_regionId != 'KE'
ORDER BY 
		_2020 DESC;


-- Stores counties GCP growth rate from 2014 to 2020 in a new table.

SELECT 
		administrative_unit_name AS County,
		administrative_unit_regionId AS County_Id,
		ROUND((_2020-_2014)/_2014, 4) AS GCP_growth_rate
INTO
		GCP_growth_rate_by_county
FROM 
		gross_county_product
WHERE 
		table_name LIKE '%Constant%' AND
		administrative_unit_name != 'KE';


-- Returns data collected in the new table. 

SELECT *
FROM 
		GCP_growth_rate_by_county
ORDER BY 
		GCP_growth_rate DESC;


-- Returns GCP data for the county of Nairobi City.

SELECT *
FROM 
		gross_county_product
WHERE
		Administrative_Unit_Name = 'Nairobi' AND
		table_name LIKE '%Constant%';

-- Its growth has found resistance for the two-year period 2019-2020.


-- Returns Nairobi City GCP growth rate from 2019 to 2020.

SELECT 
		administrative_unit_name AS County,
		ROUND((_2020 - _2019)/_2019, 4) AS 'Nairobi_growth_rate_2019-20'
FROM 
		gross_county_product
WHERE 
		administrative_unit_name = 'Nairobi' AND 
		table_name like '%Constant%';


-- Returns Kenya GCP growth rate from 2019 to 2020.
-- The goal is to see whether the whole nation has experienced the same trend.

SELECT 
		administrative_unit_name AS County,
		ROUND((_2020 - _2019)/_2019, 4) AS 'Kenya_growth_rate_2019-20'
FROM 
		gross_county_product
WHERE 
		administrative_unit_regionId = 'KE' AND 
		table_name LIKE '%Constant%';


-- Returns Kenya overall population (as of the 2019 census).

SELECT
		administrative_unit_name AS County,
		value AS Population
FROM 
		population 
WHERE 
		administrative_unit_name = 'Kenya' AND
		background_characteristic = 'Total Population';


-- Returns the number of inhabitants in Nairobi

SELECT 
		administrative_unit_name AS County,
		value AS Population
FROM 
		population
WHERE 
		administrative_unit_name = 'Nairobi City' AND 
		background_characteristic = 'Total Population';


-- Stores the number of inhabitants in the different counties in a temporary table. 

SELECT 
		administrative_unit_name AS County,
		value AS Population
INTO
		#population_by_county
FROM 
		population 
WHERE 
		background_characteristic = 'Total Population';


-- Returns data contained in the temporary table.

SELECT *
FROM
		#population_by_county
ORDER BY 
		population DESC;


-- Returns and ranks the percentage of national population which lives in the different counties

SELECT 
		RANK() OVER (ORDER BY population DESC) AS Ranking,
		County,
		Population,
		ROUND((CONVERT(float, population)/
		(SELECT CONVERT(float,population) 
		FROM #population_by_county 
		WHERE County = 'Kenya')),4) AS 'Population %'
FROM 
		#population_by_county
WHERE 
		County != 'Kenya';

/* 
Nairobi City is both Kenya's largest economy and most populated county.
It is possible obtain a "County GCP per capita" index by dividing each County GCP by its population. 
This would be a more accurate way to obtain the level of wealth of the different counties. 
2019 GCP data will be used for its relevance to the 2019 census.
In addition, GCP value is in millions of Kenyan shilling: 1KES is around 0,0079USD. */


-- Stores GCP per capita data of the different counties in a new table.

SELECT 
		p.administrative_unit_name AS County,
		g._2019 AS GCP,
		p.value AS Population,
		ROUND((CONVERT(float,g._2019*1000000)/CONVERT(float,p.value))*0.0079,4) AS GCP_per_capita
INTO
		GCP_per_capita_by_county
FROM 
		population p 
		INNER JOIN gross_county_product g
		ON p.administrative_unit_regionId = g.administrative_unit_regionId
WHERE 
		p.background_characteristic = 'Total Population' AND 
		g.table_name LIKE '%Constant%';


-- Returns data from the new table.

SELECT *
FROM 
		GCP_per_capita_by_county
ORDER BY 
		GCP_per_capita DESC;

-- Results show that Nairobi is also the richest city of Kenya and that there are other ten counties with a GCP per capita above national average.


-- Returns data from 'education' table.

SELECT *
FROM education;

/* 
The 'education' table contains the number of students enrolled in Primary or Secondary Education by county. 
The goal is to see whether there is a relationship between GCP growth rate and increase of student numbers from 2014 to 2020.
Only secondary level education data will be utilized, since it is more relevant to the matter. */
 

-- Stores the rate of increase of secondary level students from 2014 to 2020 by county in a new table.

SELECT 
		administrative_unit_name AS County,
		administrative_unit_regionId AS County_Id,
		_2014 AS Total_Students_2014,
		_2020 AS Total_Students_2020,
		ROUND((CONVERT(float,_2020) - CONVERT(float,_2014)) / CONVERT(float,_2014),4) AS N_students_increase_rate
INTO
		N_students_increase_rate_by_county
FROM 
		education
WHERE 
		school_name = 'Secondary';


-- Returns data contained in the new table.

SELECT *
FROM
		N_students_increase_rate_by_county
ORDER BY
		N_students_increase_rate DESC;
 

-- Returns the comparison between the students rate of increase ranking and the GCP growth rate ranking, both from 2014 to 2020 by county.

SELECT 
		s.County,
		RANK() OVER (ORDER BY s.N_students_increase_rate DESC) AS N_students_ranking,
		RANK() OVER (ORDER BY g.GCP_growth_rate DESC) AS GCP_growth_rate_ranking
FROM 
		N_students_increase_rate_by_county s
		INNER JOIN GCP_growth_rate_by_county g
		ON s.County_Id = g.County_Id
ORDER BY 
		N_students_ranking ASC;

/* After performing a rank regression for the two variables, results show that correlation coefficient is only 0,388 (moderate degree of correlation), 
but Significance F is lower than 0,01 (statistically significant relationship).  */
 
