suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

source("R/00_config.R")

characteristics_file <- "data/processed/ontario_ltc_home_characteristics.csv"
if (!file.exists(characteristics_file)) {
  stop("Run R/01_import_clean.R first.", call. = FALSE)
}

home_characteristics <- read_csv(
  characteristics_file,
  show_col_types = FALSE
)

if (candidate_scope == "municipal") {
  if (!file.exists(municipal_roster_file)) {
    stop(
      "Municipal scope selected, but the roster is missing: ",
      municipal_roster_file,
      call. = FALSE
    )
  }

  municipal_roster <- read_csv(
    municipal_roster_file,
    show_col_types = FALSE
  ) |>
    clean_names()

  if (!"place_or_organization" %in% names(municipal_roster)) {
    stop(
      "The municipal roster must contain place_or_organization.",
      call. = FALSE
    )
  }

  permitted_homes <- unique(municipal_roster$place_or_organization)
  home_characteristics <- home_characteristics |>
    filter(home %in% union(permitted_homes, target_homes))
}

missing_targets <- setdiff(target_homes, home_characteristics$home)
if (length(missing_targets) > 0) {
  stop(
    "Target homes missing from cleaned characteristics: ",
    paste(missing_targets, collapse = "; "),
    call. = FALSE
  )
}

select_peers <- function(target_home) {
  target <- home_characteristics |>
    filter(home == target_home) |>
    slice(1)

  if (is.na(target$facility_size)) {
    stop("Facility size is missing for ", target_home, call. = FALSE)
  }

  target_match_values <- unlist(
    target[1, matching_variables],
    use.names = TRUE
  )

  available_variables <- matching_variables[
    !is.na(as.numeric(target_match_values))
  ]

  if (length(available_variables) == 0) {
    stop("Resident-mix matching values are missing for ", target_home, call. = FALSE)
  }

  size_pool <- home_characteristics |>
    filter(
      !home %in% target_homes,
      facility_size == target$facility_size
    ) |>
    drop_na(all_of(available_variables))

  setting_pool <- size_pool |>
    filter(
      !is.na(setting),
      setting == target$setting
    )

  if (nrow(setting_pool) >= peer_count) {
    candidate_pool <- setting_pool
    match_rule <- "Same size + same setting + nearest resident mix"
  } else {
    candidate_pool <- size_pool
    match_rule <- "Same size + nearest resident mix; setting relaxed"
  }

  if (nrow(candidate_pool) == 0) {
    stop("No eligible peers found for ", target_home, call. = FALSE)
  }

  combined <- bind_rows(
    target |> select(home, all_of(available_variables)),
    candidate_pool |> select(home, all_of(available_variables))
  )

  values <- data.matrix(combined[, available_variables, drop = FALSE])
  scaled_values <- scale(values)
  scaled_values[is.na(scaled_values)] <- 0

  target_vector <- scaled_values[1, , drop = TRUE]
  candidate_values <- scaled_values[-1, , drop = FALSE]
  distances <- sqrt(rowSums(sweep(candidate_values, 2, target_vector, "-")^2))

  candidate_pool |>
    mutate(
      target_home = target_home,
      peer_home = home,
      match_distance = distances,
      match_rule = match_rule
    ) |>
    arrange(match_distance, peer_home) |>
    slice_head(n = peer_count) |>
    select(
      target_home,
      peer_home,
      match_distance,
      match_rule,
      facility_size,
      setting,
      all_of(available_variables)
    )
}

peer_matches <- map_dfr(target_homes, select_peers)

peer_counts <- peer_matches |>
  count(target_home, name = "peer_count")

if (any(peer_counts$peer_count == 0)) {
  stop("At least one target home has no matched peers.", call. = FALSE)
}

write_csv(peer_matches, "outputs/tables/comparable_home_matches.csv", na = "")

message(
  "Selected ",
  nrow(peer_matches),
  " peer-home matches across ",
  n_distinct(peer_matches$target_home),
  " target homes."
)
