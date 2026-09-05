Keep Vulnerable (VU), Endangered (EN) and Critically Endangered (CR)
mammals whose ranges intersect Sub-Saharan Africa.

Multiple polygons belonging to the same species are dissolved.

CREATE TABLE threatened_ssa_mammals AS
SELECT
    m.id_no,
    m.sci_name,
    m.category,
    ST_UnaryUnion(ST_Collect(m.geom)) AS geom
FROM mammal_ranges m
JOIN ssa_boundary s
    ON ST_Intersects(m.geom, s.geom)
WHERE m.category IN ('VU', 'EN', 'CR')
GROUP BY
    m.id_no,
    m.sci_name,
    m.category;


-- Clip each species range to the SSA boundary
CREATE TABLE threatened_ssa_ranges AS
SELECT
    m.id_no,
    m.sci_name,
    m.category,
    ST_Intersection(m.geom, s.geom) AS geom
FROM threatened_ssa_mammals m
CROSS JOIN ssa_boundary s;


-- Validate clipped ranges
SELECT
    COUNT(*) AS species,
    COUNT(DISTINCT id_no) AS unique_species,
    COUNT(*) FILTER (WHERE ST_IsEmpty(geom)) AS empty_geometries,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid_geometries
FROM threatened_ssa_ranges;


-- Count species by threat category
SELECT
    category,
    COUNT(*) AS species_count
FROM threatened_ssa_ranges
GROUP BY category
ORDER BY category;
