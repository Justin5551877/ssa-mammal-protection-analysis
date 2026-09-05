Create spatial outputs for QGIS visualisation.


Join statistical results back to species geometries so QGIS
can map and filter species by protected-area percentage.

CREATE VIEW species_protection_map AS
SELECT
    r.id_no,
    r.sci_name,
    r.category,
    p.range_km2,
    p.protected_km2,
    p.protected_percent,
    r.geom
FROM threatened_ssa_ranges r
JOIN species_protection_results p
    ON r.id_no = p.id_no;



Create geometry representing the portion of each species'
SSA range falling outside qualifying protected areas.


CREATE TABLE species_protection_gaps AS
SELECT
    m.id_no,
    m.sci_name,
    m.category,
    p.protected_percent,

    ST_Difference(
        m.geom,
        a.geom
    ) AS geom

FROM threatened_ssa_ranges m
JOIN species_protection_results p
    ON m.id_no = p.id_no
CROSS JOIN ssa_protected_coverage a;
