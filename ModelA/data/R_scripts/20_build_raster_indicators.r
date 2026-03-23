# 20_build_raster_indicators.R ----------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# ---------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------
# This script builds province-level raster indicators:
# 1. Ruggedness / land slope
# 2. Climate
# 3. Solar resource / sunshine proxy
#
# Note:
# Land cover is temporarily excluded because the cleaned raster CRS
# cannot currently be transformed in the local GDAL/PROJ setup.

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
out_dir <- file.path(data_proc, "indicators")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ---------------------------------------------------------------------
# Provinces
# ---------------------------------------------------------------------
prov <- get_provinces()

print(dim(prov))
print(prov$province_name)

# ---------------------------------------------------------------------
# Read rasters
# ---------------------------------------------------------------------
rugged <- terra::rast(file.path(data_proc, "ruggedness", "ruggedness_spain_clean.tif"))
tavg   <- terra::rast(file.path(data_proc, "climate", "tavg_spain_clean.tif"))
srad   <- terra::rast(file.path(data_proc, "solar", "srad_spain_clean.tif"))

# ---------------------------------------------------------------------
# Extract province means
# ---------------------------------------------------------------------
prov$mean_ruggedness <- exactextractr::exact_extract(rugged, prov, "mean")
prov$mean_tavg       <- exactextractr::exact_extract(tavg, prov, "mean")
prov$mean_srad       <- exactextractr::exact_extract(srad, prov, "mean")

# ---------------------------------------------------------------------
# Output table
# ---------------------------------------------------------------------
raster_indicators <- prov |>
  sf::st_drop_geometry() |>
  dplyr::select(
    province_id,
    province_name,
    mean_ruggedness,
    mean_tavg,
    mean_srad
  )

# ---------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------
print(dim(raster_indicators))
print(summary(raster_indicators$mean_ruggedness))
print(summary(raster_indicators$mean_tavg))
print(summary(raster_indicators$mean_srad))
print(colSums(is.na(raster_indicators)))

# ---------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------
write_csv_utf8(
  raster_indicators,
  file.path(out_dir, "raster_indicators.csv")
)

saveRDS(
  raster_indicators,
  file.path(out_dir, "raster_indicators.rds")
)

message("Build complete: raster_indicators")

rm(prov, rugged, tavg, srad, raster_indicators)
gc()
