suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

source("R/00_config.R")

comparison_file <- "outputs/tables/peer_comparison_all_years.csv"
if (!file.exists(comparison_file)) {
  stop("Run R/03_compare_quality_indicators.R first.", call. = FALSE)
}

comparison <- read_csv(comparison_file, show_col_types = FALSE) |>
  mutate(fiscal_year = factor(fiscal_year, levels = fiscal_years))

home_slug <- function(x) {
  x |>
    str_remove("^County of Lambton — ") |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_remove_all("(^-|-$)")
}

for (selected_home in target_homes) {
  plot_data <- comparison |>
    filter(target_home == selected_home)

  trend_plot <- ggplot(plot_data, aes(x = fiscal_year)) +
    geom_ribbon(
      aes(ymin = peer_q1, ymax = peer_q3, group = indicator),
      fill = "#CBD5E1",
      alpha = 0.7
    ) +
    geom_line(
      aes(y = peer_median, group = indicator),
      colour = "#64748B",
      linewidth = 0.8,
      linetype = "dashed"
    ) +
    geom_line(
      aes(y = target_value, group = indicator),
      colour = "#0F766E",
      linewidth = 1
    ) +
    geom_point(
      aes(y = target_value),
      colour = "#0F766E",
      size = 1.8
    ) +
    facet_wrap(~ indicator, scales = "free_y", ncol = 3) +
    labs(
      title = str_remove(selected_home, "^County of Lambton — "),
      subtitle = "Target home versus matched-peer median and interquartile range",
      x = NULL,
      y = "Risk-adjusted rate (%)",
      caption = "Source: CIHI Indicator Library. Suppressed values are shown as missing."
    ) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 35, hjust = 1),
      strip.text = element_text(face = "bold", size = 8),
      plot.title = element_text(face = "bold")
    )

  ggsave(
    filename = file.path(
      "outputs/figures",
      paste0(home_slug(selected_home), "-peer-trends.png")
    ),
    plot = trend_plot,
    width = 14,
    height = 10,
    dpi = 220
  )
}

message("Created one nine-indicator trend figure for each Lambton home.")
