# Data

The raw spatial datasets used in this project are not included directly in the repository because of their size and potential redistribution restrictions.

This directory documents the source data required to reproduce the analysis.

## Mammal Range Data

Species distribution polygons were used to represent mapped mammal ranges.

Relevant fields included:

- `id_no` — species identifier
- `sci_name` — scientific name
- `category` — IUCN threat category
- `presence`
- `origin`
- `seasonal`
- `family`
- `genus`
- `geom` — spatial range geometry

The analysis retained species classified as:

- `VU` — Vulnerable
- `EN` — Endangered
- `CR` — Critically Endangered

Species geometries were subsequently clipped to the Sub-Saharan African study area.

## Country Boundaries

Country polygon data were used to:

- define the Sub-Saharan African study area;
- retain national boundaries for mapping;
- calculate species protected-area coverage separately within each country.

Relevant attributes included:

- country name
- continent
- UN region
- subregion
- World Bank region
- geometry

Sub-Saharan Africa was defined by selecting African countries outside the `Northern Africa` subregion.

## Protected Areas

Protected-area polygon data were imported into PostgreSQL/PostGIS from three source tables:

```text
protected_areas_0
protected_areas_1
protected_areas_2
