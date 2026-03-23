# 02_clean_airports.R --------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "airports", "ne_10m_airports")
proc_dir <- file.path(data_proc, "airports")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- list.files(raw_dir, pattern = "\\.shp$", full.names = TRUE)[1]

if (is.na(raw_file)) {
  stop("No shapefile found in: ", raw_dir)
}

# 2. Read
airports_raw <- st_read(raw_file, quiet = TRUE)

# quick inspect if needed
print(colnames(airports_raw))
print(dim(airports_raw))
print(unique(st_geometry_type(airports_raw)))

# 3. Clean
airports_clean <- airports_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  select(
    airport_name = name,
    airport_name_en = name_en,
    airport_type = type,
    iata_code,
    gps_code,
    location,
    scalerank,
    natlscale,
    geometry
  )

rm(airports_raw)
gc()

# 4. Safety checks
airports_clean <- airports_clean[!st_is_empty(airports_clean), ]

print(dim(airports_clean))
print(unique(st_geometry_type(airports_clean)))
print(table(airports_clean$airport_type, useNA = "ifany"))

# 5. Save
write_gpkg_layer(
  obj   = airports_clean,
  path  = file.path(proc_dir, "airports_clean.gpkg"),
  layer = "airports_clean"
)

saveRDS(
  airports_clean,
  file.path(proc_dir, "airports_clean.rds")
)

message("Cleaning complete: airports")

rm(airports_clean)
gc()
