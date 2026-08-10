# Raw source data

Upload the unmodified public CIHI workbook here with this exact filename:

`indicator-library-all-indicator-data-en.xlsx`

Do not manually edit the source workbook. All filtering and cleaning are performed by the scripts in `R/`.

For the optional municipal-only sensitivity analysis, also add:

`municipal_home_roster.csv`

That CSV must contain a column named `place_or_organization` with names matching the CIHI `Place or organization` field.
