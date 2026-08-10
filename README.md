# Ontario LTC Peer Analysis

A reproducible R analysis comparing three County of Lambton long-term-care homes with structurally comparable Ontario homes using public CIHI Indicator Library data.

## Target homes

- County of Lambton — Lambton Meadowview Villa
- County of Lambton — Marshall Gowland Manor
- County of Lambton — North Lambton Lodge

## Research question

How do the three County of Lambton long-term-care homes perform over time, relative to structurally comparable Ontario homes?

## Quality outcomes

The comparison uses nine repeated facility-level, risk-adjusted indicators for fiscal years 2020–2021 through 2024–2025:

1. Falls in the Last 30 Days in Long-Term Care
2. Experiencing Pain in Long-Term Care
3. Experiencing Worsened Pain in Long-Term Care
4. Worsened Pressure Ulcer in Long-Term Care
5. Worsened Depressive Mood in Long-Term Care
6. Worsened Physical Functioning in Long-Term Care
7. Improved Physical Functioning in Long-Term Care
8. Restraint Use in Long-Term Care
9. Potentially Inappropriate Use of Antipsychotics in Long-Term Care

## Peer-selection method

Peers are selected before examining quality outcomes. Each target home is matched to up to 10 external Ontario homes using:

- exact facility-size category;
- exact urban/rural classification where a sufficient pool exists; and
- nearest standardized resident mix: percentage female, older than 85, younger than 65, with dementia, and with congestive heart failure.

The other County of Lambton homes are excluded from each target's peer pool. Quality outcomes are not matching variables because they are the results being compared.

The first runnable version uses all Ontario facilities. A municipal-only sensitivity analysis can be enabled after adding the municipal-home roster described below.

## Repository structure

- `data/raw/`: original public source files; never edited by the scripts
- `data/processed/`: reproducible cleaned datasets
- `R/`: configuration, cleaning, matching, comparison, and chart scripts
- `outputs/tables/`: peer lists and comparison tables
- `outputs/figures/`: trend figures

## Add the source data

Upload the CIHI workbook to:

`data/raw/indicator-library-all-indicator-data-en.xlsx`

The scripts expect the workbook's first worksheet and the original CIHI column names.

Optional municipal-only analysis: add `data/raw/municipal_home_roster.csv` with a column named `place_or_organization`, then set `candidate_scope <- "municipal"` in `R/00_config.R`.

## Run the analysis

In R or RStudio, set the repository as the project directory, then run:

```r
install.packages(c("tidyverse", "readxl", "janitor", "scales"))
source("run_analysis.R")
```

The workflow will:

1. preserve the raw workbook;
2. extract Ontario facility-level main metrics;
3. retain suppression as missing data;
4. create one clean result per home, indicator, and year;
5. select comparable peers;
6. calculate peer medians, interquartile ranges, differences, and percentile performance; and
7. save tables and figures under `outputs/`.

## Interpretation notes

For eight indicators, a lower rate is generally preferable. For Improved Physical Functioning in Long-Term Care, a higher rate is preferable. The scripts retain the original rates and calculate a direction-aware performance percentile.

Peer comparison is descriptive and does not establish causation. Suppressed and unavailable CIHI values remain missing and are never replaced with zero.
