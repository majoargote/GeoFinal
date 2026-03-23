# 09_clean_crime.R -----------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "crime")
proc_dir <- file.path(data_proc, "crime")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- file.path(raw_dir, "01002_en.xlsx")

if (!file.exists(raw_file)) {
  stop("Crime file not found: ", raw_file)
}

# 2. Read (no headers) and rename
crime_raw <- readxl::read_excel(
  raw_file,
  col_names = FALSE
) |>
  dplyr::rename(
    region = 1,
    value  = 2
  )

# 3. Drop metadata rows
crime_raw <- crime_raw[-(1:7), ]

# 4. Keep rows with values
crime_vals <- crime_raw |>
  dplyr::filter(!is.na(value))

# 5. Province names = row above value rows
prov_names <- crime_raw$region[which(!is.na(crime_raw$value)) - 1]

# 6. Build clean dataset
crime_clean <- tibble::tibble(
  provincia   = prov_names,
  crime_total = as.numeric(gsub(",", "", as.character(crime_vals$value)))
)

# 7. Drop national total
crime_clean <- crime_clean |>
  dplyr::filter(provincia != "Total")

# 8. Checks
print(head(crime_clean))
print(dim(crime_clean))
summary(crime_clean$crime_total)

# 9. Save
write_csv_utf8(
  crime_clean,
  file.path(proc_dir, "crime_clean.csv")
)

saveRDS(
  crime_clean,
  file.path(proc_dir, "crime_clean.rds")
)

message("Cleaning complete: crime")

rm(crime_clean, crime_raw, crime_vals, prov_names)
gc()
