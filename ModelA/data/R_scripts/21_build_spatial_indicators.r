# 21_build_spatial_indicators.R ---------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# ---------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------
# This script builds province-level spatial indicators:
# 1. Protected area share
# 2. Seismic hazard
# 3. Distance to nearest airport
# 4. Road infrastructure
# Output tables are kept separate by indicator for now:
# - prov_area
# - pa_by_prov
# - seis_by_prov
# - airport_by_prov
# - roads_by_prov
# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
out_dir <- file.path(data_proc, "indicators")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ---------------------------------------------------------------------
# Provinces
# ---------------------------------------------------------------------
prov <- get_provinces() |>
  st_transform(crs_project)

prov$prov_area_m2 <- as.numeric(st_area(prov))

prov_area <- prov |>
  st_drop_geometry() |>
  dplyr::select(province_id, province_name, prov_area_m2)

# =====================================================================
# Protected areas
# Variable: protected_share
# Definition: protected area within province / total province area
# =====================================================================

pa <- readRDS(file.path(data_proc, "spainprotectedarea", "spainprotectedarea_clean.rds")) |>
  st_transform(crs_project)

pa_int <- st_intersection(
  prov |>
    dplyr::select(province_id, province_name),
  pa
)

pa_int$int_area_m2 <- as.numeric(st_area(pa_int))

pa_by_prov <- pa_int |>
  st_drop_geometry() |>
  dplyr::group_by(province_id) |>
  dplyr::summarise(
    pa_area_m2 = sum(int_area_m2, na.rm = TRUE),
    .groups = "drop"
  )

rm(pa, pa_int)
gc()

# =====================================================================
# Seismic hazard
# Variables:
# - mean_seismic_hazard
# - max_seismic_hazard
# Definition:
# - mean = area-weighted mean of hpvalue within province
# - max  = maximum hpvalue within province
# =====================================================================

seis <- readRDS(file.path(data_proc, "seismicintensity", "seismicintensity_clean.rds")) |>
  st_transform(crs_project)

seis_int <- st_intersection(
  prov |>
    dplyr::select(province_id, province_name),
  seis
)

seis_int$int_area_m2 <- as.numeric(st_area(seis_int))

seis_by_prov <- seis_int |>
  st_drop_geometry() |>
  dplyr::group_by(province_id) |>
  dplyr::summarise(
    mean_seismic_hazard = weighted.mean(hpvalue, int_area_m2, na.rm = TRUE),
    max_seismic_hazard = max(hpvalue, na.rm = TRUE),
    .groups = "drop"
  )

rm(seis, seis_int)
gc()

# =====================================================================
# Airports
# Variable: dist_airport_km
# Definition: distance from province centroid to nearest relevant airport
# Airports kept:
# - major
# - major and military
# - mid
# - mid and military
# =====================================================================

airports <- readRDS(file.path(data_proc, "airports", "airports_clean.rds")) |>
  st_transform(crs_project) |>
  dplyr::filter(
    airport_type %in% c(
      "major",
      "major and military",
      "mid",
      "mid and military"
    )
  )

prov_cent <- st_centroid(prov)
airport_dist <- st_distance(prov_cent, airports)

airport_by_prov <- tibble::tibble(
  province_id = prov$province_id,
  dist_airport_km = apply(airport_dist, 1, min) |> as.numeric() / 1000
)

rm(airports, prov_cent, airport_dist)
gc()

# =====================================================================
# Roads
# Variables:
# - road_length_km
# - road_density_km_per_km2
# Definition:
# - road_length_km = total road length within province
# - road_density_km_per_km2 = road length / province area in km2
# Roads kept: fclass 0,1,2,3,4
# =====================================================================

roads <- readRDS(file.path(data_proc, "roads", "roads_clean.rds")) |>
  st_transform(crs_project)

roads_spain <- roads |>
  st_filter(prov)

roads_main <- roads_spain |>
  dplyr::filter(fclass %in% c(0, 1, 2, 3, 4))

road_int <- st_intersection(
  prov |>
    dplyr::select(province_id, province_name),
  roads_main
)

road_int$road_len_m <- as.numeric(st_length(road_int))

roads_by_prov <- prov_area |>
  dplyr::select(province_id, prov_area_m2) |>
  dplyr::left_join(
    road_int |>
      st_drop_geometry() |>
      dplyr::group_by(province_id) |>
      dplyr::summarise(
        road_length_km = sum(road_len_m, na.rm = TRUE) / 1000,
        .groups = "drop"
      ),
    by = "province_id"
  ) |>
  dplyr::mutate(
    road_length_km = dplyr::coalesce(road_length_km, 0),
    road_density_km_per_km2 = road_length_km / (prov_area_m2 / 1e6)
  ) |>
  dplyr::select(province_id, road_length_km, road_density_km_per_km2)

rm(roads, roads_spain, roads_main, road_int)
gc()

