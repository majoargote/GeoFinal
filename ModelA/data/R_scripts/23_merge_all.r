# 24_prepare_model_indicators.R ---------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# ---------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------
# This script prepares the merged indicator table for modeling:
# 1. inverts variables where lower values are better
# 2. standardizes all indicators (z-scores)
# 3. splits indicators into main and secondary sets
#
# After inversion, higher values always mean "more attractive" for
# data-centre siting.
#
# Output:
# - all_indicators_prepared.csv / .rds
# - main_indicators.csv / .rds
# - secondary_indicators.csv / .rds

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
ind_dir <- file.path(data_proc, "indicators")
if (!dir.exists(ind_dir)) dir.create(ind_dir, recursive = TRUE)

# ---------------------------------------------------------------------
# Read indicator tables
# ---------------------------------------------------------------------
spatial_indicators <- readRDS(file.path(ind_dir, "spatial_indicators.rds"))
raster_indicators  <- readRDS(file.path(ind_dir, "raster_indicators.rds"))
tabular_indicators <- readRDS(file.path(ind_dir, "tabular_indicators.rds"))

# ---------------------------------------------------------------------
# Merge all indicators
# ---------------------------------------------------------------------
all_indicators <- spatial_indicators |>
  dplyr::left_join(raster_indicators, by = c("province_id", "province_name")) |>
  dplyr::left_join(tabular_indicators, by = c("province_id", "province_name"))

print(dim(all_indicators))
print(colSums(is.na(all_indicators)))
print(names(all_indicators))
print(head(all_indicators))

write_csv_utf8(
  all_indicators,
  file.path(ind_dir, "all_indicators.csv")
)

saveRDS(
  all_indicators,
  file.path(ind_dir, "all_indicators.rds")
)



# ---------------------------------------------------------------------
# Invert "cost" / "constraint" variables and drop originals
# ---------------------------------------------------------------------
all_indicators_prepared <- all_indicators |>
  dplyr::mutate(
    inverted_protected_share   = -protected_share,
    inverted_seismic_hazard    = -max_seismic_hazard,
    inverted_dist_airport_km   = -dist_airport_km,
    inverted_ruggedness        = -mean_ruggedness
  ) |>
  dplyr::select(
    -protected_share,
    -max_seismic_hazard,
    -dist_airport_km,
    -mean_ruggedness
  ) |>
  dplyr::mutate(
    dplyr::across(
      -c(province_id, province_name),
      ~ as.numeric(scale(.))
    )
  )

# ---------------------------------------------------------------------
# Main indicators
# ---------------------------------------------------------------------
main_indicators <- all_indicators_prepared |>
  dplyr::select(
    province_id,
    province_name,
    inverted_protected_share,
    inverted_seismic_hazard,
    water_density_km_per_km2,
    inverted_dist_airport_km,
    road_density_km_per_km2,
    power_availability_mw,
    renewable_availability_mw,
    inverted_ruggedness,
    mean_tavg,
    mean_srad,
    broadband_ftth,
    crime_per_100k
  )

# ---------------------------------------------------------------------
# Secondary indicators
# ---------------------------------------------------------------------
secondary_indicators <- all_indicators_prepared |>
  dplyr::select(
    province_id,
    province_name,
    mean_seismic_hazard,
    broadband_100,
    broadband_5g
  )

# ---------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------
print(dim(all_indicators_prepared))
print(dim(main_indicators))
print(dim(secondary_indicators))

print(summary(main_indicators))
print(summary(secondary_indicators))

print(colSums(is.na(all_indicators_prepared)))
print(colSums(is.na(main_indicators)))
print(colSums(is.na(secondary_indicators)))

# ---------------------------------------------------------------------
# Naive ranking
# ---------------------------------------------------------------------

ranking <- main_indicators |>
  dplyr::mutate(
    score = rowMeans(
      dplyr::across(-c(province_id, province_name)),
      na.rm = TRUE
    )
  ) |>
  dplyr::arrange(dplyr::desc(score))

ranking <- ranking |>
  dplyr::mutate(
    rank = dplyr::dense_rank(dplyr::desc(score))
  )

sort(
  cor(
    dplyr::select(ranking, -province_id, -province_name, -rank),
    ranking$score
  )[,1],
  decreasing = TRUE
)

prov_map <- get_provinces() |>
  st_transform(crs_project) |>
  dplyr::left_join(ranking, by = c("province_id", "province_name"))

plot(prov_map["score"], main = "Data centre suitability (naive index)")
plot(prov_map["rank"], main = "Province ranking (1 = best)")

head(ranking)

# ---------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------
write_csv_utf8(
  all_indicators_prepared,
  file.path(ind_dir, "all_indicators_prepared.csv")
)

saveRDS(
  all_indicators_prepared,
  file.path(ind_dir, "all_indicators_prepared.rds")
)

write_csv_utf8(
  main_indicators,
  file.path(ind_dir, "main_indicators.csv")
)

saveRDS(
  main_indicators,
  file.path(ind_dir, "main_indicators.rds")
)

write_csv_utf8(
  secondary_indicators,
  file.path(ind_dir, "secondary_indicators.csv")
)

saveRDS(
  secondary_indicators,
  file.path(ind_dir, "secondary_indicators.rds")
)

message("Build complete: prepared indicator tables")

# ---------------------------------------------------------------------
# Clean up
# ---------------------------------------------------------------------
rm(
  all_indicators,
  all_indicators_prepared,
  main_indicators,
  secondary_indicators
)
gc()
