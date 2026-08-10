# Analysis configuration -----------------------------------------------------

target_homes <- c(
  "County of Lambton — Lambton Meadowview Villa",
  "County of Lambton — Marshall Gowland Manor",
  "County of Lambton — North Lambton Lodge"
)

peer_count <- 10L

# Use "all_ontario" for the first analysis.
# Change to "municipal" after adding data/raw/municipal_home_roster.csv.
candidate_scope <- "all_ontario"

source_workbook <- "data/raw/indicator-library-all-indicator-data-en.xlsx"
municipal_roster_file <- "data/raw/municipal_home_roster.csv"

fiscal_years <- c(
  "2020–2021",
  "2021–2022",
  "2022–2023",
  "2023–2024",
  "2024–2025"
)

quality_indicators <- c(
  "Falls in the Last 30 Days in Long-Term Care",
  "Experiencing Pain in Long-Term Care",
  "Experiencing Worsened Pain in Long-Term Care",
  "Worsened Pressure Ulcer in Long-Term Care",
  "Worsened Depressive Mood in Long-Term Care",
  "Worsened Physical Functioning in Long-Term Care",
  "Improved Physical Functioning in Long-Term Care",
  "Restraint Use in Long-Term Care",
  "Potentially Inappropriate Use of Antipsychotics in Long-Term Care"
)

higher_is_better_indicator <- "Improved Physical Functioning in Long-Term Care"

resident_mix_indicators <- c(
  "Female Long-Term Care Residents" = "percent_female",
  "Long-Term Care Residents Older Than 85" = "percent_older_85",
  "Long-Term Care Residents Younger Than 65" = "percent_younger_65",
  "Long-Term Care Residents with Dementia" = "percent_dementia",
  "Long-Term Care Residents with Congestive Heart Failure" = "percent_chf"
)

matching_variables <- unname(resident_mix_indicators)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
