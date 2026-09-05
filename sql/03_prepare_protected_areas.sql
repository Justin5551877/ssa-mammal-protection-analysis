Prepare protected-area coverage for Sub-Saharan Africa.


-- Inspect the three imported WDPA polygon datasets
SELECT
    'part_0' AS dataset,
    COUNT(*) AS records
FROM protected_areas_0

UNION ALL

SELECT
    'part_1',
    COUNT(*)
FROM protected_areas_1

UNION ALL

SELECT
    'part_2',
    COUNT(*)
FROM protected_areas_2

ORDER BY dataset;


-- Combine the WDPA polygon datasets
CREATE TABLE protected_areas_global AS

SELECT *
FROM protected_areas_0

UNION ALL

SELECT *
FROM protected_areas_1

UNION ALL

SELECT *
FROM protected_areas_2;


-- Spatial index for faster spatial queries
CREATE INDEX protected_areas_global_geom_idx
ON protected_areas_global
USING GIST (geom);


-- Extract protected areas intersecting Sub-Saharan Africa
CREATE TABLE ssa_protected_areas_raw AS
SELECT
    pa.*
FROM protected_areas_global pa
JOIN ssa_boundary s
    ON ST_Intersects(pa.geom, s.geom);


CREATE INDEX ssa_protected_areas_raw_geom_idx
ON ssa_protected_areas_raw
USING GIST (geom);


-- Inspect realm/status combinations before filtering
SELECT
    realm,
    status,
    COUNT(*) AS protected_areas
FROM ssa_protected_areas_raw
GROUP BY
    realm,
    status
ORDER BY
    realm,
    status;


-- Retain qualifying terrestrial protected areas
CREATE TABLE ssa_protected_areas AS
SELECT *
FROM ssa_protected_areas_raw
WHERE realm = 'Terrestrial'
  AND status IN ('Designated', 'Inscribed');


Clip protected areas to SSA, collect them and dissolve overlaps
so the same land is not counted multiple times.


CREATE TABLE ssa_protected_coverage AS
SELECT
    ST_UnaryUnion(
        ST_Collect(
            ST_Intersection(pa.geom, s.geom)
        )
    ) AS geom
FROM ssa_protected_areas pa
CROSS JOIN ssa_boundary s;


-- Validate dissolved protected-area geometry
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_IsValid(geom) AS valid,
    ST_IsEmpty(geom) AS empty
FROM ssa_protected_coverage;
