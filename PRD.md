# PRD: Geospatial Term Paper — Data Centers & Environmental Stress in Spain

## Context
This is an academic term paper delivered as a printed Jupyter notebook (code in technical appendix). The research asks whether predicted future data center sites in Spain cluster in provinces already under compound environmental stress. The paper combines a siting model (economic/infrastructure-driven) with an environmental impact model (water, heat, land use), then maps the overlap.

---

## Research Question
> Do predicted data center locations in Spain concentrate in areas already under compound environmental stress (water scarcity, heat extremes, land use pressure)?

---

## Notebook Structure (Sections → Paper Sections)

| # | Section | Type |
|---|---------|------|
| 1 | Introduction & Research Question | Narrative |
| 2 | Data Collection: Existing Data Centers | Code + Maps |
| 3 | Model A — Site Suitability | Code + Maps |
| 4 | Model B — Environmental Stress | Code + Maps |
| 5 | Synthesis: Overlap Analysis | Code + Maps |
| 6 | Conclusion & Limitations | Narrative |
| A | Technical Appendix (all code) | Code |

---

## Phase 1 — Data Collection: Existing Data Centers

**Goal:** Build a GeoDataFrame of known data centers in Spain.

**Source:** Scrape `https://www.datacentermap.com/spain/` and subpages per region (madrid/, barcelona/, etc.)

**Fields to collect:**
- Name, operator
- City / region
- Size (m²) — where listed
- Year built / opened — where listed
- Geocode to lat/long → assign to NUTS3 province

**Output:** `data/datacentermap_spain.csv` + `data/dc_locations.geojson`

**Library:** `requests` + `BeautifulSoup4`, geocode with `geopy` (Nominatim)

---

## Phase 2 — Administrative Base Layer

**Source:** GADM v4.1 — Level 2 (52 Spanish provinces, NUTS3)
- URL: https://gadm.org/download_country.html (country = Spain, level 2)
- Format: GeoPackage / Shapefile

**Output:** `data/spain_provinces.gpkg` — the spatial backbone for all joins

---

## Model A — Site Suitability Model

**Question answered:** Where would a rational data center operator choose to build?

**Method:** Multi-criteria scoring model. Each province scored 0–1 on each factor; weighted sum → suitability index.

### Input Variables (all at province level)