# =====================================================================
# Water resources
# Variables:
# - water_length_km
# - water_density_km_per_km2
# Definition:
# - water_length_km = total hydrographic network length within province
# - water_density_km_per_km2 = hydrographic length / province area in km2
# =====================================================================

water <- readRDS(file.path(data_proc, "hydrographicnetwork", "hydrographicnetwork_clean.rds")) |>
  st_transform(crs_project)

water_spain <- water |>
  st_filter(prov)

water_int <- st_intersection(
  prov |>
    dplyr::select(province_id, province_name),
  water_spain
)

water_int$water_len_m <- as.numeric(st_length(water_int))

water_by_prov <- prov_area |>
  dplyr::select(province_id, prov_area_m2) |>
  dplyr::left_join(
    water_int |>
      st_drop_geometry() |>
      dplyr::group_by(province_id) |>
      dplyr::summarise(
        water_length_km = sum(water_len_m, na.rm = TRUE) / 1000,
        .groups = "drop"
      ),
    by = "province_id"
  ) |>
  dplyr::mutate(
    water_length_km = dplyr::coalesce(water_length_km, 0),
    water_density_km_per_km2 = water_length_km / (prov_area_m2 / 1e6)
  ) |>
  dplyr::select(province_id, water_length_km, water_density_km_per_km2)

rm(water, water_spain, water_int)
gc()

# =====================================================================
# Power availability (proxy)
# Variables:
# - power_availability_mw: average surrounding total installed power capacity
# - renewable_availability_mw: average surrounding renewable capacity
# They are constructed as the area-weighted mean of regional power capacity
# from the Arkolakis replication dataset within each province.
# =====================================================================

ark <- readRDS(file.path(data_proc, "arkolakis", "arkolakis_clean.rds")) |>
  st_transform(crs_project)

ark_int <- st_intersection(
  prov |>
    dplyr::select(province_id, province_name),
  ark
)

ark_int$int_area_m2 <- as.numeric(st_area(ark_int))

ark_by_prov <- ark_int |>
  st_drop_geometry() |>
  dplyr::group_by(province_id) |>
  dplyr::summarise(
    power_availability_mw =
      weighted.mean(capacity_mw, int_area_m2, na.rm = TRUE),
    renewable_availability_mw =
      weighted.mean(rnw_capacity_mw, int_area_m2, na.rm = TRUE),
    .groups = "drop"
  )

rm(ark, ark_int)
gc()

# =====================================================================
# Final output: spatial_indicators
# One row per province, all indicators merged
# =====================================================================

spatial_indicators <- prov_area |>
  dplyr::left_join(pa_by_prov, by = "province_id") |>
  dplyr::left_join(seis_by_prov, by = "province_id") |>
  dplyr::left_join(airport_by_prov, by = "province_id") |>
  dplyr::left_join(roads_by_prov, by = "province_id") |>
  dplyr::left_join(water_by_prov, by = "province_id") |>
  dplyr::left_join(ark_by_prov, by = "province_id") |>
  dplyr::mutate(
    pa_area_m2 = dplyr::coalesce(pa_area_m2, 0),
    protected_share = pa_area_m2 / prov_area_m2,
    
    road_length_km = dplyr::coalesce(road_length_km, 0),
    road_density_km_per_km2 = road_length_km / (prov_area_m2 / 1e6),
    
    water_length_km = dplyr::coalesce(water_length_km, 0),
    water_density_km_per_km2 = water_length_km / (prov_area_m2 / 1e6)
  ) |>
  dplyr::select(
    province_id,
    province_name,
    protected_share,
    mean_seismic_hazard,
    max_seismic_hazard,
    water_density_km_per_km2,
    dist_airport_km,
    road_density_km_per_km2,
    power_availability_mw,
    renewable_availability_mw
  )

#####CHECKS
dim(spatial_indicators)   # should be ~47 x variables
summary(spatial_indicators)
colSums(is.na(spatial_indicators))

prov_map <- get_provinces() |>
  st_transform(crs_project) |>
  dplyr::left_join(spatial_indicators, by = "province_id")

plot(prov_map["protected_share"], main = "Protected share")
plot(prov_map["mean_seismic_hazard"], main = "Mean seismic")
plot(prov_map["max_seismic_hazard"], main = "Max seismic")

plot(prov_map["water_density_km_per_km2"], main = "Water density")
plot(prov_map["road_density_km_per_km2"], main = "Road density")
plot(prov_map["dist_airport_km"], main = "Dist airport")

plot(prov_map["power_availability_mw"], main = "Power")
plot(prov_map["renewable_availability_mw"], main = "Renewables")


# =====================================================================
# Save
# =====================================================================

write_csv_utf8(
  spatial_indicators,
  file.path(out_dir, "spatial_indicators.csv")
)

saveRDS(
  spatial_indicators,
  file.path(out_dir, "spatial_indicators.rds")
)

message("Build complete: spatial_indicators")

rm(
  prov, prov_area,
  pa_by_prov, seis_by_prov, airport_by_prov, roads_by_prov,
  water_by_prov, ark_by_prov,
  spatial_indicators
)
gc()
