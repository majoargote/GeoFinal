# 10_clean_arkolakis.R -------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "arkolakis")
proc_dir <- file.path(data_proc, "arkolakis")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

shp_file <- file.path(raw_dir, "selected_regions", "selected_regions.shp")
cap_file <- file.path(raw_dir, "csr_aggcap.csv")

if (!file.exists(shp_file)) {
  stop("selected_regions shapefile not found: ", shp_file)
}

if (!file.exists(cap_file)) {
  stop("csr_aggcap.csv not found: ", cap_file)
}

# 2. Read raw data
regions_raw <- st_read(shp_file, quiet = TRUE)
cap_raw     <- readr::read_csv(cap_file, show_col_types = FALSE)

print(colnames(regions_raw))
print(dim(regions_raw))
print(unique(st_geometry_type(regions_raw)))

print(colnames(cap_raw))
print(dim(cap_raw))
print(head(cap_raw))

# 3. Clean geometry layer
regions_clean <- regions_raw |>
  clean_names_lower() |>
  drop_zm_safe() |>
  make_valid_transform() |>
  dplyr::select(
    csr_id,
    reg_id,
    region,
    ctry_code,
    ctry_name,
    reg_groups,
    inner_dist,
    latitude,
    longitude,
    geometry
  ) |>
  dplyr::mutate(
    csr_id = as.numeric(csr_id)
  )

rm(regions_raw)
gc()

# 4. Clean capacity table
cap_clean <- cap_raw |>
  clean_names_lower() |>
  dplyr::select(
    csr_id,
    capacity_mw,
    rnw_capacity_mw,
    ffl_capacity_mw,
    slr_capacity_mw,
    wnd_capacity_mw
  ) |>
  dplyr::mutate(
    csr_id = as.numeric(csr_id)
  )

rm(cap_raw)
gc()

# 5. Merge
ark_clean <- regions_clean |>
  dplyr::left_join(cap_clean, by = "csr_id")

rm(regions_clean, cap_clean)
gc()

# 6. Safety checks
ark_clean <- ark_clean[!st_is_empty(ark_clean), ]

print(colnames(ark_clean))
print(dim(ark_clean))
print(unique(st_geometry_type(ark_clean)))
print(summary(ark_clean$capacity_mw))
print(summary(ark_clean$rnw_capacity_mw))
print(summary(ark_clean$slr_capacity_mw))
print(summary(ark_clean$wnd_capacity_mw))
print(sum(is.na(ark_clean$capacity_mw)))

# 7. Save
write_gpkg_layer(
  obj   = ark_clean,
  path  = file.path(proc_dir, "arkolakis_clean.gpkg"),
  layer = "arkolakis_clean"
)

saveRDS(
  ark_clean,
  file.path(proc_dir, "arkolakis_clean.rds")
)

message("Cleaning complete: arkolakis")

rm(ark_clean)
gc()