| Variable | Rationale | Source | Type |
|----------|-----------|--------|------|
| Electricity price (€/kWh) | Lower cost = more attractive | Eurostat `nrg_pc_205` (national proxy; use REE regional data if available) | Economic |
| Water price (€/m³) | Cooling water cost | INE / Eurostat water price statistics | Economic |
| Distance to IXP / major fiber hub | Latency-sensitive connectivity | PeeringDB / TeleGeography (manual lookup for Madrid/Barcelona) | Infrastructure |
| Power grid capacity (GW installed) | Reliable electricity supply | REE API (https://www.ree.es/en/datos/) | Infrastructure |
| Land cost proxy (urban land price) | CAPEX for site | Ministerio de Transportes / INE property price index | Economic |
| Labor market size | Skilled workforce | Eurostat regional employment (NUTS3) | Economic |
| Tax incentive zone | Special economic zones | Manual lookup (ZEC Canarias, etc.) | Economic |

**Scoring:**
```
suitability_i = Σ (w_j × normalized_score_ij)
```
Weights (suggestive): infrastructure 40%, economic 40%, water price 20%.

**Output:**
- `data/model_a_scores.csv` — province-level suitability scores
- Map: choropleth of suitability index across 52 provinces
- Table: top 10 predicted provinces

---

## Model B — Environmental Stress Analysis

**Question answered:** At Model A's top predicted sites, how severe is the compound environmental stress?

**Spatial unit:** NUTS3 provinces (join all layers to `spain_provinces.gpkg`)

### Layer 1 — Water Scarcity (Primary Focus, weight: 50%)

| Dataset | Variable | Source | Format |
|---------|----------|--------|--------|
| WRI Aqueduct | Baseline water stress index per province | https://www.wri.org/aqueduct | CSV download + join |
| CSIC Drought Monitor | Mean SPEI-12 (1961–present) per province | https://spei.csic.es/ | NetCDF → spatial mean |
| Confederaciones Hidrográficas | River basin over-allocation indicator | https://hispagua.cedex.es/ | Manual lookup by basin |

**Province score:** Normalize water stress index + SPEI aridity to 0–1 (high = scarce)

### Layer 2 — Heat Extremes (Weight: 25%)

| Dataset | Variable | Source | Format |
|---------|----------|--------|--------|
| E-OBS v31.0e | Annual days T_max > 35°C (1950–2024) | https://surfobs.climate.copernicus.eu/ | NetCDF → spatial mean |
| AEMET OpenData | Historical extreme temperature records | https://www.aemet.es/en/datos_abiertos | CSV / API |

**Province score:** Mean annual heat-days above 35°C, normalized to 0–1

### Layer 3 — Land Use Pressure (Weight: 25%)

| Dataset | Variable | Source | Format |
|---------|----------|--------|--------|
| Corine Land Cover 2018 | % agricultural + % urban per province | https://land.copernicus.eu/pan-european/corine-land-cover | Shapefile |
| SIOSE | Protected areas overlap | https://www.siose.es/ | Shapefile |

**Province score:** % land under agricultural/urban/protected use (less "open" land = more pressure), normalized 0–1

### Compound Environmental Stress Index

```
stress_i = 0.50 × water_i + 0.25 × heat_i + 0.25 × landuse_i
```

- Classify provinces into 4 tiers: Low / Medium / High / Very High stress
- **Output:** `data/model_b_stress.csv` + choropleth map

---

## Synthesis & Overlap Analysis

**Core output maps:**

1. **Map 1:** Known data centers plotted over Spain (bubble size = facility size m²)
2. **Map 2:** Model A — Site suitability choropleth (52 provinces)
3. **Map 3:** Model B — Compound environmental stress choropleth
4. **Map 4:** Bivariate map — High suitability + High stress provinces highlighted (the key finding)
5. **Map 5 (optional):** Water scarcity deep-dive — SPEI map with existing DC locations overlaid

**Quantification of answer:**
- Cross-tabulate suitability tier × stress tier for each province
- Correlation coefficient: suitability score vs. stress score
- Narrative: "X of the top 10 predicted provinces fall in High or Very High stress zones"

---

## Tech Stack

```toml
# pyproject.toml dependencies to add
dependencies = [
    "geopandas>=0.14",
    "pandas>=2.0",
    "numpy>=1.26",
    "matplotlib>=3.8",
    "folium>=0.15",          # interactive maps
    "requests>=2.31",
    "beautifulsoup4>=4.12",
    "geopy>=2.4",            # geocoding DCs
    "xarray>=2024.1",        # NetCDF handling (E-OBS, SPEI)
    "rioxarray>=0.15",       # raster-vector intersection
    "scikit-learn>=1.4",     # normalization (MinMaxScaler)
    "scipy>=1.12",
    "seaborn>=0.13",
    "plotly>=5.18",          # optional interactive visuals
    "contextily>=1.5",       # basemaps
    "mapclassify>=2.6",      # choropleth classification
]
```

---

## Critical Files

| File | Purpose |
|------|---------|
| `dataCenters.ipynb` | Main paper notebook |
| `data/datacentermap_spain.csv` | Scraped DC data |
| `data/dc_locations.geojson` | Geocoded DCs |
| `data/spain_provinces.gpkg` | GADM province boundaries |
| `data/model_a_scores.csv` | Suitability scores |
| `data/model_b_stress.csv` | Stress index scores |
| `outputs/` | All exported maps (PNG/HTML) |

---

## Open Questions to Resolve During Implementation

1. **Electricity price at NUTS3:** Eurostat data is national-level for Spain. Fallback: use REE regional demand intensity as proxy for grid capacity, keep electricity price national.
2. **IXP proximity:** PeeringDB lists IXPs in Madrid (ESPANIX), Barcelona (CATNIX), Bilbao, Valencia — manual lat/long lookup and distance calculation per province centroid.
3. **Water price regional data:** INE publishes water tariff surveys by province — check availability.

---

## Verification

1. Run notebook top-to-bottom: all cells execute without error
2. Confirm DC scrape returns ≥ 50 records for Spain
3. Province layer joins cleanly: all 52 provinces have scores in both models
4. Bivariate map renders with clear visual separation of quadrants
5. Final printed output: export notebook as PDF, verify maps render at print resolution
