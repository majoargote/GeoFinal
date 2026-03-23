# 05_clean_broadband.R -------------------------------------------------

rm(list = ls())
gc()
cat("\014")

source("/Users/michelleshi/Desktop/DataCentres/data/R_scripts/00_setup.R")

# 1. Paths
raw_dir  <- file.path(data_raw, "broadband")
proc_dir <- file.path(data_proc, "broadband")

if (!dir.exists(proc_dir)) dir.create(proc_dir, recursive = TRUE)

raw_file <- list.files(
  raw_dir,
  pattern = "\\.xlsx$|\\.xls$|\\.csv$",
  full.names = TRUE,
  recursive = TRUE
)[1]

if (is.na(raw_file)) {
  stop("No broadband file found in: ", raw_dir)
}

print(raw_file)

# 2. Read (municipio sheet)
broadband_raw <- readxl::read_excel(raw_file, sheet = "Municipio")

print(colnames(broadband_raw))
print(dim(broadband_raw))

# 3. Clean names
broadband_clean <- broadband_raw |>
  clean_names_lower() |>
  select(-x8, -x10, -x13, -x16)

# 4. Convert % strings to numeric
percent_cols <- c(
  "vdsl_30mbps_junio_2021",
  "inalambrico_fijo_junio_2021",
  "ftth_junio_2021",
  "hfc_junio_2021",
  "cob_30mbps_junio_2021",
  "cob_100mbps_junio_2021",
  "x4g_junio_2021",
  "x5g_junio_2021"
)

broadband_clean <- broadband_clean |>
  mutate(
    across(
      all_of(percent_cols),
      ~ as.numeric(gsub("%", "", as.character(.)))
    ),
    cmun = stringr::str_pad(as.character(cmun), width = 5, pad = "0")
  )

# 5. Keep relevant columns
broadband_clean <- broadband_clean |>
  select(
    comunidad_autonoma,
    provincia,
    cmun,
    municipio,
    habitantes,
    viviendas_catastro_agosto_2020,
    all_of(percent_cols)
  )

rm(broadband_raw)
gc()

# 6. Safety checks
print(dim(broadband_clean))
summary(broadband_clean[percent_cols])

# 7. Save
write_csv_utf8(
  broadband_clean,
  file.path(proc_dir, "broadband_clean.csv")
)

saveRDS(
  broadband_clean,
  file.path(proc_dir, "broadband_clean.rds")
)

message("Cleaning complete: broadband")

rm(broadband_clean)
gc()
