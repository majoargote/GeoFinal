# 00_setup.R ------------------------------------------------------------

# Packages
install_and_load <- function(pkgs) {
    missing_pkgs <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
    if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs, dependencies = TRUE)
  }
    invisible(lapply(pkgs, library, character.only = TRUE))
}


required_packages <- c(
  "sf","terra","dplyr","readr","stringr",
  "janitor","exactextractr","units",
  "purrr","tidyr","glue", "readxl", "rnaturalearth","giscoR"
)

install_and_load(required_packages)

# directory
setwd("/Users/michelleshi/Desktop/DataCentres")

# Paths
root_dir <- getwd()
data_raw <- file.path(root_dir, "data", "raw")
data_int <- file.path(root_dir, "data", "intermediate")
data_proc <- file.path(root_dir, "data", "processed")
output_dir <- file.path(root_dir, "output")


# Helper functions ------------------------------------------------------

#standardize column names
clean_names_lower <- function(df) {
  janitor::clean_names(df)
}

#fix geometry + reproject
make_valid_transform <- function(x, crs = crs_project) {
  x |>
    st_make_valid() |>
    st_transform(crs)
}

#remove Z/M coordinates
drop_zm_safe <- function(x) {
  if (inherits(x, "sf") || inherits(x, "sfc")) {
    st_zm(x, drop = TRUE, what = "ZM")
  } else {
    x
  }
}

#load master geography
get_provinces <- function() {
  st_read(file.path(data_proc, "spain_provinces_master.gpkg"), quiet = TRUE)
}

#export clean tables
write_csv_utf8 <- function(df, path) {
  readr::write_csv(df, path)
}

#export spatial layers
write_gpkg_layer <- function(obj, path, layer) {
  st_write(obj, path, layer = layer, delete_layer = TRUE, quiet = TRUE)
}

# Project CRS
crs_project <- 25830   # Spain mainland; adjust if needed

# Safe directory creation
dir_create_if_needed <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
}

# Read provinces and standardise
get_provinces <- function() {
  x <- st_read(file.path(data_proc, "spain_provinces_master.gpkg"), quiet = TRUE) |>
    clean_names_lower() |>
    drop_zm_safe() |>
    st_make_valid() |>
    st_transform(crs_project)
  x
}

# Save RDS helper
write_rds <- function(obj, path) {
  saveRDS(obj, path)
}

# Read RDS helper
read_rds <- function(path) {
  readRDS(path)
}

# Check unique keys
check_duplicates <- function(df, keys) {
  df |>
    st_drop_geometry() |>
    dplyr::count(across(all_of(keys))) |>
    dplyr::filter(n > 1)
}

# Province centroids for distance-based measures
get_province_centroids <- function() {
  prov <- get_provinces()
  st_centroid(prov)
}

# Get Spain boundary (for raster cropping etc.)
get_spain_boundary <- function() {
  spain <- rnaturalearth::ne_countries(
    country = "Spain",
    scale = "medium",
    returnclass = "sf"
  )
  
  spain |>
    st_make_valid()
}

# Get provinces 
get_provinces <- function() {
  st_read(file.path(data_proc, "spain_provinces_master.gpkg"), quiet = TRUE)
}
