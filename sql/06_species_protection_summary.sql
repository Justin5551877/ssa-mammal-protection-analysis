Calculate final protected-area percentages and save
species-level results.


-- Display species ranked by protected-area coverage
SELECT
    sci_name,
    category,
    ROUND(range_km2::numeric, 1) AS range_km2,
    ROUND(protected_km2::numeric, 1) AS protected_km2,
    ROUND(
        LEAST(
            100,
            protected_km2 / NULLIF(range_km2, 0) * 100
        )::numeric,
        2
    ) AS protected_percent
FROM species_protection
ORDER BY protected_percent DESC;


-- Save clean species-level results
CREATE TABLE species_protection_results AS
SELECT
    id_no,
    sci_name,
    category,
    range_km2,
    protected_km2,

    LEAST(
        100,
        protected_km2 / NULLIF(range_km2, 0) * 100
    ) AS protected_percent

FROM species_protection;
