# 01_clean_hydrographicnetwork.R ---------------------------------------

rm(list = ls())
gc()
cat("\014")


source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "hydrographicnetwork", "red-hidrografica2022_27")
proc_dir <- file.path(data_proc, "hydrographicnetwork")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- list.files(raw_dir, pattern = "\\.shp$", full.names = TRUE)[1]

if (is.na(raw_file)) {
  stop("No shapefile found in: ", raw_dir)
}

# 2. Read
rivers_raw <- st_read(raw_file, quiet = TRUE)

# 3. Clean
rivers_clean <- rivers_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  filter(continua == "realSurfaceWaterSegment") |>
  select(
    river_name = geoname_txt,
    geometry
  )

rm(rivers_raw)
gc()

# 4. Safety checks
rivers_clean <- rivers_clean |>
  st_cast("MULTILINESTRING")

rivers_clean <- rivers_clean[!st_is_empty(rivers_clean), ]

print(dim(rivers_clean))
print(unique(st_geometry_type(rivers_clean)))

# 5. Save
write_gpkg_layer(
  obj   = rivers_clean,
  path  = file.path(proc_dir, "hydrographicnetwork_clean.gpkg"),
  layer = "hydrographicnetwork_clean"
)

saveRDS(
  rivers_clean,
  file.path(proc_dir, "hydrographicnetwork_clean.rds")
)

message("Cleaning complete: hydrographicnetwork")

rm(rivers_clean)
gc()
