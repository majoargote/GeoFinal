# 09_clean_population.R -----------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "crime")
proc_dir <- file.path(data_proc, "crime")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- file.path(raw_dir, "population.xlsx")

if (!file.exists(raw_file)) {
  stop("Pop file not found: ", raw_file)
}

# 2. Read (no headers) and rename
population_raw <- readxl::read_excel(
  raw_file,
  col_names = FALSE
) |>
  dplyr::rename(
    region = 1,
    value  = 2
  )

# 3. Drop metadata rows
population_raw <- population_raw[-(1:7), ]

# 4. Keep rows with values
population_vals <- population_raw |>
  dplyr::filter(!is.na(value))

# 5. Province names = row above value rows
prov_names <- population_raw$region[which(!is.na(population_raw$value)) - 1]

# 6. Build clean dataset
population_clean <- tibble::tibble(
  provincia   = prov_names,
  population_total = as.numeric(gsub(",", "", as.character(population_vals$value)))
)

# 7. Drop national total
population_clean <- population_clean |>
  dplyr::filter(provincia != "Total")

# 8. Checks
print(head(population_clean))
print(dim(population_clean))
summary(population_clean$population_total)

# 9. Save
write_csv_utf8(
  population_clean,
  file.path(proc_dir, "population_clean.csv")
)

saveRDS(
  population_clean,
  file.path(proc_dir, "population_clean.rds")
)

message("Cleaning complete: population")

rm(population_clean, population_raw, population_vals, prov_names)
gc()
