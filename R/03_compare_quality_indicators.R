suppressPackageStartupMessages({
  library(tidyverse)
})

source("R/00_config.R")

quality_file <- "data/processed/ontario_ltc_quality_long.csv"
peers_file <- "outputs/tables/comparable_home_matches.csv"

if (!file.exists(quality_file) || !file.exists(peers_file)) {
  stop("Run the cleaning and peer-selection scripts first.", call. = FALSE)
}

quality_long <- read_csv(quality_file, show_col_types = FALSE)
peer_matches <- read_csv(peers_file, show_col_types = FALSE)

target_quality <- quality_long |>
  filter(home %in% target_homes) |>
  transmute(
    target_home = home,
    fiscal_year,
    indicator,
    target_value = value,
    target_value_status = value_status
  )

peer_quality <- peer_matches |>
  select(target_home, peer_home) |>
  left_join(
    quality_long |>
      select(home, fiscal_year, indicator, peer_value = value),
    by = c("peer_home" = "home")
  )

comparison_rows <- peer_quality |>
  inner_join(
    target_quality,
    by = c("target_home", "fiscal_year", "indicator")
  )

comparison <- comparison_rows |>
  group_by(target_home, fiscal_year, indicator) |>
  summarise(
    target_value = first(target_value),
    target_value_status = first(target_value_status),
    peer_n_reported = sum(!is.na(peer_value)),
    peer_median = median(peer_value, na.rm = TRUE),
    peer_q1 = quantile(peer_value, 0.25, na.rm = TRUE, names = FALSE),
    peer_q3 = quantile(peer_value, 0.75, na.rm = TRUE, names = FALSE),
    percent_of_peers_target_matches_or_outperforms = {
      target_result <- first(target_value)
      if (is.na(target_result) || all(is.na(peer_value))) {
        NA_real_
      } else if (first(indicator) == higher_is_better_indicator) {
        100 * mean(target_result >= peer_value, na.rm = TRUE)
      } else {
        100 * mean(target_result <= peer_value, na.rm = TRUE)
      }
    },
    .groups = "drop"
  ) |>
  mutate(
    higher_is_better = indicator == higher_is_better_indicator,
    target_minus_peer_median = target_value - peer_median,
    direction_adjusted_gap = if_else(
      higher_is_better,
      target_value - peer_median,
      peer_median - target_value
    ),
    interpretation = case_when(
      is.na(direction_adjusted_gap) ~ "Not available",
      direction_adjusted_gap > 0 ~ "Better than peer median",
      direction_adjusted_gap < 0 ~ "Worse than peer median",
      TRUE ~ "Equal to peer median"
    ),
    fiscal_year = factor(fiscal_year, levels = fiscal_years)
  ) |>
  arrange(target_home, indicator, fiscal_year)

latest_comparison <- comparison |>
  filter(fiscal_year == tail(fiscal_years, 1)) |>
  arrange(target_home, desc(percent_of_peers_target_matches_or_outperforms))

write_csv(
  comparison |>
    mutate(fiscal_year = as.character(fiscal_year)),
  "outputs/tables/peer_comparison_all_years.csv",
  na = ""
)

write_csv(
  latest_comparison |>
    mutate(fiscal_year = as.character(fiscal_year)),
  "outputs/tables/peer_comparison_latest_year.csv",
  na = ""
)

message("Created peer comparison tables for all nine indicators.")
