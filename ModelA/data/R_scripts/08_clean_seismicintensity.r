# 08_clean_seismicintensity.R ------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "earthquakehazard", "output2")
proc_dir <- file.path(data_proc, "seismicintensity")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- file.path(raw_dir, "hmap1846.shp")

if (!file.exists(raw_file)) {
  stop("Seismic shapefile not found: ", raw_file)
}

# 2. Read
seis_raw <- st_read(raw_file, quiet = TRUE)

print(colnames(seis_raw))
print(dim(seis_raw))
print(unique(st_geometry_type(seis_raw)))

# 3. Clean
seis_clean <- seis_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  select(
    hpvalue,
    geometry
  )

rm(seis_raw)
gc()

# 4. Safety checks
seis_clean <- seis_clean |>
  st_cast("MULTIPOLYGON")

seis_clean <- seis_clean[!st_is_empty(seis_clean), ]

print(colnames(seis_clean))
print(dim(seis_clean))
print(unique(st_geometry_type(seis_clean)))
print(summary(seis_clean$hpvalue))

# 5. Save
write_gpkg_layer(
  obj   = seis_clean,
  path  = file.path(proc_dir, "seismicintensity_clean.gpkg"),
  layer = "seismicintensity_clean"
)

saveRDS(
  seis_clean,
  file.path(proc_dir, "seismicintensity_clean.rds")
)

message("Cleaning complete: seismicintensity")

rm(seis_clean)
gc()
