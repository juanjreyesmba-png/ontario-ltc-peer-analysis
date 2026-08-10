required_packages <- c("tidyverse", "readxl", "janitor", "scales")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the missing packages first: install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))",
    call. = FALSE
  )
}

source("R/01_import_clean.R")
source("R/02_select_comparable_homes.R")
source("R/03_compare_quality_indicators.R")
source("R/04_create_figures.R")

message("Analysis complete. Review outputs/tables and outputs/figures.")
