Check coordinate reference systems and calculate species range
and protected-area coverage.


-- Inspect CRS of mammal range geometries
SELECT
    ST_SRID(geom)
FROM threatened_ssa_ranges
LIMIT 1;


Check whether local PostGIS recognises SRID 54009 as the intended
equal-area CRS before using it for area calculations.


SELECT
    srid,
    auth_name,
    auth_srid,
    srtext
FROM spatial_ref_sys
WHERE srid = 54009;


-- Calculate total SSA range and protected range for each species
CREATE TABLE species_protection AS
SELECT
    m.id_no,
    m.sci_name,
    m.category,

    ST_Area(
        ST_Transform(m.geom, 54009)
    ) / 1000000.0 AS range_km2,

    ST_Area(
        ST_Transform(
            ST_Intersection(m.geom, p.geom),
            54009
        )
    ) / 1000000.0 AS protected_km2

FROM threatened_ssa_ranges m
CROSS JOIN ssa_protected_coverage p;
