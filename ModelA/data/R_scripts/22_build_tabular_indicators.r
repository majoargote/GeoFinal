# 22_build_tabular_indicators.R ---------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# ---------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------
# This script builds province-level tabular indicators:
# 1. Broadband / telecommunications
# 2. Crime / safety
#
# Notes:
# - Broadband is kept as the cleaned province-level measure provided
# - Crime is converted into a comparable rate:
#   crime_per_100k = total crimes / population * 100000
# - You may need to adjust the variable names below depending on the
#   columns in the cleaned files

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
out_dir <- file.path(data_proc, "indicators")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ---------------------------------------------------------------------
# Provinces
# ---------------------------------------------------------------------
prov <- get_provinces() |>
  sf::st_drop_geometry() |>
  dplyr::select(province_id, province_name)

print(dim(prov))
print(prov$province_name)

fix_province_names <- function(x) {
  dplyr::recode(
    x,
    "Coruña, A" = "A Coruña",
    "Coruña (A)" = "A Coruña",
    "Rioja, La" = "La Rioja",
    "Rioja (La)" = "La Rioja",
    "Balears, Illes" = "Illes Balears",
    "Balears (Illes)" = "Illes Balears",
    "Palmas, Las" = "Las Palmas",
    "Palmas (Las)" = "Las Palmas",
    .default = x
  )
}
# ---------------------------------------------------------------------
# Read tabular inputs
# ---------------------------------------------------------------------
broadband <- readRDS(file.path(data_proc, "broadband", "broadband_clean.rds"))
crime     <- readRDS(file.path(data_proc, "crime", "crime_clean.rds"))


# ---------------------------------------------------------------------
# Province reference
# ---------------------------------------------------------------------
prov_ref <- prov |>
  sf::st_drop_geometry() |>
  dplyr::select(province_id, province_name) |>
  dplyr::mutate(
    province_name = fix_province_names(province_name)
  )

# ---------------------------------------------------------------------
# Broadband (municipality → province aggregation)
# ---------------------------------------------------------------------
# Broadband variables are coverage percentages at municipality level.
# We aggregate to province using population weights (habitantes).

broadband_by_prov <- broadband |>
  dplyr::mutate(
    habitantes = as.numeric(habitantes)
  ) |>
  dplyr::group_by(provincia) |>
  dplyr::summarise(
    broadband_ftth = weighted.mean(ftth_junio_2021, habitantes, na.rm = TRUE),
    broadband_100  = weighted.mean(cob_100mbps_junio_2021, habitantes, na.rm = TRUE),
    broadband_5g   = weighted.mean(x5g_junio_2021, habitantes, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::rename(province_name = provincia) |>
  dplyr::mutate(
    province_name = fix_province_names(province_name)
  )

# ---------------------------------------------------------------------
# Crime / safety
# ---------------------------------------------------------------------
# Crime is converted to a province-level rate per 100,000 residents
# using cleaned province population data.

pop_df <- readRDS(file.path(data_proc, "crime", "population_clean.rds")) |>
  dplyr::filter(provincia != "National Total") |>
  dplyr::mutate(
    provincia = gsub("^[0-9]{2} ", "", provincia),
    provincia = fix_province_names(provincia),
    population_total = as.numeric(population_total)
  )

crime_by_prov <- crime |>
  dplyr::filter(!provincia %in% c("Foreign", "Unknown", "Total")) |>
  dplyr::mutate(
    provincia = fix_province_names(provincia),
    crime_total = as.numeric(crime_total)
  ) |>
  dplyr::left_join(pop_df, by = "provincia") |>
  dplyr::mutate(
    crime_per_100k = (crime_total / population_total) * 100000
  ) |>
  dplyr::rename(
    province_name = provincia
  ) |>
  dplyr::select(
    province_name,
    crime_per_100k
  )

# ---------------------------------------------------------------------
# Output table
# ---------------------------------------------------------------------
tabular_indicators <- prov_ref |>
  dplyr::left_join(broadband_by_prov, by = "province_name") |>
  dplyr::left_join(crime_by_prov, by = "province_name")

# ---------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------
print(dim(tabular_indicators))
print(summary(tabular_indicators$broadband_ftth))
print(summary(tabular_indicators$crime_per_100k))
print(colSums(is.na(tabular_indicators)))

# ---------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------
write_csv_utf8(
  tabular_indicators,
  file.path(out_dir, "tabular_indicators.csv")
)

saveRDS(
  tabular_indicators,
  file.path(out_dir, "tabular_indicators.rds")
)

message("Build complete: tabular_indicators")

rm(prov, broadband, crime, broadband_by_prov, crime_by_prov, tabular_indicators)
gc()
