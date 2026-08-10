suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(janitor)
})

source("R/00_config.R")

if (!file.exists(source_workbook)) {
  stop(
    "Source workbook not found. Upload it as: ",
    source_workbook,
    call. = FALSE
  )
}

# Read only the 12 required columns from the 33-column CIHI workbook.
# This substantially reduces memory use for the 822,882-row source.
keep_positions <- c(1, 2, 4, 5, 6, 11, 18, 19, 20, 21, 29, 31)
cihi_col_types <- rep("skip", 33)
cihi_col_types[keep_positions] <- "text"

message("Reading required columns from the CIHI workbook...")
raw_cihi <- read_excel(
  source_workbook,
  sheet = 1,
  col_types = cihi_col_types,
  na = c("", "NA")
) |>
  clean_names()

required_columns <- c(
  "place_or_organization",
  "province_territory",
  "corporation",
  "reporting_level",
  "indicator",
  "time_frame",
  "metric",
  "main_metric",
  "metric_value",
  "unit_of_measure",
  "urban_or_rural_remote",
  "long_term_care_facility_size"
)

missing_columns <- setdiff(required_columns, names(raw_cihi))
if (length(missing_columns) > 0) {
  stop(
    "Missing expected CIHI columns: ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

clean_category <- function(x) {
  x <- str_squish(x)
  x[x %in% c("", "-", "Not applicable", "Not available")] <- NA_character_
  x
}

first_valid <- function(x) {
  values <- clean_category(x)
  values <- values[!is.na(values)]
  if (length(values) == 0) NA_character_ else values[[1]]
}

reported_value <- function(x) {
  suppressWarnings(readr::parse_number(x, locale = locale(grouping_mark = ",")))
}

quality_long <- raw_cihi |>
  filter(
    province_territory == "Ontario",
    reporting_level == "Facility",
    indicator %in% quality_indicators,
    time_frame %in% fiscal_years,
    main_metric == "Yes",
    metric == "Risk-adjusted rate"
  ) |>
  transmute(
    home = place_or_organization,
    corporation,
    fiscal_year = time_frame,
    indicator,
    metric,
    unit = unit_of_measure,
    facility_size = clean_category(long_term_care_facility_size),
    setting = clean_category(urban_or_rural_remote),
    value_raw = metric_value,
    value_status = case_when(
      metric_value == "Suppressed" ~ "Suppressed",
      metric_value == "Not available" ~ "Not available",
      metric_value == "Not applicable" ~ "Not applicable",
      TRUE ~ "Reported"
    ),
    value = if_else(
      value_status == "Reported",
      reported_value(metric_value),
      NA_real_
    )
  )

duplicate_results <- quality_long |>
  count(home, fiscal_year, indicator) |>
  filter(n > 1)

if (nrow(duplicate_results) > 0) {
  stop(
    "More than one main result exists for at least one home/indicator/year.",
    call. = FALSE
  )
}

facility_metadata <- quality_long |>
  group_by(home, corporation) |>
  summarise(
    facility_size = first_valid(facility_size),
    setting = first_valid(setting),
    .groups = "drop"
  )

resident_mix <- raw_cihi |>
  filter(
    province_territory == "Ontario",
    reporting_level == "Facility",
    indicator %in% names(resident_mix_indicators),
    time_frame == "2024–2025",
    main_metric == "Yes"
  ) |>
  transmute(
    home = place_or_organization,
    feature = recode(indicator, !!!as.list(resident_mix_indicators)),
    value = reported_value(metric_value)
  ) |>
  group_by(home, feature) |>
  summarise(value = first(value), .groups = "drop") |>
  pivot_wider(names_from = feature, values_from = value)

home_characteristics <- facility_metadata |>
  left_join(resident_mix, by = "home")

write_csv(quality_long, "data/processed/ontario_ltc_quality_long.csv", na = "")
write_csv(
  home_characteristics,
  "data/processed/ontario_ltc_home_characteristics.csv",
  na = ""
)

message(
  "Cleaned ",
  comma(n_distinct(quality_long$home)),
  " Ontario homes and ",
  comma(nrow(quality_long)),
  " quality-result rows."
)

rm(raw_cihi)
invisible(gc())
