/*
Threatened Mammal Protected-Area Coverage in Sub-Saharan Africa

-- Check PostGIS installation
SELECT PostGIS_Version();


-- Inspect available African regional classifications
SELECT DISTINCT
    continent,
    region_un,
    subregion,
    region_wb
FROM countries
WHERE continent = 'Africa'
ORDER BY subregion, region_wb;


-- Create Sub-Saharan African country subset
CREATE TABLE ssa_countries AS
SELECT *
FROM countries
WHERE continent = 'Africa'
  AND subregion <> 'Northern Africa';


-- Combine country geometries into one study-area geometry
CREATE TABLE ssa_boundary AS
SELECT
    ST_UnaryUnion(ST_Collect(geom)) AS geom
FROM ssa_countries;


-- Validate study-area geometry
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_IsValid(geom) AS valid
FROM ssa_boundary;
