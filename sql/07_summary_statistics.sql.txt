Generate descriptive statistics from final species-level results.



-- Mean and median protected coverage by IUCN category
SELECT
    category,
    COUNT(*) AS species,

    ROUND(
        AVG(protected_percent)::numeric,
        2
    ) AS mean_protection,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY protected_percent)::numeric,
        2
    ) AS median_protection

FROM species_protection_results
GROUP BY category
ORDER BY category;


-- Group species into protected-coverage bands
SELECT
    CASE
        WHEN protected_percent < 10 THEN '<10%'
        WHEN protected_percent < 30 THEN '10-30%'
        WHEN protected_percent < 50 THEN '30-50%'
        ELSE '50%+'
    END AS coverage_group,

    COUNT(*) AS species

FROM species_protection_results

GROUP BY coverage_group

ORDER BY MIN(protected_percent);


-- Fifteen species with the lowest protected coverage
SELECT
    sci_name,
    category,
    ROUND(protected_percent::numeric, 2) AS protected_percent
FROM species_protection_results
ORDER BY protected_percent
LIMIT 15;
