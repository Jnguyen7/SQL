-- Dataset: https://catalog.data.gov/dataset/vaccination-coverage-among-health-care-personnel-b0240

SELECT season,
	SUBSTRING_INDEX(season, '-', -1) AS season_updated
 FROM vaccination;
 
 SELECT * FROM Vaccination;
 -- Select Data that we will start with
 
 SELECT Vaccine, 
	Geography, 
	SUBSTRING_INDEX(season, '-', -1) AS Season_updated,
    `Personnel Type`,
    `Estimate (%)` AS Estimate,
    `Sample Size`,
    tot
FROM vaccination
	WHERE `Geography Type` = 'States'
ORDER BY 2,3;

-- Finding total population size for each season
-- Shows total number of vaccinated health care personnel and health care employees during each collected season in the USA

ALTER TABLE vaccination
	ADD COLUMN tot FLOAT;
    
UPDATE vaccination
	SET tot = `Sample Size` * 100 / `Estimate (%)`;

SELECT CONCAT(20, SUBSTRING_INDEX(season, '-', -1)) AS Season_updated, Geography, ROUND(SUM(`tot`)) AS total_vaccinated,ROUND( ((SUM(`tot`)) * 100 / `Estimate (%)`) - (SUM(`tot`))) AS Not_vaccinated, ROUND((SUM(`tot`)) * 100 / `Estimate (%)`) AS Tot_Health_population
FROM vaccination
WHERE `Personnel Type` IN ('Employees', 'Adult Students/Trainees and Volunteers', 'Licensed Independent Practitioners')
GROUP BY Season_updated, Geography;

-- Shows total number of vaccinated health care personnel and health care employees during each collected season in the entire USA only compared to not vaccinated health care personnel and health care employees

SELECT SUBSTRING_INDEX(season, '-', -1) AS Season_updated, Geography, ROUND(SUM(`tot`)) AS total_vaccinated, ROUND( ((SUM(`tot`)) * 100 / `Estimate (%)`) - (SUM(`tot`))) AS Not_vaccinated, ROUND((SUM(`tot`)) * 100 / `Estimate (%)`) AS Tot_Health_population
FROM vaccination
WHERE `Personnel Type` IN ('Employees', 'Adult Students/Trainees and Volunteers', 'Licensed Independent Practitioners')
AND `Geography Type` = 'National'
GROUP BY Geography, Season_updated;
