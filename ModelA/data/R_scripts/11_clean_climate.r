# 11_clean_climate.R ---------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
tavg_raw_dir <- file.path(data_raw, "climate", "wc2.1_30s_tavg")
srad_raw_dir <- file.path(data_raw, "solar",   "wc2.1_30s_srad")

tavg_proc_dir <- file.path(data_proc, "climate")
srad_proc_dir <- file.path(data_proc, "solar")

if (!dir.exists(tavg_proc_dir)) dir.create(tavg_proc_dir, recursive = TRUE)
if (!dir.exists(srad_proc_dir)) dir.create(srad_proc_dir, recursive = TRUE)

tavg_files <- list.files(
  tavg_raw_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

srad_files <- list.files(
  srad_raw_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

if (length(tavg_files) == 0) {
  stop("No tavg tif files found in: ", tavg_raw_dir)
}

if (length(srad_files) == 0) {
  stop("No srad tif files found in: ", srad_raw_dir)
}

# 2. Read raw data
tavg_raw <- terra::rast(tavg_files)
srad_raw <- terra::rast(srad_files)

print(tavg_files)
print(srad_files)

print(tavg_raw)
print(srad_raw)

# 3. Read Spain boundary
spain <- get_spain_boundary()
spain_vect <- terra::vect(spain)

# 4. Clean temperature raster
tavg_clean <- terra::app(tavg_raw, mean, na.rm = TRUE)
tavg_clean <- terra::crop(tavg_clean, spain_vect)
tavg_clean <- terra::mask(tavg_clean, spain_vect)

rm(tavg_raw)
gc()

# 5. Clean solar raster
srad_clean <- terra::app(srad_raw, mean, na.rm = TRUE)
srad_clean <- terra::crop(srad_clean, spain_vect)
srad_clean <- terra::mask(srad_clean, spain_vect)

rm(srad_raw, spain, spain_vect)
gc()

# 6. Safety checks
print(tavg_clean)
print(terra::crs(tavg_clean))
print(terra::res(tavg_clean))
print(dim(tavg_clean))

print(srad_clean)
print(terra::crs(srad_clean))
print(terra::res(srad_clean))
print(dim(srad_clean))

# 7. Save
terra::writeRaster(
  tavg_clean,
  filename = file.path(tavg_proc_dir, "tavg_spain_clean.tif"),
  overwrite = TRUE,
  gdal = c("COMPRESS=LZW")
)

terra::writeRaster(
  srad_clean,
  filename = file.path(srad_proc_dir, "srad_spain_clean.tif"),
  overwrite = TRUE,
  gdal = c("COMPRESS=LZW")
)

tavg_clean <- terra::rast(file.path(tavg_proc_dir, "tavg_spain_clean.tif"))
srad_clean <- terra::rast(file.path(srad_proc_dir, "srad_spain_clean.tif"))

saveRDS(
  tavg_clean,
  file.path(tavg_proc_dir, "tavg_spain_clean.rds")
)

saveRDS(
  srad_clean,
  file.path(srad_proc_dir, "srad_spain_clean.rds")
)

message("Cleaning complete: climate")

rm(tavg_clean, srad_clean)
gc()
