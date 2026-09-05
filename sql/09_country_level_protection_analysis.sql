[[[
09_country_level_protection_analysis.sql

Purpose:
Calculate protected-area representation of threatened mammal
ranges within individual Sub-Saharan African countries and
produce a country-level summary for choropleth mapping in QGIS.

Main choropleth metric:
Number of threatened mammal species with <30% of their mapped
national range overlapping qualifying terrestrial protected areas.
============================================================ 


 ============================================================
1. INTERSECT SPECIES RANGES WITH COUNTRIES
============================================================

DROP TABLE IF EXISTS country_species_ranges CASCADE;

CREATE TABLE country_species_ranges AS
SELECT
    c.name AS country,
    m.id_no,
    m.sci_name,
    m.category,
    ST_Intersection(m.geom, c.geom) AS geom
FROM threatened_ssa_ranges m
JOIN ssa_countries c
    ON ST_Intersects(m.geom, c.geom)
WHERE NOT ST_IsEmpty(
    ST_Intersection(m.geom, c.geom)
);

CREATE INDEX country_species_ranges_geom_idx
ON country_species_ranges
USING GIST (geom);


/* Validate country-species combinations */

SELECT
    COUNT(*) AS country_species_combinations,
    COUNT(DISTINCT country) AS countries,
    COUNT(DISTINCT id_no) AS species
FROM country_species_ranges;


Species richness represented in each country 

SELECT
    country,
    COUNT(*) AS threatened_species
FROM country_species_ranges
GROUP BY country
ORDER BY threatened_species DESC;


 ============================================================
2. CALCULATE SPECIES RANGE AREA WITHIN EACH COUNTRY

Geometry is transformed from EPSG:4326 to World Mollweide
(ESRI:54009), an equal-area projection.

ST_Area returns m² after transformation.
Division by 1,000,000 converts m² to km².
============================================================ 

DROP TABLE IF EXISTS country_species_range_area CASCADE;

CREATE TABLE country_species_range_area AS
SELECT
    country,
    id_no,
    sci_name,
    category,

    ST_Area(
        ST_Transform(geom, 54009)
    ) / 1000000.0 AS country_range_km2,

    geom

FROM country_species_ranges;

CREATE INDEX country_species_range_area_geom_idx
ON country_species_range_area
USING GIST (geom);


/* Validate calculated areas */

SELECT *
FROM country_species_range_area
WHERE country_range_km2 <= 0
   OR country_range_km2 IS NULL;


/* Inspect largest national species-range intersections */

SELECT
    country,
    sci_name,
    category,
    ROUND(country_range_km2::numeric, 0) AS country_range_km2
FROM country_species_range_area
ORDER BY country_range_km2 DESC
LIMIT 20;


/* ============================================================
3. CALCULATE PROTECTED RANGE WITHIN EACH COUNTRY
============================================================ */

DROP TABLE IF EXISTS country_species_protection CASCADE;

CREATE TABLE country_species_protection AS
SELECT
    x.country,
    x.id_no,
    x.sci_name,
    x.category,
    x.country_range_km2,
    x.protected_km2,

    LEAST(
        100.0,
        x.protected_km2 /
        NULLIF(x.country_range_km2, 0) * 100.0
    ) AS protected_percent

FROM (
    SELECT
        r.country,
        r.id_no,
        r.sci_name,
        r.category,
        r.country_range_km2,

        ST_Area(
            ST_Transform(
                ST_Intersection(r.geom, p.geom),
                54009
            )
        ) / 1000000.0 AS protected_km2

    FROM country_species_range_area r
    CROSS JOIN ssa_protected_coverage p

) x;


/* ============================================================
4. VALIDATE COUNTRY-LEVEL PROTECTION CALCULATIONS
============================================================ */

/* Protected range should not materially exceed total range */

SELECT
    country,
    sci_name,
    country_range_km2,
    protected_km2,
    protected_percent
FROM country_species_protection
WHERE protected_km2 > country_range_km2
ORDER BY protected_percent DESC;


/* Percentages should remain between 0 and 100 */

SELECT *
FROM country_species_protection
WHERE protected_percent < 0
   OR protected_percent > 100;


/* Count country-species combinations with zero protection */

SELECT
    COUNT(*) AS zero_protection_combinations
FROM country_species_protection
WHERE protected_percent = 0;


/* Count combinations with less than 30% protection */

SELECT
    COUNT(*) AS below_30_percent_combinations
FROM country_species_protection
WHERE protected_percent < 30;


/* Inspect example results */

SELECT
    country,
    sci_name,
    category,
    ROUND(country_range_km2::numeric, 1) AS range_km2,
    ROUND(protected_km2::numeric, 1) AS protected_km2,
    ROUND(protected_percent::numeric, 2) AS protected_percent
FROM country_species_protection
ORDER BY protected_percent ASC
LIMIT 30;


/* ============================================================
5. AGGREGATE TO COUNTRY LEVEL
============================================================ */

DROP TABLE IF EXISTS country_protection_summary CASCADE;

CREATE TABLE country_protection_summary AS
SELECT
    country,

    COUNT(*) AS threatened_species,

    COUNT(*) FILTER (
        WHERE protected_percent < 30
    ) AS species_below_30,

    COUNT(*) FILTER (
        WHERE protected_percent = 0
    ) AS species_zero_protection,

    AVG(protected_percent)
        AS mean_protected_percent,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY protected_percent
        ) AS median_protected_percent

FROM country_species_protection
GROUP BY country;


/* Inspect country-level results */

SELECT
    country,
    threatened_species,
    species_below_30,
    species_zero_protection,
    ROUND(
        mean_protected_percent::numeric,
        2
    ) AS mean_protected_percent,
    ROUND(
        median_protected_percent::numeric,
        2
    ) AS median_protected_percent
FROM country_protection_summary
ORDER BY species_below_30 DESC;


/* ============================================================
6. CREATE QGIS-READY COUNTRY CHOROPLETH VIEW
============================================================ */

CREATE OR REPLACE VIEW country_protection_map AS
SELECT
    c.name AS country,

    COALESCE(
        s.threatened_species,
        0
    ) AS threatened_species,

    COALESCE(
        s.species_below_30,
        0
    ) AS species_below_30,

    COALESCE(
        s.species_zero_protection,
        0
    ) AS species_zero_protection,

    s.mean_protected_percent,
    s.median_protected_percent,

    c.geom

FROM ssa_countries c
LEFT JOIN country_protection_summary s
    ON c.name = s.country;


/* Check final map data */

SELECT
    country,
    threatened_species,
    species_below_30,
    species_zero_protection,
    ROUND(
        mean_protected_percent::numeric,
        2
    ) AS mean_protected_percent,
    ROUND(
        median_protected_percent::numeric,
        2
    ) AS median_protected_percent
FROM country_protection_map
ORDER BY species_below_30 DESC;


/* ============================================================
7. FINAL CSV EXPORT QUERIES

Run each query in pgAdmin and export the result grid as CSV.
Do not export geometry columns.
============================================================ */


/* ------------------------------------------------------------
CSV 1:
results/species_protection_summary.csv
------------------------------------------------------------ */

SELECT
    id_no,
    sci_name,
    category,
    ROUND(range_km2::numeric, 2) AS range_km2,
    ROUND(protected_km2::numeric, 2) AS protected_km2,
    ROUND(protected_percent::numeric, 2) AS protected_percent
FROM species_protection_results
ORDER BY protected_percent ASC,
         sci_name ASC;


/* ------------------------------------------------------------
CSV 2:
results/country_protection_summary.csv
------------------------------------------------------------ */

SELECT
    country,
    threatened_species,
    species_below_30,
    species_zero_protection,
    ROUND(
        mean_protected_percent::numeric,
        2
    ) AS mean_protected_percent,
    ROUND(
        median_protected_percent::numeric,
        2
    ) AS median_protected_percent
FROM country_protection_summary
ORDER BY species_below_30 DESC,
         country ASC;
