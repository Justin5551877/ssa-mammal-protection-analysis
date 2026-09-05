Validate calculated species range and protected-area results.


-- Find cases where calculated protected area exceeds total range
SELECT *
FROM species_protection
WHERE protected_km2 > range_km2;


-- Inspect >100% cases in more detail
SELECT
    id_no,
    sci_name,
    category,
    range_km2,
    protected_km2,
    protected_km2 - range_km2 AS difference_km2,
    protected_km2 / NULLIF(range_km2, 0) * 100 AS protected_percent
FROM species_protection
WHERE protected_km2 > range_km2
ORDER BY protected_percent DESC;
