# 06_clean_ruggedness.R -----------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "ruggedness")
proc_dir <- file.path(data_proc, "ruggedness")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- file.path(raw_dir, "tri.txt")

if (!file.exists(raw_file)) {
  stop("Ruggedness file not found: ", raw_file)
}

print(raw_file)
print(file.info(raw_file))

# 2. Read global raster
rugged_raw <- terra::rast(raw_file)

# 3. Read Spain boundary and move to raster CRS
spain <- get_spain_boundary()
spain_vect <- terra::vect(st_transform(spain, 4326))

# 4. Crop and mask to Spain
rugged_crop <- terra::crop(rugged_raw, spain_vect)
rugged_clean <- terra::mask(rugged_crop, spain_vect)

rm(rugged_raw, rugged_crop, spain, spain_vect)
gc()

# 5. Safety checks
print(rugged_clean)
print(terra::crs(rugged_clean))
print(terra::ext(rugged_clean))
print(terra::res(rugged_clean))
print(dim(rugged_clean))

# 6. Save
out_path <- file.path(proc_dir, "ruggedness_spain_clean.tif")

terra::writeRaster(
  rugged_clean,
  filename = out_path,
  overwrite = TRUE,
  gdal = c("COMPRESS=LZW")
)

# reload from disk (safer for large rasters)
rugged_clean <- terra::rast(out_path)

saveRDS(
  rugged_clean,
  file.path(proc_dir, "ruggedness_spain_clean.rds")
)

print(file.exists(out_path))

message("Cleaning complete: ruggedness")

rm(rugged_clean)
gc()
