# 03_clean_spainprotectedarea.R ----------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "spainprotectedarea", "enp2024_shape")
proc_dir <- file.path(data_proc, "spainprotectedarea")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- list.files(raw_dir, pattern = "\\.shp$", full.names = TRUE)[1]

if (is.na(raw_file)) {
  stop("No shapefile found in: ", raw_dir)
}

# 2. Read
raw_file <- file.path(raw_dir, "enp2024_p.shp")

if (!file.exists(raw_file)) {
  stop("Shapefile not found: ", raw_file)
}

pa_raw <- st_read(raw_file, quiet = TRUE)

print(colnames(pa_raw))
print(dim(pa_raw))
print(unique(st_geometry_type(pa_raw)))

# 3. Clean
pa_clean <- pa_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  select(
    site_name,
    odesignate,
    site_code,
    desig_abbr,
    site_cdda,
    sup_ha,
    geometry
  )

rm(pa_raw)
gc()

# 4. Safety checks
pa_clean <- pa_clean |>
  st_cast("MULTIPOLYGON")

pa_clean <- pa_clean[!st_is_empty(pa_clean), ]

print(dim(pa_clean))
print(unique(st_geometry_type(pa_clean)))
print(summary(pa_clean$sup_ha))

# 5. Save
write_gpkg_layer(
  obj   = pa_clean,
  path  = file.path(proc_dir, "spainprotectedarea_clean.gpkg"),
  layer = "spainprotectedarea_clean"
)

saveRDS(
  pa_clean,
  file.path(proc_dir, "spainprotectedarea_clean.rds")
)

message("Cleaning complete: spainprotectedarea")

rm(pa_clean)
gc()




