# 04_clean_roads.R -----------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "roads")
proc_dir <- file.path(data_proc, "roads")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- list.files(
  raw_dir,
  pattern = "gROADS.*\\.shp$",
  full.names = TRUE,
  recursive = TRUE
)[1]

if (is.na(raw_file)) {
  stop("No shapefile found in: ", raw_dir)
}

# 2. Read
roads_raw <- st_read(raw_file, quiet = TRUE)

print(colnames(roads_raw))
print(dim(roads_raw))
print(unique(st_geometry_type(roads_raw)))

# 3. Clean
roads_clean <- roads_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  select(
    roadid,
    onme,
    ntlclass,
    fclass,
    numlanes,
    speedlimit,
    curntspeed,
    opstatus,
    length_km,
    geometry
  )

rm(roads_raw)
gc()

# 4. Safety checks
roads_clean <- roads_clean |>
  st_cast("MULTILINESTRING")

roads_clean <- roads_clean[!st_is_empty(roads_clean), ]

print(dim(roads_clean))
print(unique(st_geometry_type(roads_clean)))
print(summary(roads_clean$length_km))
print(table(roads_clean$fclass, useNA = "ifany"))
print(table(roads_clean$opstatus, useNA = "ifany"))

# 5. Save
write_gpkg_layer(
  obj   = roads_clean,
  path  = file.path(proc_dir, "roads_clean.gpkg"),
  layer = "roads_clean"
)

saveRDS(
  roads_clean,
  file.path(proc_dir, "roads_clean.rds")
)

message("Cleaning complete: roads")

rm(roads_clean)
gc()
