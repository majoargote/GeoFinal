# 07_clean_landcover.R -----------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "landcover", "DATA 2")
proc_dir <- file.path(data_proc, "landcover")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- file.path(raw_dir, "U2018_CLC2018_V2020_20u1.tif")

if (!file.exists(raw_file)) {
  stop("Landcover file not found: ", raw_file)
}

print(raw_file)

# 2. Read raster
lc_raw <- terra::rast(raw_file)

# 3. Keep as-is for now
lc_clean <- lc_raw

rm(lc_raw)
gc()

# 4. Checks
print(lc_clean)
print(terra::crs(lc_clean))
print(terra::res(lc_clean))
print(dim(lc_clean))

# 5. Save
out_path <- file.path(proc_dir, "landcover_clean.tif")

terra::writeRaster(
  lc_clean,
  filename = out_path,
  overwrite = TRUE,
  gdal = c("COMPRESS=LZW")
)

lc_clean <- terra::rast(out_path)

saveRDS(
  lc_clean,
  file.path(proc_dir, "landcover_clean.rds")
)

print(file.exists(out_path))

message("Cleaning complete: landcover")

rm(lc_clean)
gc()
