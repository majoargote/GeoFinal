# 19_build_provinces.R -------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
proc_dir <- data_proc

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

# 2. Get Spain NUTS3 = provinces
prov_raw <- giscoR::gisco_get_nuts(
  year = "2021",
  epsg = "4326",
  resolution = "20",
  nuts_level = "3"
)

# 3. Keep Spain only, exclude Canary Islands
prov_clean <- prov_raw |>
  dplyr::filter(CNTR_CODE == "ES") |>
  clean_names_lower() |>
  drop_zm_safe() |>
  st_make_valid() |>
  dplyr::select(
    province_id   = nuts_id,
    province_name = name_latn,
    geometry
  ) |>
  dplyr::filter(
    !province_name %in% c(
      "Tenerife",
      "El Hierro",
      "Fuerteventura",
      "Gran Canaria",
      "La Gomera",
      "La Palma",
      "Lanzarote",
      "Ceuta",
      "Melilla",
      "Mallorca",
      "Menorca",
      "Eivissa y Formentera"
    )
  )

rm(prov_raw)
gc()

# 4. Safety checks
prov_clean <- prov_clean[!st_is_empty(prov_clean), ]

print(dim(prov_clean))
print(unique(st_geometry_type(prov_clean)))
print(prov_clean$province_name)

# 5. Save
write_gpkg_layer(
  obj   = prov_clean,
  path  = file.path(proc_dir, "spain_provinces_master.gpkg"),
  layer = "spain_provinces_master"
)

saveRDS(
  prov_clean,
  file.path(proc_dir, "spain_provinces_master.rds")
)

message("Build complete: spain_provinces_master")

rm(prov_clean)
gc()
